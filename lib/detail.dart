import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models.dart';
import 'widgets.dart';

/// Layar detail artikel gaya SakuMedis: tab di atas (Materi / Bukti /
/// Sumber) untuk SEMUA artikel.
/// - Materi (build 1.5.2): seksi lipat (accordion) — tiap blok berlabel
///   jadi kartu lipat (seksi pertama terbuka default); beberapa seksi
///   boleh terbuka bersamaan; auto-scroll hanya bila header terpotong
///   atau di luar pandang. Catatan penting di PALING BAWAH artikel
///   TERTUTUP secara default — hanya ketukan pengguna yang membukanya, dan membuka
///   seksi lain tidak pernah membukanya. Parser dipakai bersama dari
///   models.dart (parseBodySections) — bukan parser kedua.
///   Passthrough pencarian: artikel dibuka dari hasil pencarian langsung
///   membuka seksi yang mengandung kecocokan (searchQuery).
/// - Bukti: daftar literatur dari field referensi, dipecah per sitasi.
///   Bila referensi masih placeholder PERLU VERIFIKASI / [CONTOH],
///   tampil apa adanya sebagai catatan — tidak dikarang.
/// - Sumber: acuan artikel (teks referensi utuh). Catatan SOP DIHAPUS
///   (basis aplikasi = referensi jurnal, bukan SOP).
/// Tanpa bookmark (dihapus permanen). Bench Mode pindah ke AppBar
/// (ikon lampu + indikator aktif); pill melayang DIHAPUS.
class DetailScreen extends StatefulWidget {
  final Article article;

  /// Kata kunci pencarian yang membuka artikel ini, bila ada. Dipakai
  /// passthrough: seksi yang cocok langsung terbuka di tab Materi.
  final String? searchQuery;
  const DetailScreen({required this.article, this.searchQuery, super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _keepScreenOn = false;

  @override
  void dispose() {
    if (_keepScreenOn) WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _toggleBenchMode() async {
    final next = !_keepScreenOn;
    setState(() => _keepScreenOn = next);
    if (next) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    if (!mounted) return;
    if (next) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Layar menyala sampai artikel ditutup'),
          action: SnackBarAction(
            label: 'Matikan',
            onPressed: _toggleBenchMode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  /// Sitasi asli dari field referensi, dipecah per ';'. Null bila tidak
  /// ada sitasi asli (kosong atau masih placeholder).
  List<String>? _citations(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('PERLU VERIFIKASI') ||
        trimmed.startsWith('Referensi contoh (placeholder)')) {
      return null;
    }
    final parts = trimmed
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final citations = _citations(article.reference);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(article.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimary)),
              Text(article.category,
                  style: const TextStyle(
                      fontSize: 12, color: kOnSurfaceVariant)),
            ],
          ),
          backgroundColor: kBackground,
          elevation: 1,
          actions: [
            IconButton(
              icon: Icon(
                  _keepScreenOn
                      ? Icons.lightbulb
                      : Icons.lightbulb_outline,
                  color: _keepScreenOn ? kPrimary : kOnSurfaceVariant),
              tooltip: _keepScreenOn
                  ? 'Matikan mode layar menyala'
                  : 'Mode layar menyala (Bench Mode)',
              onPressed: _toggleBenchMode,
            ),
          ],
          bottom: const TabBar(
            labelColor: kPrimary,
            unselectedLabelColor: kOnSurfaceVariant,
            indicatorColor: kPrimary,
            tabs: [
              Tab(text: 'Materi'),
              Tab(text: 'Bukti'),
              Tab(text: 'Sumber'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MateriTab(
                article: article, autoOpenQuery: widget.searchQuery),
            _BuktiTab(article: article, citations: citations),
            _SumberTab(article: article, citations: citations),
          ],
        ),
      ),
    );
  }
}

/// Tab Materi: seksi lipat + kartu Catatan penting di bawah.
///
/// Perilaku yang dikunci:
/// - Catatan penting (dulu kartu Kritis): di PALING BAWAH artikel,
///   tertutup default, hanya ketukan pengguna yang membukanya;
///   membuka seksi lain tidak pernah membukanya.
/// - Seksi berlabel: seksi pertama terbuka default (atau seksi yang
///   cocok dengan kueri); sisanya tertutup, boleh terbuka bersamaan.
/// - Auto-scroll: HANYA bila header terpotong/di luar pandang, durasi
///   pendek (150ms), header dibawa dekat atas.
/// - Passthrough: autoOpenQuery membuka seksi pertama yang cocok.
class _MateriTab extends StatefulWidget {
  final Article article;
  final String? autoOpenQuery;
  const _MateriTab({required this.article, this.autoOpenQuery});

