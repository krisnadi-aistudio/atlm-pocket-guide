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
    final visible = _query.isEmpty
        ? widget.articles
        : widget.articles
            .where((a) =>
                a.title.toLowerCase().contains(_query.toLowerCase()) ||
                a.body.toLowerCase().contains(_query.toLowerCase()))
            .toList();
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
            TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari di kategori ini…',
                prefixIcon: const Icon(Icons.search, color: kPrimary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
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
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  _query.isEmpty
                      ? '${widget.articles.length} artikel'
                      : visible.isEmpty
                          ? 'Tidak ditemukan untuk “$_query”.'
                          : '${visible.length} hasil untuk “$_query”.',
                  style: const TextStyle(
                      fontSize: 13, color: kOnSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada artikel di kategori ini.'),
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
