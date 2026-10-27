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

  /// Jumlah item artikel yang dilewati karena rusak (dari
  /// loadArticles); bila > 0, Beranda menampilkan banner.
  final int skippedCount;
  const HomeScreen(
      {required this.articles, this.skippedCount = 0, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  int _gridMode = 2;
  String _versionText = 'Versi 1.5';
  final _searchController = TextEditingController();
  bool _skippedBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getInt(_gridModeKey);
      if (saved != null && mounted) setState(() => _gridMode = saved);
    }).catchError((_) {});
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        // Footer tampil mayor.minor saja ('Versi 1.5'), bukan
        // 'Versi 1.5.2'. Nomor build lengkap tampil di Tentang.
        setState(() => _versionText =
            'Versi ${info.version.split('.').take(2).join('.')}');
      }
    }).catchError((_) {});
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
      // Artikel 'Tentang Aplikasi Ini' bukan kategori kerja: jangan
      // sampai muncul sebagai kartu kategori hantu di Beranda.
      if (a.category == 'Tentang Aplikasi Ini') continue;
      if (!counts.containsKey(a.category)) categories.add(a.category);
      counts[a.category] = (counts[a.category] ?? 0) + 1;
    }
    final results = _query.isEmpty
        ? const <Article>[]
        : searchArticles(widget.articles, _query);

    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (widget.skippedCount > 0 && !_skippedBannerDismissed)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: kWarningContainer,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${widget.skippedCount} artikel tidak dapat dimuat.',
                          style:
                              const TextStyle(color: kOnWarning)),
                    ),
                    InkWell(
                      onTap: () => setState(
                          () => _skippedBannerDismissed = true),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 18, color: kOnWarning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    // Pengaturan dibuka langsung dari sini (tombol
                    // roda gigi); tab bawah dihapus.
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: kPrimary),
                      tooltip: 'Pengaturan',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                                articles: widget.articles)));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Selamat datang di Buku Saku ATLM',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchDelegate(
              SearchField(
                controller: _searchController,
                hintText: 'Cari istilah, pemeriksaan, atau spesimen…',
                showClear: _query.isNotEmpty,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
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
                      itemBuilder: (_) => [
                        CheckedPopupMenuItem(
                            value: 2,
                            checked: _gridMode == 2,
                            child: const Text('2 Kolom')),
                        CheckedPopupMenuItem(
                            value: 3,
                            checked: _gridMode == 3,
                            child: const Text('3 Kolom')),
                        CheckedPopupMenuItem(
                            value: 1,
                            checked: _gridMode == 1,
                            child: const Text('Daftar')),
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

/// Delegasi header pencarian menempel di Beranda: kolom pencarian
/// tetap terlihat saat daftar digulir. Tinggi tetap 68 (kolom 56 +
/// jarak bawah 12) supaya tidak ada pemotongan layout.
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickySearchDelegate(this.child);

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) =>
      oldDelegate.child != child;
}