  @override
  State<_MateriTab> createState() => _MateriTabState();
}

class _MateriTabState extends State<_MateriTab> {
  late final List<BodySection> _sections;
  late final List<int> _criticalIndices;
  final Set<int> _openSections = {};
  final Set<int> _openCriticals = {};
  final Map<int, GlobalKey> _sectionKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sections = parseBodySections(widget.article.body);
    _criticalIndices = [
      for (var i = 0; i < _sections.length; i++)
        if (_sections[i].kind == SectionKind.critical) i
    ];
    for (var i = 0; i < _sections.length; i++) {
      _sectionKeys[i] = GlobalKey();
    }
    final q = widget.autoOpenQuery;
    var openedByQuery = false;
    if (q != null && q.trim().isNotEmpty) {
      final idx = findSectionForQuery(_sections, q);
      if (idx != null) {
        openedByQuery = true;
        if (_sections[idx].kind == SectionKind.labeled) {
          _openSections.add(idx);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeScrollToSection(idx);
        });
      }
    }
    if (!openedByQuery) {
      // Tanpa kueri (atau kueri tanpa kecocokan): buka seksi
      // berlabel pertama supaya artikel langsung terbaca; seksi
      // lain tetap tertutup. Catatan penting tidak pernah dibuka
      // otomatis.
      for (var i = 0; i < _sections.length; i++) {
        if (_sections[i].kind == SectionKind.labeled) {
          _openSections.add(i);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSection(int index) {
    final nowOpen = !_openSections.contains(index);
    setState(() {
      if (nowOpen) {
        _openSections.add(index);
      } else {
        _openSections.remove(index);
      }
    });
    if (nowOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeScrollToSection(index);
      });
    }
  }

  void _toggleCritical(int index) {
    setState(() {
      if (_openCriticals.contains(index)) {
        _openCriticals.remove(index);
      } else {
        _openCriticals.add(index);
      }
    });
  }

  /// Gulir HANYA bila header seksi terpotong atau di luar pandang.
  /// Header yang sudah terlihat penuh tidak digerakkan sama sekali.
  void _maybeScrollToSection(int index) {
    final key = _sectionKeys[index];
    final context = key?.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final offset = box.localToGlobal(Offset.zero);
    final topLimit =
        MediaQuery.of(this.context).padding.top + kToolbarHeight + 48.0;
    final screenHeight = MediaQuery.of(this.context).size.height;
    if (offset.dy < topLimit ||
        offset.dy + box.size.height > screenHeight) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (article.title.startsWith('[CONTOH]')) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWarningContainer,
                border: Border.all(color: kWarningBorder, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PERINGATAN: ARTIKEL [CONTOH]',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(
                      'Artikel ini masih berupa contoh tata letak dan BUKAN isi buku saku ATLM yang sebenarnya. Jangan gunakan angka atau langkah di dalam artikel ini untuk pemeriksaan spesimen nyata sampai diganti isi asli.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Seksi lain dalam urutan asli.
          for (var i = 0; i < _sections.length; i++)
            if (_sections[i].kind != SectionKind.critical) ...[
              _sectionWidget(i),
              const SizedBox(height: 14),
            ],
          // Catatan penting: paling bawah artikel
          // (bukan lagi di bawah judul).
          for (final ci in _criticalIndices) ...[
            _criticalCard(_sections[ci], _openCriticals.contains(ci),
                () => _toggleCritical(ci)),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _sectionWidget(int index) {
    final s = _sections[index];
    switch (s.kind) {
      case SectionKind.labeled:
        final open = _openSections.contains(index);
        return Container(
          key: _sectionKeys[index],
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kOutlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleSection(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.label ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                      Icon(
                          open
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: kPrimary),
                    ],
                  ),
                  if (open) ...[
                    const SizedBox(height: 8),
                    _labeledContent(s),
                  ],
                ],
              ),
            ),
          ),
        );
      case SectionKind.paragraph:
        return Container(
          key: _sectionKeys[index],
          child: Text(s.text,
              style: const TextStyle(fontSize: 16, height: 1.5)),
        );
      case SectionKind.multiline:
        return Container(
          key: _sectionKeys[index],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _multilineBlock(s.text),
          ),
        );
      case SectionKind.banner:
        return Container(
          key: _sectionKeys[index],
          child: _verificationBanner(s.text),
        );
      case SectionKind.critical:
        return const SizedBox.shrink();
    }
  }

  /// Isi seksi berlabel: Rumus bergambar bila ada di formulaDisplays,
  /// langkah inline jadi daftar bernomor vertikal, Interpretasi
  /// berpasangan jadi tabel 2 kolom, selain itu teks biasa.
  Widget _labeledContent(BodySection s) {
    if (s.label == 'Rumus') {
      final f = formulaDisplays[widget.article.id];
      if (f != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < f.assets.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Image.asset(f.assets[i],
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Rumus ${widget.article.title} bagian ${i + 1}',
                  errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSurfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.broken_image,
                                color: kOnSurfaceVariant, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Gambar rumus tidak dapat dimuat.',
                                  style: TextStyle(
                                      color: kOnSurfaceVariant)),
                            ),
                          ],
                        ),
                      )),
            ],
            if (f.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(f.note,
                  style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ],
        );
      }
    }
    if (s.label == 'Cara pemeriksaan manual') {
      final groups = parseInlineSteps(s.text);
      if (groups != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var gi = 0; gi < groups.length; gi++) ...[
              if (gi > 0) const SizedBox(height: 12),
              if (groups[gi].preamble.isNotEmpty) ...[
                Text(groups[gi].preamble,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              for (var i = 0; i < groups[gi].steps.length; i++) ...[
                _stepRow(i + 1, groups[gi].steps[i]),
                if (i < groups[gi].steps.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ],
        );
      }
    }
    if (s.label == 'Interpretasi') {
      final rows = parseInterpretationRows(s.text);
      if (rows != null) return _interpretationTable(rows);
    }
    return Text(s.text, style: const TextStyle(fontSize: 16, height: 1.5));
  }

  Widget _stepRow(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: kPrimaryContainer, shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kOnPrimaryContainer)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, height: 1.5))),
      ],
    );
  }

  Widget _interpretationTable(List<InterpretationRow> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kOutlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: kOutlineVariant),
            verticalInside: BorderSide(color: kOutlineVariant),
          ),
          children: [
            const TableRow(children: [
              TableCell(
                child: ColoredBox(
                  color: kSurfaceVariant,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('Hasil',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              TableCell(
                child: ColoredBox(
                  color: kSurfaceVariant,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('Keterangan',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
            for (final r in rows)
              TableRow(children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.result,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.explanation,
                        style:
                            const TextStyle(fontSize: 16, height: 1.5)),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _criticalCard(BodySection section, bool open, VoidCallback onTap) {
    final items = section.items ?? const <String>[];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCriticalContainer,
        border: Border.all(color: kCriticalBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Catatan penting',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB3261E))),
                  ),
                  Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFFB3261E)),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 8),
                for (final item in items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _verificationBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWarningContainer,
        border: Border.all(color: kWarningBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kOnWarning)),
    );
  }

  List<Widget> _multilineBlock(String block) {
    final lines = block.split('\n');
    final widgets = <Widget>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final stepMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (stepMatch != null) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: kPrimaryContainer, shape: BoxShape.circle),
              child: Text(stepMatch.group(1)!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kOnPrimaryContainer)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(stepMatch.group(2)!)),
          ],
        ));
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(line.substring(2))),
          ],
        ));
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(_paragraph(line));
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }

  Widget _paragraph(String text) {
    final colon = text.indexOf(': ');
    if (colon >= 2 &&
        colon <= 24 &&
        !text.substring(0, colon).contains(RegExp(r'[0-9]'))) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: kOnSurface, height: 1.5),
          children: [
            TextSpan(
                text: '${text.substring(0, colon)}: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: text.substring(colon + 2)),
          ],
        ),
      );
    }
    return Text(text, style: const TextStyle(fontSize: 16, height: 1.5));
  }
}

