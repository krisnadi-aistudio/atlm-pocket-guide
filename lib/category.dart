import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'detail.dart';

/// Layar kategori sendiri: cari dalam kategori + daftar artikelnya
/// saja. Kembali mengantar ke Beranda.
///
/// Bila artikel-artikelnya punya sub-kelompok (field `sub`), layar ini
/// menampilkan daftar sub dulu; ketuk satu sub untuk melihat daftar
/// artikelnya (alur: Beranda → Kategori → Sub → Artikel).
class CategoryScreen extends StatefulWidget {
  final String category;
  final List<Article> articles;
  final String? sub;
  const CategoryScreen(
      {required this.category,
      required this.articles,
      this.sub,
      super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

/// Urutan sub-kelompok Hematologi sesuai desain pengguna.
const _subOrder = <String>[
  'Trombosit',
  'Eritrosit',
  'Leukosit',
  'Hemoglobin',
  'Gambaran Darah Tepi',
  'LED',
  'Hemostasis',
  'Golongan Darah',
];

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mode sub-kelompok: artikel punya field sub dan pengguna belum
    // memilih sub -> tampilkan daftar sub terlebih dahulu.
    if (widget.sub == null) {
      final subs = <String>[];
      for (final a in widget.articles) {
        final s = a.sub;
        if (s != null && s.isNotEmpty && !subs.contains(s)) subs.add(s);
      }
      if (subs.isNotEmpty) {
        subs.sort((x, y) {
          final ix = _subOrder.indexOf(x);
          final iy = _subOrder.indexOf(y);
          if (ix >= 0 && iy >= 0) return ix.compareTo(iy);
          if (ix >= 0) return -1;
          if (iy >= 0) return 1;
          return x.compareTo(y);
        });
        return _buildSubList(context, subs);
      }
    }
    final filtered = _query.isEmpty
        ? widget.articles
        : widget.articles
            .where((a) =>
                a.title.toLowerCase().contains(_query.toLowerCase()) ||
                a.body.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    // Urutan dasar layar kategori selalu A–Z (case-insensitive);
    // hasil filter pencarian mewarisi urutan ini.
    final visible = List.of(filtered)
      ..sort((a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.sub == null
                ? widget.category
                : '${widget.category} • ${widget.sub}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kPrimary)),
        backgroundColor: kBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchField(
              controller: _controller,
              hintText: 'Cari judul atau kata kunci di kategori ini…',
              showClear: _query.isNotEmpty,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  _query.isEmpty
                      ? '${widget.articles.length} artikel'
                      : '${visible.length} hasil untuk “$_query”.',
                  style: const TextStyle(
                      fontSize: 13, color: kOnSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _query.isEmpty
                                  ? 'Kategori ini belum punya artikel.'
                                  : 'Tidak ada hasil untuk “$_query”.',
                              textAlign: TextAlign.center,
                            ),
                            if (_query.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                                child: const Text('Hapus pencarian'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) => ArticleRow(
                        article: visible[i],
                        onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                    article: visible[i],
                                    searchQuery: _query.isNotEmpty
                                        ? _query
                                        : null))),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Daftar sub-kelompok: satu kartu per sub berisi nama + jumlah artikel.
  /// Ketuk untuk membuka daftar artikel sub tersebut.
  Widget _buildSubList(BuildContext context, List<String> subs) {
    final counts = <String, int>{};
    for (final a in widget.articles) {
      final s = a.sub;
      if (s != null && s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kPrimary)),
        backgroundColor: kBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${subs.length} kelompok • ${widget.articles.length} artikel',
                style:
                    const TextStyle(fontSize: 13, color: kOnSurfaceVariant)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: subs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = subs[i];
                  final n = counts[s] ?? 0;
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: kOutlineVariant)),
                    elevation: 2,
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => CategoryScreen(
                                  category: widget.category,
                                  sub: s,
                                  articles: widget.articles
                                      .where((a) => a.sub == s)
                                      .toList()))),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(s,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$n artikel',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: kOnSurfaceVariant)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: kOnSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
