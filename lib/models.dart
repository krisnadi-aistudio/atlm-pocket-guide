import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Article {
  final String id;
  final String title;
  final String category;
  final String? sub;
  final String body;
  final String reference;

  Article({
    required this.id,
    required this.title,
    required this.category,
    this.sub,
    required this.body,
    required this.reference,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        sub: j['sub'] as String?,
        body: (j['body'] as String?) ?? '',
        reference: (j['reference'] as String?) ?? '',
      );

  /// Subjudul kata kunci ala SakuMedis: label sebelum ":" (2-24 huruf,
  /// tanpa angka), maks 4, dipisah " / ". Blok tabel (mengandung "|") dilewati.
  String get keywords {
    final labels = <String>[];
    for (final block in body.split('\n\n')) {
      if (block.contains('|')) continue;
      var text = block.trim();
      if (text.startsWith('• ')) text = text.substring(2).trim();
      final colon = text.indexOf(':');
      if (colon >= 2 && colon <= 24) {
        final label = text.substring(0, colon).trim();
        if (label.isNotEmpty &&
            !label.contains(RegExp(r'[0-9]')) &&
            !labels.contains(label)) {
          labels.add(label);
        }
      }
      if (labels.length >= 4) break;
    }
    return labels.join(' / ');
  }
}

Future<List<Article>> loadArticles() async {
  final raw = await rootBundle.loadString('assets/articles.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => Article.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Sinonim istilah awam -> istilah artikel (kurasi manual, kecil).
/// Dipakai memperluas query: artikel cocok bila query ATAU sinonimnya
/// cocok. Daftar sengaja pendek & tak-ambigu; sinonim salah = hasil
/// salah, jadi jangan ditambah tanpa verifikasi (3 Nov 2026).
const _searchSynonyms = <String, List<String>>{
  'gula darah': ['glukosa'],
  'kencing': ['urin'],
  'air kencing': ['urin'],
};

/// Normalisasi query: huruf kecil, spasi dirapikan.
String _normalizeQuery(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

List<Article> searchArticles(List<Article> all, String query) {
  final q = _normalizeQuery(query);
  if (q.isEmpty) return const [];
  // Kembangkan dengan sinonim yang kuncinya muncul di query.
  final terms = <String>[q];
  _searchSynonyms.forEach((key, values) {
    if (q.contains(key)) terms.addAll(values);
  });
  return all.where((a) {
    // Haystack dinormalisasi sama seperti query.
    final title = _normalizeQuery(a.title);
    final body = _normalizeQuery(a.body);
    final ref = _normalizeQuery(a.reference);
    return terms.any((t) =>
        title.contains(t) || body.contains(t) || ref.contains(t));
  }).toList();
}

/// SATU parser konten (build 1.5.2) — dipakai renderer tab Materi DAN
/// pencocokan passthrough pencarian. Jangan menulis parser kedua di
/// widget: perbaikan di sini otomatis berlaku di semua pemakaian.
///
/// Aturan (mempertahankan semantik render lama, plus perbaikan kritis):
/// - Blok dipisah '\n\n', dikosongkan yang kosong.
/// - Mengandung PERLU VERIFIKASI -> banner (jalur dormant: 0 blok kini).
/// - Diawali 'Titik kritis:' -> kartu kritis (lihat parseCriticalItems).
/// - Mengandung '\n' -> multiline (jalur dormant: 0 blok kini).
/// - Label 'X: ' (X 2-24 huruf, tanpa angka) -> seksi berlabel.
/// - Selain itu -> paragraf biasa.
enum SectionKind { labeled, critical, paragraph, multiline, banner }

class BodySection {
  final SectionKind kind;
  final String? label;
  final String text;
  final List<String>? items;
  final String raw;
  const BodySection(
      {required this.kind,
      this.label,
      required this.text,
      this.items,
      required this.raw});
}

List<BodySection> parseBodySections(String body) {
  final sections = <BodySection>[];
  for (final rawBlock in body.split('\n\n')) {
    final block = rawBlock.trim();
    if (block.isEmpty) continue;
    if (block.contains('PERLU VERIFIKASI')) {
      sections.add(BodySection(
          kind: SectionKind.banner, text: block, raw: block));
    } else if (block.startsWith('Titik kritis:')) {
      final rest = block.substring('Titik kritis:'.length).trim();
      sections.add(BodySection(
          kind: SectionKind.critical,
          label: 'Titik kritis',
          text: rest,
          items: parseCriticalItems(rest),
          raw: block));
    } else if (block.contains('\n')) {
      // Blok multiline: baris pertama bisa berupa label
      // ("Interpretasi: ..." lalu baris lanjutan) — deteksi dulu
      // sebelum fallback multiline, supaya accordion/label khusus
      // tetap dipakai.
      final firstLine = block.split('\n').first.trim();
      final firstColon = firstLine.indexOf(': ');
      if (firstColon >= 2 &&
          firstColon <= 24 &&
          !firstLine.substring(0, firstColon).contains(RegExp(r'[0-9]'))) {
        sections.add(BodySection(
            kind: SectionKind.labeled,
            label: firstLine.substring(0, firstColon),
            text: block.substring(firstColon + 2).trim(),
            raw: block));
      } else {
        sections.add(BodySection(
            kind: SectionKind.multiline, text: block, raw: block));
      }
    } else {
      final colon = block.indexOf(': ');
      if (colon >= 2 &&
          colon <= 24 &&
          !block.substring(0, colon).contains(RegExp(r'[0-9]'))) {
        sections.add(BodySection(
            kind: SectionKind.labeled,
            label: block.substring(0, colon),
            text: block.substring(colon + 2),
            raw: block));
      } else {
        sections.add(BodySection(
            kind: SectionKind.paragraph, text: block, raw: block));
      }
    }
  }
  return sections;
}

/// Item kartu kritis. Format data: sebaris ("- item1. - item2.") pada
/// 71 artikel; 2 artikel faeces berupa paragraf tanpa pemisah (1 item
/// utuh); format multiline dipertahankan untuk robustness.
/// PENTING: pemisah ' - ' HANYA dipecah di dalam blok kritis — tidak
/// pernah dipecah global pada teks lain. Rentang angka seperti
/// "2 - 8 °C" DILINDUNGI: ' - ' yang diapit digit di kedua sisi bukan
/// pemisah item (scanner manual agar pola tumpang-tindih
/// "1 - 2 - 3" tertangani).
bool _isAsciiDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

List<String> parseCriticalItems(String rest) {
  if (rest.isEmpty) return const [];
  if (rest.contains('\n')) {
    return rest
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.startsWith('- ')
            ? l.substring(2).trim()
            : (l.startsWith('• ') ? l.substring(2).trim() : l))
        .where((l) => l.isNotEmpty)
        .toList();
  }
  if (rest.contains(' - ')) {
    // Scanner manual: pecah pada ' - ' KECUALI yang diapit digit di
    // kedua sisi ("2 - 8 °C", "7,35 - 7,45", "1 - 2 - 3" tetap utuh).
    final parts = <String>[];
    final buf = StringBuffer();
    var i = 0;
    while (i < rest.length) {
      final j = rest.indexOf(' - ', i);
      if (j < 0) {
        buf.write(rest.substring(i));
        break;
      }
      final beforeDigit = j > 0 && _isAsciiDigit(rest[j - 1]);
      final afterDigit = j + 3 < rest.length && _isAsciiDigit(rest[j + 3]);
      if (beforeDigit && afterDigit) {
        buf.write(rest.substring(i, j + 3)); // pertahankan rentang
        i = j + 3;
      } else {
        buf.write(rest.substring(i, j));
        parts.add(buf.toString());
        buf.clear();
        i = j + 3;
      }
    }
    parts.add(buf.toString());
    final items = <String>[];
    for (var k = 0; k < parts.length; k++) {
      var p = parts[k].trim();
      if (k == 0 && p.startsWith('-')) p = p.substring(1).trim();
      if (p.isNotEmpty) items.add(p);
    }
    return items;
  }
  // Satu item saja: tetap buang awalan '- ' / '• ' bila ada, supaya
  // tidak tampil bullet ganda ('• - ...'). Kasus nyata 1.5.2:
  // hematologi-darah-rutin-hitung-jenis.
  // Sisa kosong ('- ' saja) -> daftar kosong, bukan item hampa
  // (adversarial 3 Nov 2026).
  if (rest.startsWith('- ')) {
    final t = rest.substring(2).trim();
    return t.isEmpty ? const [] : [t];
  }
  if (rest.startsWith('• ')) {
    final t = rest.substring(2).trim();
    return t.isEmpty ? const [] : [t];
  }
  return [rest];
}

/// Indeks seksi pertama yang teks aslinya (raw) mengandung query,
/// atau null. Dipakai passthrough pencarian: artikel dibuka dari
/// hasil pencarian langsung membuka/menggulir ke seksi yang cocok.
/// Mencocokkan ke `raw` (bukan label+teks) supaya query persis seperti
/// di body — mis. "Spesimen: darah" — tetap cocok. Kartu kritis ikut
/// dicari; pembukaannya TIDAK otomatis (prinsip terkunci: hanya ketukan
/// pengguna) — pemanggil cukup menggulir ke kartunya.
int? findSectionForQuery(List<BodySection> sections, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return null;
  for (var i = 0; i < sections.length; i++) {
    if (sections[i].raw.toLowerCase().contains(q)) return i;
  }
  return null;
}

/// Satu grup langkah inline: preamble opsional (mis. 'Metode Duke:')
/// + langkah-langkah bernomor dari 1.
class StepGroup {
  final String preamble;
  final List<String> steps;
  const StepGroup({required this.preamble, required this.steps});
}

/// Urutan langkah inline '1. ... 2. ...' di dalam satu blok teks.
/// Null bila bukan urutan langkah (fallback: paragraf biasa).
/// - Preamble = teks sebelum '1. ' pertama.
/// - Nomor yang kembali ke 1 memulai grup baru; label metode di ekor
///   step sebelumnya (teks setelah '. ' terakhir yang berakhir ':',
///   maks 60 karakter) dipindah jadi preamble grup baru.
/// - Tiap grup harus bernomor persis 1..n; bila tidak, null.
/// - Desimal aman: pola menuntut spasi setelah titik ('1. '), jadi
///   '1.5 M' atau '37°C' tidak pernah terpecah.
List<StepGroup>? parseInlineSteps(String text) {
  final matches = RegExp(r'(\d+)\.\s+').allMatches(text).toList();
  if (matches.length < 2) return null;
  if (int.parse(matches.first.group(1)!) != 1) return null;
  final firstPreamble = text.substring(0, matches.first.start).trim();
  final segments = <({int number, String body})>[];
  for (var i = 0; i < matches.length; i++) {
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    segments.add((
      number: int.parse(matches[i].group(1)!),
      body: text.substring(matches[i].end, end).trim(),
    ));
  }
  final groups = <StepGroup>[];
  var groupPreamble = firstPreamble;
  var steps = <String>[];
  for (final seg in segments) {
    if (seg.number == 1 && steps.isNotEmpty) {
      var last = steps.removeLast();
      var nextPreamble = '';
      final dot = last.lastIndexOf('. ');
      if (dot >= 0) {
        final tail = last.substring(dot + 2);
        if (tail.endsWith(':') && tail.length <= 60) {
          last = '${last.substring(0, dot)}.';
          nextPreamble = tail;
        }
      }
      steps.add(last);
      groups.add(StepGroup(preamble: groupPreamble, steps: List.of(steps)));
      groupPreamble = nextPreamble;
      steps = <String>[];
    }
    if (seg.number != steps.length + 1) return null;
    steps.add(seg.body);
  }
  groups.add(StepGroup(preamble: groupPreamble, steps: steps));
  return groups;
}

/// Satu baris tabel Interpretasi: hasil + keterangan.
class InterpretationRow {
  final String result;
  final String explanation;
  const InterpretationRow({required this.result, required this.explanation});
}

/// Tampilan Rumus sebagai gambar: daftar aset PNG + catatan teks
/// (kalimat penjelasan dari blok Rumus yang bukan persamaan).
/// Gambar dirender dari tools/render_formulas.py (matplotlib mathtext,
/// font Computer Modern, latar transparan) dan dibundel ke APK sehingga
/// aplikasi tetap offline penuh. Teks data di articles.json TIDAK diubah,
/// jadi pencarian tetap menemukan rumus lewat teksnya.
class FormulaDisplay {
  final List<String> assets;
  final String note;
  const FormulaDisplay({required this.assets, this.note = ''});
}

/// id artikel -> tampilan Rumus bergambar. 10 dari 24 blok Rumus
/// (per 2 Nov 2026): kriteria Light cairan pleura (bukan persamaan),
/// pelaporan sedimen urin (instruksi, bukan persamaan), dan blok Rumus
/// prosedural lain tetap tampil sebagai teks.
const formulaDisplays = <String, FormulaDisplay>{
  'hematologi-indeks-eritrosit': FormulaDisplay(assets: [
    'assets/formulas/hematologi-indeks-eritrosit-1.png',
    'assets/formulas/hematologi-indeks-eritrosit-2.png',
    'assets/formulas/hematologi-indeks-eritrosit-3.png',
  ]),
  'hematologi-rumus-retikulosit': FormulaDisplay(assets: [
    'assets/formulas/hematologi-rumus-retikulosit-1.png',
    'assets/formulas/hematologi-rumus-retikulosit-2.png',
  ], note: 'Jumlah total eritrosit terhitung minimal 1.000 sel.'),
  'hematologi-hitung-jenis-leukosit': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hitung-jenis-leukosit.png',
  ], note: 'Total persentase wajib tepat 100%.'),
  'hematologi-estimasi-barbara-brown': FormulaDisplay(assets: [
    'assets/formulas/hematologi-estimasi-trombosit-bb.png',
    'assets/formulas/hematologi-estimasi-leukosit-bb.png',
  ]),
  'hematologi-retikulosit-supravital': FormulaDisplay(assets: [
    'assets/formulas/hematologi-retikulosit-supravital.png',
  ]),
  'hematologi-konfirmasi-clumping-trombosit': FormulaDisplay(assets: [
    'assets/formulas/hematologi-koreksi-clumping.png',
  ]),
  'hematologi-hitung-leukosit-manual': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hitung-leukosit-dasar.png',
    'assets/formulas/hematologi-hitung-leukosit-cepat.png',
  ]),
  'hematologi-hitung-trombosit-manual': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hitung-trombosit-cepat.png',
  ]),
  'hematologi-hitung-eritrosit-manual': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hitung-eritrosit-cepat.png',
  ]),
  'hematologi-hitung-eosinofil-manual': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hitung-eosinofil-cepat.png',
  ]),
  'hematologi-mikrohematokrit': FormulaDisplay(assets: [
    'assets/formulas/hematologi-mikrohematokrit.png',
  ]),
  'hematologi-koreksi-nrbc': FormulaDisplay(assets: [
    'assets/formulas/hematologi-koreksi-nrbc.png',
  ]),
  'hematologi-koreksi-sitrat': FormulaDisplay(assets: [
    'assets/formulas/hematologi-koreksi-sitrat-trombosit.png',
    'assets/formulas/hematologi-koreksi-sitrat-volume.png',
  ]),
  'hematologi-rumple-leede': FormulaDisplay(assets: [
    'assets/formulas/hematologi-rumple-leede.png',
  ]),
  'hematologi-hb-sianmethemoglobin': FormulaDisplay(assets: [
    'assets/formulas/hematologi-hb-sianmet-1.png',
    'assets/formulas/hematologi-hb-sianmet-2.png',
  ]),
  'rujukan-analisa-cairan-pleura': FormulaDisplay(assets: [
    'assets/formulas/rujukan-kriteria-light.png',
  ]),
  'hematologi-nilai-absolut-nlr': FormulaDisplay(assets: [
    'assets/formulas/hematologi-nilai-absolut-nlr.png',
  ], note: 'Satuan: sel/µL.'),
  'hematologi-mikroskopis-malaria': FormulaDisplay(assets: [
    'assets/formulas/hematologi-mikroskopis-malaria.png',
  ], note: 'Bila tidak diketahui, gunakan nilai standar 8.000 '
      'leukosit/µL darah. Satuan: parasit per µL darah.'),
  'faal-ginjal-ureum-darah': FormulaDisplay(assets: [
    'assets/formulas/faal-ginjal-ureum-darah.png',
  ], note: 'Atau dikalikan 0,467.'),
  'lemak-kolesterol-ldl': FormulaDisplay(assets: [
    'assets/formulas/lemak-kolesterol-ldl.png',
  ], note: 'Rumus Friedewald, satuan mg/dL. Catatan: tidak valid dan '
      'dilarang digunakan apabila kadar Trigliserida > 400 mg/dL.'),
  'cairan-tubuh-calcium-ion': FormulaDisplay(assets: [
    'assets/formulas/cairan-tubuh-calcium-ion.png',
  ], note: 'Distandarisasi ke pH fisiologis 7,40.'),
  'cairan-tubuh-elektrolit-urine-na-k-cl': FormulaDisplay(assets: [
    'assets/formulas/cairan-tubuh-elektrolit-urine-na-k-cl.png',
  ], note: 'Satuan: mEq/24 jam; konsentrasi dalam mEq/L, volume dalam '
      'Liter.'),
  'faal-hati-bilirubin-indirek': FormulaDisplay(assets: [
    'assets/formulas/faal-hati-bilirubin-indirek.png',
  ], note: 'Satuan: mg/dL.'),
  'lain-lain-analisa-gas-darah': FormulaDisplay(assets: [
    'assets/formulas/lain-lain-analisa-gas-darah-1.png',
    'assets/formulas/lain-lain-analisa-gas-darah-2.png',
  ], note: 'HCO3- dalam mmol/L dan PaCO2 dalam mmHg. Celah anion dipakai '
      'menilai asidosis metabolik.'),
};

