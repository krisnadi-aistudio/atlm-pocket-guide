import 'package:atlm_pocket_guide/category.dart';
import 'package:atlm_pocket_guide/detail.dart';
import 'package:atlm_pocket_guide/home.dart';
import 'package:atlm_pocket_guide/models.dart';
import 'package:atlm_pocket_guide/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart'
    show wakelockPlusPlatformInstance;
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Widget test SakuATLM: memverifikasi kelakuan UI tanpa aset/platform asli.
/// Dijalankan via `flutter test`. Tidak ikut ke APK.

Article _art({
  required String id,
  required String title,
  String category = 'HEMATOLOGI',
  String? sub,
  required String body,
}) =>
    Article(
        id: id,
        title: title,
        category: category,
        sub: sub,
        body: body,
        reference: 'Ref uji.');

final _fxA = _art(
  id: 't1',
  title: 'Hitung Leukosit Manual',
  sub: 'Leukosit',
  body: 'Prinsip: Hitung manual bilik hitung.\n\n'
      'Sampel: darah EDTA.\n\n'
      'Titik kritis: Jangan pakai heparin - Segera periksa.',
);
final _fxB = _art(
  id: 't2',
  title: 'Uji Rumple Leede',
  sub: 'Hemostasis',
  body: 'Prinsip: Uji kerapuhan kapiler.\n\n'
      'Cara pemeriksaan manual: 1. Pasang manset. 2. Tunggu 5 menit.',
);
final _fxNoSub = _art(
  id: 't3',
  title: 'Artikel Tanpa Sub',
  body: 'Prinsip: Umum.',
);

class _FakeWakelock extends WakelockPlusPlatformInterface {
  final calls = <bool>[];
  @override
  Future<void> toggle({required bool enable}) async {
    calls.add(enable);
  }

  @override
  Future<bool> get enabled async => calls.isNotEmpty && calls.last;
}