/// Tab Bukti: daftar literatur dari field referensi.
/// Placeholder tampil apa adanya — bukan literatur karangan.
class _BuktiTab extends StatelessWidget {
  final Article article;
  final List<String>? citations;
  const _BuktiTab({required this.article, required this.citations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Literatur'),
          const SizedBox(height: 12),
          if (citations == null)
            _NoteCard(
                text: article.reference.trim().isEmpty
                    ? 'Belum ada literatur untuk artikel ini.'
                    : article.reference.trim())
          else
            for (var i = 0; i < citations!.length; i++) ...[
              _LiteratureCard(index: i + 1, text: citations![i]),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// Tab Sumber: acuan artikel (teks referensi utuh). Catatan SOP
/// dihapus (basis = referensi jurnal).
class _SumberTab extends StatelessWidget {
  final Article article;
  final List<String>? citations;
  const _SumberTab({required this.article, required this.citations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Sumber'),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: kOutlineVariant)),
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acuan artikel ini',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(article.reference.trim().isEmpty
                      ? 'Belum ditetapkan.'
                      : article.reference.trim()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiteratureCard extends StatelessWidget {
  final int index;
  final String text;
  const _LiteratureCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kOutlineVariant)),
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$index. Literatur',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kOnPrimaryContainer)),
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String text;
  const _NoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: kOnSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: kOnSurfaceVariant, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