/// Pasangan 'Label: keterangan' pada blok Interpretasi.
/// Hanya bila SELURUH teks terdiri dari >= 2 pasangan (label maks 30
/// karakter, tanpa '.' ';' ':'); selain itu null (tetap prosa).
/// Contoh yang lolos: tes narkoba (Negatif/Positif/Tidak Valid),
/// gas darah (Tafsir dibaca berurutan/Nilai acuan klasik).
/// Hasil parse tabel interpretasi: prefix (teks pengantar sebelum tabel,
/// bisa kosong) + baris-baris tabel.
class InterpretationTable {
  final String prefix;
  final List<InterpretationRow> rows;
  const InterpretationTable({required this.prefix, required this.rows});
}

InterpretationTable? parseInterpretationRows(String text) {
  final pattern = RegExp(r'(?:^|\.\s+)([^.:;]{1,30}):\s+');
  final matches = pattern.allMatches(text).toList();
  if (matches.length < 2) return null;
  // Prefix: teks sebelum baris tabel pertama (boleh kosong).
  // Jika match diawali ".\s+", sertakan titiknya di prefix.
  var prefixEnd = matches.first.start;
  if (prefixEnd > 0 && text[prefixEnd] == '.') prefixEnd += 1;
  final prefix = text.substring(0, prefixEnd).trim();
  // Validasi: prefix tidak boleh mengandung pola "Label:" yang terlewat
  // (artinya tabel tidak berurutan).
  final rows = <InterpretationRow>[];
  for (var i = 0; i < matches.length; i++) {
    final nextStart =
        i + 1 < matches.length ? matches[i + 1].start : text.length;
    var body = text.substring(matches[i].end, nextStart).trim();
    if (body.endsWith('.')) {
      body = body.substring(0, body.length - 1).trim();
    }
    if (body.isEmpty) return null;
    rows.add(InterpretationRow(
        result: matches[i].group(1)!.trim(), explanation: body));
  }
  return InterpretationTable(prefix: prefix, rows: rows);
}