void main() {
  late _FakeWakelock fakeWakelock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'SakuATLM',
      packageName: 'id.atlm.pocketguide',
      version: '1.5.9',
      buildNumber: '14',
      buildSignature: '',
    );
    ThemeController.mode.value = ThemeMode.system;
    fakeWakelock = _FakeWakelock();
    WakelockPlusPlatformInterface.instance = fakeWakelock;
    // wakelock_plus men-cache instance di variabel top-level
    // (lazy); tanpa ini, tes berurutan memakai fake basi.
    wakelockPlusPlatformInstance = fakeWakelock;
  });

  // HomeScreen bukan Scaffold penuh (di aplikasi ia menjadi body Scaffold),
  // jadi bungkus dengan Scaffold agar TextField punya ancestor Material.
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

  group('Beranda', () {
    testWidgets('menampilkan kartu kategori dari daftar artikel',
        (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      expect(find.text('HEMATOLOGI'), findsOneWidget);
      // Sapaan dinamis berdasar jam perangkat.
      expect(find.textContaining('Selamat'), findsOneWidget);
    });

    testWidgets('pencarian memfilter lalu kembali ke grid', (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      await t.enterText(
          find.byType(TextField), 'leukosit');
      await t.pump();
      expect(find.text('Hitung Leukosit Manual'), findsOneWidget);
      expect(find.text('Uji Rumple Leede'), findsNothing);
      await t.enterText(find.byType(TextField), '');
      await t.pump();
      expect(find.text('HEMATOLOGI'), findsOneWidget);
    });

    testWidgets('ketuk hasil pencarian membuka DetailScreen', (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      await t.enterText(find.byType(TextField), 'leukosit');
      await t.pump();
      await t.tap(find.text('Hitung Leukosit Manual'));
      await t.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);
      // Judul artikel tampil di body detail.
      expect(find.text('Hitung Leukosit Manual'), findsWidgets);
    });

    testWidgets('ketuk kartu kategori membuka CategoryScreen', (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      await t.tap(find.text('HEMATOLOGI'));
      await t.pumpAndSettle();
      expect(find.byType(CategoryScreen), findsOneWidget);
    });
  });

  group('DetailScreen', () {
    testWidgets('seksi berlabel tertutup default, ketuk membuka-menutup',
        (t) async {
      await t.pumpWidget(wrap(DetailScreen(article: _fxA)));
      await t.pump();
      expect(find.text('Sampel'), findsOneWidget);
      expect(find.text('darah EDTA.'), findsNothing);
      await t.tap(find.text('Sampel'));
      await t.pump();
      expect(find.text('darah EDTA.'), findsOneWidget);
      await t.tap(find.text('Sampel'));
      await t.pump();
      expect(find.text('darah EDTA.'), findsNothing);
    });

    testWidgets(
        'PRINSIP TERKUNCI: Catatan penting hanya terbuka oleh ketukan langsung',
        (t) async {
      await t.pumpWidget(wrap(DetailScreen(article: _fxA)));
      await t.pump();
      expect(find.text('Catatan penting'), findsOneWidget);
      expect(find.text('Jangan pakai heparin'), findsNothing);
      // Membuka seksi lain TIDAK boleh membukanya.
      await t.tap(find.text('Sampel'));
      await t.pump();
      expect(find.text('darah EDTA.'), findsOneWidget);
      expect(find.text('Jangan pakai heparin'), findsNothing);
      // Hanya ketukan langsung yang membukanya.
      await t.tap(find.text('Catatan penting'));
      await t.pump();
      expect(find.text('Jangan pakai heparin'), findsOneWidget);
    });

    testWidgets('passthrough membuka seksi berlabel yang cocok', (t) async {
      await t.pumpWidget(
          wrap(DetailScreen(article: _fxA, searchQuery: 'EDTA')));
      await t.pump();
      expect(find.text('darah EDTA.'), findsOneWidget);
    });

    testWidgets(
        'passthrough ke kritis TIDAK auto-buka kartu (prinsip terkunci)',
        (t) async {
      await t.pumpWidget(
          wrap(DetailScreen(article: _fxA, searchQuery: 'heparin')));
      await t.pump();
      expect(find.text('Catatan penting'), findsOneWidget);
      expect(find.text('Jangan pakai heparin'), findsNothing);
    });

    testWidgets('bench mode memanggil enable lalu disable', (t) async {
      await t.pumpWidget(wrap(DetailScreen(article: _fxA)));
      await t.pump();
      await t.tap(find.byIcon(Icons.lightbulb_outline));
      await t.pump();
      expect(fakeWakelock.calls, [true]);
      await t.tap(find.byIcon(Icons.lightbulb));
      await t.pump();
      expect(fakeWakelock.calls, [true, false]);
    });

    testWidgets('bench mode mati saat halaman ditutup (anti race)',
        (t) async {
      await t.pumpWidget(wrap(DetailScreen(article: _fxA)));
      await t.pump();
      await t.tap(find.byIcon(Icons.lightbulb_outline));
      await t.pump();
      expect(fakeWakelock.calls, [true]);
      // Tutup halaman saat wakelock aktif -> dispose harus mematikan.
      await t.pumpWidget(wrap(const SizedBox()));
      await t.pump();
      expect(fakeWakelock.calls.last, false);
    });
  });

  group('Alur perilaku', () {
    testWidgets('kategori -> sub -> artikel -> detail', (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      await t.tap(find.text('HEMATOLOGI'));
      await t.pumpAndSettle();
      expect(find.byType(CategoryScreen), findsOneWidget);
      await t.tap(find.text('Leukosit'));
      await t.pumpAndSettle();
      await t.tap(find.text('Hitung Leukosit Manual'));
      await t.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);
    });

    testWidgets('mode grid diubah via menu dan tersimpan', (t) async {
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      // Default 2 kolom: SliverGrid.
      expect(find.byType(SliverGrid), findsOneWidget);
      await t.tap(find.byIcon(Icons.grid_view_rounded));
      await t.pumpAndSettle();
      // Ketuk item menu 'Daftar' (indeks 2).
      await t.tap(find.byType(CheckedPopupMenuItem<int>).at(2));
      await t.pumpAndSettle();
      // Tutup menu bila masih terbuka (quirks harness uji).
      if (find.byType(CheckedPopupMenuItem<int>).evaluate().isNotEmpty) {
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();
      }
      // Mode daftar: tidak ada SliverGrid lagi.
      expect(find.byType(SliverGrid), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('grid_mode'), 1);
      // Muat ulang: mode daftar dipertahankan.
      await t.pumpWidget(wrap(HomeScreen(articles: [_fxA, _fxB])));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(SliverGrid), findsNothing);
    });

    test('ThemeController.setMode tersimpan di prefs', () async {
      await ThemeController.setMode(ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(ThemeController.mode.value, ThemeMode.dark);
    });
  });

  group('CategoryScreen', () {
    testWidgets('daftar sub + grup Lainnya untuk artikel tanpa sub',
        (t) async {
      await t.pumpWidget(wrap(CategoryScreen(
          category: 'HEMATOLOGI',
          articles: [_fxA, _fxB, _fxNoSub])));
      await t.pump();
      expect(find.text('Leukosit'), findsOneWidget);
      expect(find.text('Hemostasis'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);
      await t.tap(find.text('Lainnya'));
      await t.pumpAndSettle();
      expect(find.text('Artikel Tanpa Sub'), findsOneWidget);
    });
  });

  group('ThemeController', () {
    testWidgets('toggle membalik terang <-> gelap', (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = t.element(find.byType(Scaffold));
      ThemeController.mode.value = ThemeMode.light;
      await ThemeController.toggle(ctx);
      expect(ThemeController.mode.value, ThemeMode.dark);
      await ThemeController.toggle(ctx);
      expect(ThemeController.mode.value, ThemeMode.light);
    });
  });
}
