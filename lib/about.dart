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
        // lengkap tampil di baris Versi Aplikasi + halaman Tentang.
        setState(() {
          _versionText =
              'Versi ${info.version.split('.').take(2).join('.')}';
          _fullVersionText =
              'Versi ${info.version} (build ${info.buildNumber})';
        });
      }
    });
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
          title: Text('Pengaturan',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel(title: 'Umum'),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.lightbulb,
                  title: 'Fitur',
                  onTap: () => _openFeatures(context)),
              const SizedBox(height: 20),
              const _SectionLabel(title: 'Data & Privasi'),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.gavel,
                  title: 'Syarat & Ketentuan',
                  onTap: () => _openInfo(context, _InfoPage.terms)),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.policy,
                  title: 'Kebijakan Privasi',
                  onTap: () => _openInfo(context, _InfoPage.privacy)),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.medical_services,
                  title: 'Disclaimer Medis',
                  onTap: () => _openDisclaimer(context)),
              const SizedBox(height: 20),
              const _SectionLabel(title: 'Informasi'),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.info,
                  title: 'Tentang Aplikasi',
                  onTap: () => _openAboutApp(context)),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.code,
                  title: 'Lisensi Open Source',
                  onTap: () => _openInfo(context, _InfoPage.openSource)),
              const SizedBox(height: 12),
              _SettingsRow(
                  icon: Icons.smartphone,
                  title: 'Versi Aplikasi',
                  subtitle: _fullVersionText),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris pengaturan ala SakuMedis: ikon dalam kotak biru muda + judul +
/// panah (kecuali baris info seperti versi).
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsRow(
      {required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
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
                          style: TextStyle(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label grup ala SakuMedis: ikon + teks biru.
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      ],
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
          title: Text('Fitur',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          title: Text('Disclaimer Medis',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode(context) ? kWarningContainerDark : kWarningContainer,
            border: Border.all(color: kWarningBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Penting untuk pengguna',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: isDarkMode(context) ? kOnWarningDark : kOnWarning)),
              const SizedBox(height: 4),
              Text(
                  'Aplikasi ini adalah alat bantu referensi, bukan pengganti SOP laboratorium dan penilaian tenaga kompeten.',
                  style: TextStyle(color: isDarkMode(context) ? kOnWarningDark : kOnWarning)),
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
          title: Text('Tentang Aplikasi',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              elevation: 2,
              color: Theme.of(context).colorScheme.surface,
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
                    Text('Referensi cepat analis laboratorium',
                        style: TextStyle(
                            fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(versionText,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(height: 6),
                    Text(fullVersionText,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              elevation: 2,
              color: Theme.of(context).colorScheme.surface,
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
                    Text('Analis Teknologi Laboratorium Medik',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                            color: kAmber,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    Text('Buku saku untuk analis laboratorium',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
            Center(
              child: Column(
                children: [
                  Text('© 2026 Buku Saku ATLM',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('Dibuat untuk analis laboratorium',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (page == _InfoPage.terms) ...[
              const Text(
                  'Buku Saku ATLM adalah alat bantu referensi offline untuk analis laboratorium medik dan pembelajar di bidang laboratorium medik.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                  'Isi aplikasi ini bukan pengganti Standar Operasional Prosedur (SOP) laboratorium, instruksi pabrikan alat dan reagen, maupun penilaian tenaga kesehatan yang kompeten. Bila ada perbedaan antara aplikasi dan SOP yang berlaku, SOP yang berlaku yang dipakai.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                  'Seluruh konten tersimpan di perangkat dan dapat dipakai tanpa koneksi internet. Aplikasi ini tidak memungut biaya dan tidak menampilkan iklan.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
            ],
            if (page == _InfoPage.privacy) ...[
              const Text(
                  'Buku Saku ATLM tidak mengumpulkan, mengirim, atau membagikan data pengguna apa pun. Aplikasi ini tidak memakai akun, tidak memakai server, dan tidak memakai pelacak.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                  'Satu-satunya yang tersimpan lokal di perangkat adalah preferensi tampilan (mode grid kategori). Tidak ada data pribadi, tidak ada riwayat baca, tidak ada bookmark.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                  'Aplikasi ini tidak meminta izin apa pun di perangkat (tanpa akses kamera, lokasi, kontak, atau penyimpanan).',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
              const Text(
                  'Karena tidak ada data yang dikumpulkan, tidak ada data yang dapat dihapus dari server — menghapus aplikasi sudah cukup.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
            ],
            if (page == _InfoPage.openSource) ...[
              const Text(
                  'Aplikasi ini dibangun di atas perangkat lunak sumber terbuka berikut, dipakai sesuai lisensinya masing-masing. Terima kasih kepada para kontributornya.',
                  style: TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 12),
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
