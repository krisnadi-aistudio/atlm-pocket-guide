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

  test('findSectionForQuery cocok ke raw, kritis ikut dicari', () {
    const body =
        'Prinsip: Tes HPLC.\n\nTitik kritis: - HPLC berbahaya.\n\nRumus: x = y.';
    final secs = parseBodySections(body);
    expect(findSectionForQuery(secs, 'HPLC'), 0);
    expect(findSectionForQuery(secs, 'x = y'), 2);
    expect(findSectionForQuery(secs, 'tidak ada'), isNull);
    expect(findSectionForQuery(secs, ''), isNull);
  });

  test('findSectionForQuery: query ber-titik-dua cocok ke teks asli', () {
    const body = 'Prinsip: Tes A.\n\nSampel: darah vena, serum.';
    final secs = parseBodySections(body);
    expect(findSectionForQuery(secs, 'Sampel: darah'), 1);
  });

  test('findSectionForQuery: kecocokan di kritis mengembalikan indeks kritis',
      () {
    const body = 'Prinsip: Tes A.\n\nTitik kritis: Jangan pakai heparin.';
    final secs = parseBodySections(body);
    final idx = findSectionForQuery(secs, 'heparin');
    expect(idx, isNotNull);
    expect(secs[idx!].kind, SectionKind.critical);
  });

  test('critical: rentang angka tidak terpecah jadi item', () {
    expect(parseCriticalItems('Simpan pada 2 - 8 °C. - Cuci tangan dulu.'),
        ['Simpan pada 2 - 8 °C.', 'Cuci tangan dulu.']);
    expect(parseCriticalItems('pH 7,35 - 7,45 normal. - Ulangi.'),
        ['pH 7,35 - 7,45 normal.', 'Ulangi.']);
    // Pola tumpang-tindih: rentang berantai tetap utuh (review 3 Nov).
    expect(parseCriticalItems('- Suhu 1 - 2 - 3 °C. - Cuci tangan.'),
        ['Suhu 1 - 2 - 3 °C.', 'Cuci tangan.']);
    // ' - ' sesudah digit tapi sebelum huruf tetap pemisah item.
    expect(parseCriticalItems('- Dosis 2 - Ulangi 3x.'),
        ['Dosis 2', 'Ulangi 3x.']);
    // Sisa kosong ('- ' saja) -> daftar kosong, bukan item hampa.
    expect(parseCriticalItems('- '), isEmpty);
    expect(parseCriticalItems('• '), isEmpty);
  });

  test('sections: multiline berlabel di baris pertama jadi labeled', () {
    const body = 'Interpretasi: baris pertama\nbaris kedua lanjutan';
    final secs = parseBodySections(body);
    expect(secs.length, 1);
    expect(secs.first.kind, SectionKind.labeled);
    expect(secs.first.label, 'Interpretasi');
    expect(secs.first.text, 'baris pertama\nbaris kedua lanjutan');
  });

  test('sections: multiline tanpa label tetap multiline', () {
    const body = 'baris pertama biasa\nbaris kedua biasa';
    final secs = parseBodySections(body);
    expect(secs.length, 1);
    expect(secs.first.kind, SectionKind.multiline);
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
    final table = parseInterpretationRows(
        'Negatif: Garis C dan T muncul. Positif: Hanya garis C muncul. '
        'Tidak Valid: Garis C tidak muncul.');
    expect(table!.rows.length, 3);
    expect(table.rows[0].result, 'Negatif');
    expect(table.rows[0].explanation, 'Garis C dan T muncul');
    expect(table.rows[2].result, 'Tidak Valid');
    expect(table.prefix, isEmpty);
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

  test('interpretasi dengan prefix: prefix terpisah, tabel tetap jadi', () {
    final table = parseInterpretationRows(
        'Positif = basil merah tahan asam. Skala IUATLD/WHO. '
        'Negatif: 0 AFB. Scanty: 1-9 AFB. 1+: 10-99 AFB.');
    expect(table, isNotNull);
    expect(table!.prefix, 'Positif = basil merah tahan asam. Skala IUATLD/WHO.');
    expect(table.rows.length, 3);
    expect(table.rows[0].result, 'Negatif');
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
    expect(formulaDisplays.length, 24);
    expect(total, 32);
  });

  group('searchArticles', () {
    Article art(String id, String title, String body, String ref) => Article(
        id: id,
        title: title,
        category: 'KIMIA KLINIK',
        body: body,
        reference: ref);
    final a1 = art('g1', 'Glukosa Darah Puasa', 'Prinsip: enzimatik.',
        'American Diabetes Association. Standards of Care.');
    final a2 = art('u1', 'Urin Rutin', 'Prinsip: carik celup.',
        'Gandasoebrata. Penuntun Laboratorium Klinik.');

    test('cocok judul/body', () {
      expect(searchArticles([a1, a2], 'glukosa'), [a1]);
      expect(searchArticles([a1, a2], 'carik'), [a2]);
    });

    test('cocok referensi', () {
      expect(searchArticles([a1, a2], 'diabetes association'), [a1]);
    });

    test('sinonim istilah awam', () {
      expect(searchArticles([a1, a2], 'gula darah'), [a1]);
      expect(searchArticles([a1, a2], 'air kencing'), [a2]);
    });

    test('normalisasi spasi & kapital', () {
      expect(searchArticles([a1, a2], '  GLUKOSA   darah '), [a1]);
    });

    test('query kosong -> kosong', () {
      expect(searchArticles([a1, a2], '   '), isEmpty);
    });
  });

  group('adversarial parser (hasil debat ronde 10)', () {
    test('label lowercase tetap labeled', () {
      final s = parseBodySections('prinsip: xxx');
      expect(s.first.kind, SectionKind.labeled);
    });
    test('dua blok kritis -> dua seksi kritis', () {
      final s = parseBodySections('Titik kritis: a\n\nTitik kritis: b');
      expect(s.map((e) => e.kind),
          [SectionKind.critical, SectionKind.critical]);
    });
    test('label tanpa spasi -> paragraf', () {
      final s = parseBodySections('Sampel:darah');
      expect(s.first.kind, SectionKind.paragraph);
    });
    test('angka:jam bukan label', () {
      final s = parseBodySections('12:30 waktu inkubasi');
      expect(s.first.kind, SectionKind.paragraph);
    });
    test('kritis: separator trailing/leading', () {
      expect(parseCriticalItems('a - b - '), ['a', 'b']);
      expect(parseCriticalItems(' - a'), ['a']);
    });
    test('steps: desimal bukan langkah', () {
      expect(parseInlineSteps('Atur pH 7.5. Lanjutkan inkubasi.'), isNull);
    });
    test('find: query kosong -> null', () {
      final secs = parseBodySections('Prinsip: xxx\n\nSampel: yyy');
      expect(findSectionForQuery(secs, ''), isNull);
    });
    test('kritis multiline -> item per baris', () {
      final s = parseBodySections('Titik kritis: baris1\nbaris2');
      expect(s.first.kind, SectionKind.critical);
      expect(s.first.items, ['baris1', 'baris2']);
    });
  });
}
