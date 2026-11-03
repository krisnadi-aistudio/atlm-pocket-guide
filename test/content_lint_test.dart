import 'dart:convert';

import 'package:atlm_pocket_guide/models.dart';
import 'package:atlm_pocket_guide/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lint konten otomatis: BUILD DITOLAK bila katalog artikel rusak.
/// Dijalankan via `flutter test` bersama suite lain. Memvalidasi
/// assets/articles.json yang di-bundle ke aplikasi (bukan staging):
/// - skema: field wajib isi, id unik, kategori dikenal
/// - body: ter-parse tanpa error, blok kritis tidak degeneratif
/// - aset: setiap PNG di formulaDisplays benar-benar ada
/// (penangkal "perubahan editorial kecil merusak tampilan diam-diam").
void main() {
  const categories = {
    'HEMATOLOGI',
    'KIMIA KLINIK',
    'URINALISA',
    'FAECES',
    'MIKROBIOLOGI',
    'IMUNOSEROLOGI',
    'PARASITOLOGI',
  };

  late List<dynamic> raw;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final s = await rootBundle.loadString('assets/articles.json');
    raw = json.decode(s) as List<dynamic>;
  });

  test('katalog valid dan tidak kosong', () {
    expect(raw, isNotEmpty);
  });

  test('skema artikel: field wajib, id unik, kategori dikenal', () {
    final ids = <String>{};
    for (final e in raw) {
      final a = e as Map<String, dynamic>;
      for (final f in ['id', 'title', 'category', 'body', 'reference']) {
        expect((a[f] as String?)?.trim().isNotEmpty, isTrue,
            reason: 'field "$f" kosong pada ${a['id']}');
      }
      expect(ids.add(a['id'] as String), isTrue,
          reason: 'id duplikat: ${a['id']}');
      expect(categories.contains(a['category']), isTrue,
          reason: 'kategori tak dikenal "${a['category']}" pada ${a['id']}');
    }
  });

  test('body ter-parse, blok kritis tidak degeneratif', () {
    for (final e in raw) {
      final a = e as Map<String, dynamic>;
      final secs = parseBodySections(a['body'] as String);
      expect(secs, isNotEmpty, reason: 'tanpa seksi: ${a['id']}');
      for (final s in secs) {
        if (s.kind == SectionKind.critical) {
          expect(s.items, isNotEmpty,
              reason: 'blok kritis tanpa item: ${a['id']}');
        }
      }
    }
  });

  test('aset rumus di formulaDisplays semuanya ada', () async {
    for (final entry in formulaDisplays.entries) {
      for (final p in entry.value.assets) {
        try {
          await rootBundle.load(p);
        } catch (_) {
          fail('aset hilang: $p (dipakai artikel ${entry.key})');
        }
      }
    }
  });

  test('setiap kategori data punya warna khusus (tidak jatuh ke default)',
      () {
    const defaultGrey = Color(0xFF607D8B);
    final cats = {
      for (final e in raw) (e as Map<String, dynamic>)['category'] as String
    };
    for (final c in cats) {
      expect(categoryStyle(c).color, isNot(defaultGrey),
          reason: 'kategori "$c" belum punya warna di categoryStyle()');
    }
  });
}
