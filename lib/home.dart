import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'widgets.dart';
import 'category.dart';
import 'detail.dart';
import 'about.dart';
import 'theme_controller.dart';

const _gridModeKey = 'grid_mode'; // 2 = 2 kolom, 3 = 3 kolom, 1 = daftar

/// Beranda ala SakuMedis: header logo + sapaan + cari menonjol +
/// grid kategori (pill jumlah) + toggle tampilan, tersimpan lokal.
class HomeScreen extends StatefulWidget {
  final List<Article> articles;
  const HomeScreen({required this.articles, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Sapaan berdasar jam perangkat: pagi 04-10, siang 11-14,
/// sore 15-18, malam 19-03.
String _salamWaktu() {
  final jam = DateTime.now().hour;
  if (jam >= 4 && jam < 11) {
    return 'Selamat pagi kak, selamat beraktifitas.';
  } else if (jam >= 11 && jam < 15) {
    return 'Selamat siang kak, tetap semangat.';
  } else if (jam >= 15 && jam < 19) {
    return 'Selamat sore kak, semoga hari mu menyenangkan.';
  } else {
    return 'Selamat malam kak, selamat beristirahat.';
  }
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
      // Terima hanya 1/2/3; nilai lama/rusak diabaikan (pakai default 2).
      if ((saved == 1 || saved == 2 || saved == 3) && mounted) {
        setState(() => _gridMode = saved!);
      }
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
    // Urutan kategori = alfabetis A-Z.
    final categories = <String>[];
    for (final a in widget.articles) {
      if (!categories.contains(a.category)) categories.add(a.category);
    }
    categories.sort();
    final results = _query.isEmpty
        ? const <Article>[]
        : searchArticles(widget.articles, _query);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header minimalis 1 baris ala SakuMedis: logo + nama,
          // nempel di atas saat scroll (freeze).
          SliverAppBar(
            pinned: true,
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                const LabLogo(32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('SakuATLM',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
            actions: [
              // Tombol mode gelap di samping Pengaturan.
              // Tooltip dinamis: menyebut aksi yang akan terjadi.
              IconButton(
                // brightness_2 dicerminkan horizontal agar sabit tidak "kebalik".
                icon: Theme.of(context).brightness == Brightness.dark
                    ? Icon(
                        Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.141592653589793),
                        child: Icon(
                          Icons.brightness_2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Aktifkan mode terang'
                    : 'Aktifkan mode gelap',
                onPressed: () => ThemeController.toggle(context),
              ),
              // Pengaturan (titik 3).
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary),
                tooltip: 'Pengaturan',
                onSelected: (v) {
                  if (v == 'settings') {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(articles: widget.articles)));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings,
                            color:
                                Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text('Pengaturan'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                Text(_salamWaktu(),
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Label permanen untuk screen reader (hintText hilang
                // setelah pengguna mengetik).
                Semantics(
                  label: 'Cari artikel',
                  textField: true,
                  child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Mau cari apa kak?!',
                    hintStyle: const TextStyle(fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon:
                        Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    ),
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
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      icon: Icon(Icons.grid_view_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      tooltip: 'Ubah tampilan grid',
                      onSelected: _setGridMode,
                      // Mode aktif ditandai (terbaca screen reader).
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
                    child: Text('SakuATLM • $_versionText',
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text('Disusun oleh Muhammad Krisnadi Wibowo',
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
