import 'dart:convert';
import 'dart:io';

import 'package:atlm_pocket_guide/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('critical inline items dipisah dengan benar', () {
    final items =
        parseCriticalItems('- Jangan baca >2 menit. - Uji lanjut weak D.');
    expect(items, ['Jangan baca >2 menit.', 'Uji lanjut weak D.']);
  });

  test('critical tanpa pemisah jadi satu item utuh', () {
    final items =
        parseCriticalItems('Periksa feses cair sesegera mungkin.');
    expect(items, ['Periksa feses cair sesegera mungkin.']);
  });

  test('critical multiline per baris', () {
    final items = parseCriticalItems('- Item satu\n- Item dua');
    expect(items, ['Item satu', 'Item dua']);
  });

  test('critical satu item berawalan dash tidak menyisakan dash', () {
    final items =
        parseCriticalItems('- Perhatikan keberadaan sel eritroblas.');
    expect(items, ['Perhatikan keberadaan sel eritroblas.']);
  });

  test('critical kosong menghasilkan list kosong', () {
    expect(parseCriticalItems(''), isEmpty);
  });

  test('sections: kritis diekstrak, label dikenali', () {
    const body =
        'Prinsip: Tes A.\n\nTitik kritis: - Waspada X. - Waspada Y.\n\nInterpretasi: Normal bila Z.';
    final secs = parseBodySections(body);
    expect(secs.length, 3);
    expect(secs[0].kind, SectionKind.labeled);
    expect(secs[0].label, 'Prinsip');
    expect(secs[0].text, 'Tes A.');
    expect(secs[1].kind, SectionKind.critical);
    expect(secs[1].items, ['Waspada X.', 'Waspada Y.']);
    expect(secs[2].label, 'Interpretasi');
  });

  test('tanda hubung di teks biasa tidak pernah dipecah', () {
    const body = 'Prinsip: Rentang 2 - 8 jam.';
    final secs = parseBodySections(body);
    expect(secs.length, 1);
    expect(secs[0].kind, SectionKind.labeled);
    expect(secs[0].text, 'Rentang 2 - 8 jam.');
  });

  test('findSectionForQuery melewati kritis dan menemukan seksi', () {
    const body =
        'Prinsip: Tes HPLC.\n\nTitik kritis: - HPLC berbahaya.\n\nRumus: x = y.';
    final secs = parseBodySections(body);
    expect(findSectionForQuery(secs, 'HPLC'), 0);
    expect(findSectionForQuery(secs, 'x = y'), 2);
    expect(findSectionForQuery(secs, 'tidak ada'), isNull);
    expect(findSectionForQuery(secs, ''), isNull);
  });

  test('cabang banner dipertahankan (dormant)', () {
    const body = 'Prinsip: Tes.\n\nPERLU VERIFIKASI — contoh.';
    final secs = parseBodySections(body);
    expect(secs[1].kind, SectionKind.banner);
  });

  test('langkah inline satu grup tanpa dan dengan preamble', () {
    final groups2 =
        parseInlineSteps('1. Siapkan alat. 2. Putar tabung. 3. Baca hasil.');
    expect(groups2!.length, 1);
    expect(groups2[0].preamble, '');
    expect(groups2[0].steps,
        ['Siapkan alat.', 'Putar tabung.', 'Baca hasil.']);
    final groups3 = parseInlineSteps(
        'Ambil darah. 1. Siapkan alat. 2. Putar tabung.');
    expect(groups3!.length, 1);
    expect(groups3[0].preamble, 'Ambil darah.');
    expect(groups3[0].steps, ['Siapkan alat.', 'Putar tabung.']);
  });

  test('langkah inline dua grup dengan preamble metode', () {
    final groups = parseInlineSteps('Metode Duke: 1. Bersihkan telinga. '
        '2. Tusuk lanset. Metode Ivy: 1. Pasang manset. 2. Buat insisi.');
    expect(groups!.length, 2);
    expect(groups[0].preamble, 'Metode Duke:');
    expect(groups[0].steps, ['Bersihkan telinga.', 'Tusuk lanset.']);
    expect(groups[1].preamble, 'Metode Ivy:');
    expect(groups[1].steps, ['Pasang manset.', 'Buat insisi.']);
  });

  test('langkah inline menolak bukan-urutan dan desimal', () {
    expect(parseInlineSteps('Hanya 1. langkah.'), isNull);
    expect(parseInlineSteps('Teks 2. bukan step 3. juga.'), isNull);
    expect(parseInlineSteps('Kadar 2.5 mg/dL normal. Suhu 37°C.'), isNull);
    expect(parseInlineSteps('1. Satu. 3. Lompat.'), isNull);
  });

  test('interpretasi berpasangan jadi baris kolom', () {
    final rows = parseInterpretationRows(
        'Negatif: Garis C dan T muncul. Positif: Hanya garis C muncul. '
        'Tidak Valid: Garis C tidak muncul.');
    expect(rows!.length, 3);
    expect(rows[0].result, 'Negatif');
    expect(rows[0].explanation, 'Garis C dan T muncul');
    expect(rows[2].result, 'Tidak Valid');
  });

  test('interpretasi prosa dan campuran tetap prosa', () {
    expect(
        parseInterpretationRows(
            'Mengevaluasi status anemia lewat indeks MCV dan RDW.'),
        isNull);
    expect(
        parseInterpretationRows(
            'BTA positif bila terlihat basil. Skala: Negatif = 0 AFB; '
            '1+ = 10-99 AFB.'),
        isNull);
  });

  test('peta rumus bergambar: kunci valid dan file ada', () {
    final raw = File('assets/articles.json').readAsStringSync();
    final ids = {
      for (final a in jsonDecode(raw) as List) (a as Map)['id'] as String
    };
    var total = 0;
    for (final entry in formulaDisplays.entries) {
      expect(ids.contains(entry.key), isTrue, reason: entry.key);
      for (final asset in entry.value.assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
        total++;
      }
    }
    expect(formulaDisplays.length, 12);
    expect(total, 17);
  });
}
