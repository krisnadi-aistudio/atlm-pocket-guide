import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'detail.dart';

/// Layar kategori sendiri: cari dalam kategori + daftar artikelnya
/// saja. Kembali mengantar ke Beranda.
class CategoryScreen extends StatefulWidget {
  final String category;
  final List<Article> articles;
  const CategoryScreen(
      {required this.category, required this.articles, super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.articles
        : widget.articles
            .where((a) =>
                a.title.toLowerCase().contains(_query.toLowerCase()) ||
                a.body.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    // Urutan dasar layar kategori selalu A–Z (case-insensitive);
    // hasil filter pencarian mewarisi urutan ini.
    final visible = List.of(filtered)
      ..sort((a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kPrimary)),
        backgroundColor: kBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchField(
              controller: _controller,
              hintText: 'Cari judul atau kata kunci di kategori ini…',
              showClear: _query.isNotEmpty,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  _query.isEmpty
                      ? '${widget.articles.length} artikel'
                      : '${visible.length} hasil untuk “$_query”.',
                  style: const TextStyle(
                      fontSize: 13, color: kOnSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _query.isEmpty
                                  ? 'Kategori ini belum punya artikel.'
                                  : 'Tidak ada hasil untuk “$_query”.',
                              textAlign: TextAlign.center,
                            ),
                            if (_query.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                                child: const Text('Hapus pencarian'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) => ArticleRow(
                        article: visible[i],
                        onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                    article: visible[i],
                                    searchQuery: _query.isNotEmpty
                                        ? _query
                                        : null))),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
