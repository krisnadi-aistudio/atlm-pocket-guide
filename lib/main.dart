import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'home.dart';
import 'splash.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const AtlmApp());
}

class AtlmApp extends StatelessWidget {
  const AtlmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, __) => MaterialApp(
      title: 'SakuATLM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          onPrimary: Colors.white,
          primaryContainer: kPrimaryContainer,
          onPrimaryContainer: kOnPrimaryContainer,
          surface: Colors.white,
          onSurface: kOnSurface,
          surfaceContainerHighest: kSurfaceVariant,
          onSurfaceVariant: kOnSurfaceVariant,
          outlineVariant: kOutlineVariant,
        ),
        scaffoldBackgroundColor: kBackground,
        useMaterial3: true,
      ),
      // Tema gelap mengikuti pengaturan sistem Android. Warna kategori
      // (ikon/label) TIDAK berubah; hanya permukaan, teks, dan aksen
      // yang menyesuaikan agar tetap terbaca di latar gelap.
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryDark,
          onPrimary: kOnPrimaryDark,
          primaryContainer: kPrimaryContainerDark,
          onPrimaryContainer: kOnPrimaryContainerDark,
          surface: kSurfaceDark,
          onSurface: kOnSurfaceDark,
          surfaceContainerHighest: kSurfaceVariantDark,
          onSurfaceVariant: kOnSurfaceVariantDark,
          outlineVariant: kOutlineVariantDark,
        ),
        scaffoldBackgroundColor: kBackgroundDark,
        useMaterial3: true,
      ),
      themeMode: mode,
      home: const AppShell(),
      ),
    );
  }
}

/// Kerangka aplikasi: satu layar Beranda penuh (tab bawah dihapus).
/// Pengaturan dibuka lewat titik 3 di Beranda. Tanpa login, tanpa
/// bookmark, tanpa iklan, tanpa server — seluruh konten lokal.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late Future<List<Article>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _load();
  }

  /// Muat artikel + jeda minimum splash (1,4 dtk) agar branding sempat terlihat.
  Future<List<Article>> _load() => Future.wait([
        loadArticles(),
        Future.delayed(const Duration(milliseconds: 1400)),
      ]).then((v) => v[0] as List<Article>);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Gagal memuat konten lokal: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _initFuture = _load();
                    }),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )),
          );
        }
        if (!snapshot.hasData) {
          return const SplashScreen();
        }
        return Scaffold(body: HomeScreen(articles: snapshot.data!));
      },
    );
  }
}
