import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'models.dart';
import 'detail.dart';
import 'widgets.dart';

/// Layar Pengaturan gaya layar Akun SakuMedis: baris-baris berkelompok.
/// Dibuka lewat titik 3 di Beranda (tab bawah dihapus) — sebagai halaman
/// biasa dengan tombol kembali, bukan lagi tab.
class SettingsScreen extends StatefulWidget {
  final List<Article> articles;
  const SettingsScreen({required this.articles, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionText = 'Versi 1.5';
  String _fullVersionText = 'Versi 1.5.4 (build 9)';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        // Pill & footer tampil mayor.minor ('Versi 1.5'); nomor build
        // lengkap tampil di subtitle baris Tentang + halaman Tentang.
        setState(() {
          _versionText =
              'Versi ${info.version.split('.').take(2).join('.')}';
          _fullVersionText =
              'Versi ${info.version} (build ${info.buildNumber})';
        });
      }
    }).catchError((_) {});
  }

  void _openFeatures(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _FeaturesPage()));
  }

  void _openDisclaimer(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _DisclaimerPage()));
  }

  void _openAboutApp(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _AboutAppPage(
            articles: widget.articles,
            versionText: _versionText,
            fullVersionText: _fullVersionText)));
  }

  void _openInfo(BuildContext context, _InfoPage page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => _InfoPageScreen(page: page)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Pengaturan',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimary)),
          backgroundColor: kBackground,
          elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsGroup(rows: [
                _SettingsRow(
                    icon: Icons.lightbulb,
                    title: 'Fitur',
                    onTap: () => _openFeatures(context)),
                _SettingsRow(
                    icon: Icons.gavel,
                    title: 'Syarat & Ketentuan',
                    onTap: () => _openInfo(context, _InfoPage.terms)),
                _SettingsRow(
                    icon: Icons.policy,
                    title: 'Kebijakan Privasi',
                    onTap: () => _openInfo(context, _InfoPage.privacy)),
                _SettingsRow(
                    icon: Icons.medical_services,
                    title: 'Disclaimer Medis',
                    onTap: () => _openDisclaimer(context)),
              ]),
              const SizedBox(height: 16),
              _SettingsGroup(rows: [
                _SettingsRow(
                    icon: Icons.info,
                    title: 'Tentang Aplikasi',
                    subtitle: _fullVersionText,
                    onTap: () => _openAboutApp(context)),
                _SettingsRow(
                    icon: Icons.code,
                    title: 'Lisensi Open Source',
                    onTap: () => _openInfo(context, _InfoPage.openSource)),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu baris pengaturan (tanpa kartu sendiri): dipakai di dalam
/// _SettingsGroup supaya baris-baris sejenis menyatu dalam satu kartu
/// dengan pemisah, bukan kartu terpisah per baris. Tinggi baris
/// minimal 80 (ikon 48 + padding 16) sehingga target sentuh aman.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsRow(
      {required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: kPrimaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 13, color: kOnSurfaceVariant)),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Kartu grup baris pengaturan: satu kartu, baris dipisah Divider.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> rows;
  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kOutlineVariant)),
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, color: kOutlineVariant),
          ],
        ],
      ),
    );
  }
}

