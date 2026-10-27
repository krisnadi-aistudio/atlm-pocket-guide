import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'widgets.dart';
import 'category.dart';
import 'detail.dart';
import 'about.dart';

const _gridModeKey = 'grid_mode'; // 2 = 2 kolom, 3 = 3 kolom, 1 = daftar

/// Beranda ala SakuMedis: header logo + sapaan + cari menonjol +
/// grid kategori (pill jumlah) + toggle tampilan, tersimpan lokal.
class HomeScreen extends StatefulWidget {
  final List<Article> articles;
  const HomeScreen({required this.articles, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  int _gridMode = 2;
  String _versionText = 'Versi 1.5';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getInt(_gridModeKey);
      if (saved != null && mounted) setState(() => _gridMode = saved);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        // Footer tampil mayor.minor saja ('Versi 1.5'), bukan
        // 'Versi 1.5.2'. Nomor build lengkap tampil di Tentang.
        setState(() => _versionText =
            'Versi ${info.version.split('.').take(2).join('.')}');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setGridMode(int mode) async {
    setState(() => _gridMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gridModeKey, mode);
  }

  void _openArticle(BuildContext context, Article article,
      {String? searchQuery}) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            DetailScreen(article: article, searchQuery: searchQuery)));
  }

  void _openCategory(BuildContext context, String category) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CategoryScreen(
            category: category,
            articles: widget.articles
                .where((a) => a.category == category)
                .toList())));
  }

  @override
  Widget build(BuildContext context) {
    // Urutan kategori = urutan kemunculan pertama di JSON (stabil).
    final categories = <String>[];
    final counts = <String, int>{};
    for (final a in widget.articles) {
      if (!counts.containsKey(a.category)) categories.add(a.category);
      counts[a.category] = (counts[a.category] ?? 0) + 1;
    }
    final results = _query.isEmpty
        ? const <Article>[]
        : searchArticles(widget.articles, _query);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const LabLogo(44),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buku Saku ATLM',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary)),
                          Text(
                              'Referensi cepat analis laboratorium',
                              style: TextStyle(
                                  fontSize: 13, color: kOnSurfaceVariant)),
                        ],
                      ),
                    ),
                    // Pengaturan pindah ke sini (titik 3); tab bawah dihapus.
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: kPrimary),
                      tooltip: 'Pengaturan',
                      onSelected: (v) {
                        if (v == 'settings') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                  articles: widget.articles)));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: kPrimary),
                              SizedBox(width: 12),
                              Text('Pengaturan'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Selamat datang di Buku Saku ATLM',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari istilah, pemeriksaan, atau spesimen…',
                    prefixIcon:
                        const Icon(Icons.search, color: kPrimary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: kSurfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: kPrimary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          if (_query.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                      results.isEmpty
                          ? 'Tidak ditemukan untuk “$_query”.'
                          : '${results.length} hasil untuk “$_query”.',
                      style: const TextStyle(
                          fontSize: 13, color: kOnSurfaceVariant)),
                  const SizedBox(height: 12),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SectionHeader(
                    title: 'Kategori',
                    trailing: PopupMenuButton<int>(
                      icon: const Icon(Icons.grid_view_rounded,
                          color: kPrimary),
                      tooltip: 'Ubah tampilan grid',
                      onSelected: _setGridMode,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 2, child: Text('2 Kolom')),
                        PopupMenuItem(value: 3, child: Text('3 Kolom')),
                        PopupMenuItem(value: 1, child: Text('Daftar')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          if (_query.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ArticleRow(
                      article: results[i],
                      showCategory: true,
                      onOpen: () => _openArticle(context, results[i],
                          searchQuery: _query),
                    ),
                  ),
                  childCount: results.length,
                ),
              ),
            )
          else if (_gridMode == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CategoryCard(
                      category: categories[i],
                      count: counts[categories[i]] ?? 0,
                      mode: 1,
                      onTap: () => _openCategory(context, categories[i]),
                    ),
                  ),
                  childCount: categories.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridMode,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: _gridMode == 3 ? 0.95 : 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => CategoryCard(
                    category: categories[i],
                    count: counts[categories[i]] ?? 0,
                    mode: _gridMode,
                    onTap: () => _openCategory(context, categories[i]),
                  ),
                  childCount: categories.length,
                ),
              ),
            ),
          // Footer kredit di bawah Beranda (pengganti tab bawah):
          // nama + versi + penyusun, teks kecil abu-abu.
          if (_query.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Text('Buku Saku ATLM • $_versionText',
                        style: const TextStyle(
                            fontSize: 12, color: kOnSurfaceVariant)),
                  ),
                  const SizedBox(height: 2),
                  const Center(
                    child: Text('Disusun oleh Muhammad Krisnadi Wibowo',
                        style: TextStyle(
                            fontSize: 12, color: kOnSurfaceVariant)),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
