import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'home.dart';

void main() {
  runApp(const AtlmApp());
}

class AtlmApp extends StatelessWidget {
  const AtlmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buku Saku ATLM',
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
      home: const AppShell(),
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
  Future<List<Article>> _articlesFuture = loadArticles();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _articlesFuture,
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
                      _articlesFuture = loadArticles();
                    }),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(body: HomeScreen(articles: snapshot.data!));
      },
    );
  }
}