/// Halaman penjabaran fitur: satu kategori fitur dalam satu halaman.
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Fitur',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimary)),
          backgroundColor: kBackground,
          elevation: 0),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoRow(
              icon: Icons.search,
              title: 'Pencarian Lokal',
              description:
                  'Cari istilah, pemeriksaan, dan spesimen tanpa internet.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: Icons.lightbulb,
              title: 'Bench Mode',
              description:
                  'Layar tetap menyala saat tangan sibuk di meja kerja.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: Icons.wifi_off,
              title: 'Sepenuhnya Offline',
              description:
                  'Semua artikel tersimpan di perangkat, tanpa akun dan tanpa server.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: Icons.info_outline,
              title: 'Batasan yang disengaja',
              description:
                  'Tanpa akun, tanpa riwayat baca, dan tanpa bookmark — dibuka untuk satu keperluan, lalu ditutup.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman Disclaimer Medis: isi banner "Penting untuk pengguna"
/// yang dulu nempel di layar Tentang — kini hanya tinggal di sini.
class _DisclaimerPage extends StatelessWidget {
  const _DisclaimerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Disclaimer Medis',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimary)),
          backgroundColor: kBackground,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWarningContainer,
            border: Border.all(color: kWarningBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Penting untuk pengguna',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kOnWarning)),
              SizedBox(height: 4),
              Text(
                  'Aplikasi ini adalah alat bantu referensi, bukan pengganti SOP laboratorium dan penilaian tenaga kompeten.',
                  style: TextStyle(color: kOnWarning)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halaman Tentang Aplikasi: logo + deskripsi satu kalimat + kartu
/// penyusun + seksi artikel 'Tentang Aplikasi Ini' (bila ada) + footer.
/// Profil penyusun hanya tinggal di sini, bukan di layar Pengaturan utama.
class _AboutAppPage extends StatelessWidget {
  final List<Article> articles;
  final String versionText;
  final String fullVersionText;
  const _AboutAppPage(
      {required this.articles,
      required this.versionText,
      required this.fullVersionText});

  void _openArticle(BuildContext context, Article article) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(article: article)));
  }

  @override
  Widget build(BuildContext context) {
    final aboutArticles = articles
        .where((a) => a.category == 'Tentang Aplikasi Ini')
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Tentang Aplikasi',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimary)),
          backgroundColor: kBackground,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: kOutlineVariant)),
              elevation: 2,
              color: Colors.white,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const LabLogo(72),
                    const SizedBox(height: 14),
                    const Text('Buku Saku ATLM',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('Referensi cepat analis laboratorium',
                        style: TextStyle(
                            fontSize: 14, color: kOnSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(versionText,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kOnPrimaryContainer)),
                    ),
                    const SizedBox(height: 6),
                    Text(fullVersionText,
                        style: const TextStyle(
                            fontSize: 12, color: kOnSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Disusun analis laboratorium medik untuk rekan analis — referensi cepat yang dibuka saat bekerja, tanpa buku tebal, tanpa internet, tanpa akun, gratis.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: kOutlineVariant)),
              elevation: 2,
              color: Colors.white,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Muhammad Krisnadi Wibowo',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Analis Teknologi Laboratorium Medik',
                        style: TextStyle(color: kOnSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                            color: kAmber,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    const Text('Buku saku untuk analis laboratorium',
                        style: TextStyle(color: kOnSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (aboutArticles.isNotEmpty) ...[
              const SectionHeader(title: 'Tentang Aplikasi Ini'),
              const SizedBox(height: 12),
              for (int i = 0; i < aboutArticles.length; i++) ...[
                ArticleRow(
                  article: aboutArticles[i],
                  onOpen: () => _openArticle(context, aboutArticles[i]),
                ),
                if (i < aboutArticles.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Text('© 2026 Buku Saku ATLM',
                      style: TextStyle(
                          fontSize: 12, color: kOnSurfaceVariant)),
                  SizedBox(height: 2),
                  Text('Dibuat untuk analis laboratorium',
                      style: TextStyle(
                          fontSize: 12, color: kOnSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

enum _InfoPage { terms, privacy, openSource }

class _InfoPageScreen extends StatelessWidget {
  final _InfoPage page;
  const _InfoPageScreen({required this.page});

  String get _title {
    switch (page) {
      case _InfoPage.terms:
        return 'Syarat & Ketentuan';
      case _InfoPage.privacy:
        return 'Kebijakan Privasi';
      case _InfoPage.openSource:
        return 'Lisensi Open Source';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimary)),
          backgroundColor: kBackground,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (page == _InfoPage.terms) ...[
              const _Subheading('Tujuan'),
              const SizedBox(height: 6),
              const Text(
                  'Buku Saku ATLM adalah alat bantu referensi offline untuk analis laboratorium medik dan pembelajar di bidang laboratorium medik.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Bukan pengganti SOP'),
              const SizedBox(height: 6),
              const Text(
                  'Isi aplikasi ini bukan pengganti Standar Operasional Prosedur (SOP) laboratorium, instruksi pabrikan alat dan reagen, maupun penilaian tenaga kesehatan yang kompeten. Bila ada perbedaan antara aplikasi dan SOP yang berlaku, SOP yang berlaku yang dipakai.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Offline dan gratis'),
              const SizedBox(height: 6),
              const Text(
                  'Seluruh konten tersimpan di perangkat dan dapat dipakai tanpa koneksi internet. Aplikasi ini tidak memungut biaya dan tidak menampilkan iklan.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
            ],
            if (page == _InfoPage.privacy) ...[
              const _Subheading('Ringkas'),
              const SizedBox(height: 6),
              const Text(
                  'Buku Saku ATLM tidak mengumpulkan, mengirim, atau membagikan data pengguna apa pun. Aplikasi ini tidak memakai akun, tidak memakai server, dan tidak memakai pelacak.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Data yang disimpan'),
              const SizedBox(height: 6),
              const Text(
                  'Satu-satunya yang tersimpan lokal di perangkat adalah preferensi tampilan (mode grid kategori). Tidak ada data pribadi, tidak ada riwayat baca, tidak ada bookmark.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Izin'),
              const SizedBox(height: 6),
              const Text(
                  'Aplikasi ini tidak meminta izin apa pun di perangkat (tanpa akses kamera, lokasi, kontak, atau penyimpanan).',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Menghapus aplikasi'),
              const SizedBox(height: 6),
              const Text(
                  'Karena tidak ada data yang dikumpulkan, tidak ada data yang dapat dihapus dari server — menghapus aplikasi sudah cukup.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
            ],
            if (page == _InfoPage.openSource) ...[
              const Text(
                  'Aplikasi ini dibangun di atas perangkat lunak sumber terbuka berikut, dipakai sesuai lisensinya masing-masing. Terima kasih kepada para kontributornya.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              const _Subheading('Pustaka dan ikon'),
              const SizedBox(height: 6),
              const InfoRow(
                  icon: Icons.code,
                  title: 'Flutter & Material 3',
                  description:
                      'Antarmuka aplikasi, termasuk kartu, daftar, dan navigasi.'),
              const SizedBox(height: 12),
              const InfoRow(
                  icon: Icons.code,
                  title: 'shared_preferences',
                  description: 'Preferensi tampilan grid yang tersimpan lokal.'),
              const SizedBox(height: 12),
              const InfoRow(
                  icon: Icons.code,
                  title: 'wakelock_plus',
                  description: 'Bench Mode: menjaga layar tetap menyala.'),
              const SizedBox(height: 12),
              const InfoRow(
                  icon: Icons.code,
                  title: 'package_info_plus',
                  description: 'Menampilkan nomor versi aplikasi.'),
              const SizedBox(height: 12),
              const InfoRow(
                  icon: Icons.code,
                  title: 'Health Icons (MIT)',
                  description:
                      'Ikon kategori oleh Resolve to Save Lives, lisensi MIT.'),
              const SizedBox(height: 12),
              const InfoRow(
                  icon: Icons.code,
                  title: 'Streamline Icons (CC BY 4.0)',
                  description:
                      'Ikon pot sampel feses, oleh Streamline, lisensi CC BY 4.0.'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Subjudul berpola di halaman info: memecah dinding teks supaya
/// dokumen legal mudah dipindai.
class _Subheading extends StatelessWidget {
  final String title;
  const _Subheading(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}
