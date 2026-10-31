import 'package:flutter/material.dart';
import 'category_icons.dart';
import 'models.dart';

const kPrimary = Color(0xFF0B63E5);
const kPrimaryContainer = Color(0xFFDCE8FD);
const kOnPrimaryContainer = Color(0xFF001A3D);
const kBackground = Color(0xFFF6F8FC);
const kOnSurface = Color(0xFF121C1D);
const kOnSurfaceVariant = Color(0xFF44546B);
const kOutlineVariant = Color(0xFFC6D2E0);
const kSurfaceVariant = Color(0xFFE3E8F0);
const kAmber = Color(0xFFFFB951);
const kWarningContainer = Color(0xFFFFF3D6);
const kWarningBorder = Color(0xFFE8A838);
const kOnWarning = Color(0xFF5C3A00);
const kCriticalContainer = Color(0xFFFDECEA);
const kCriticalBorder = Color(0xFFE57373);

// Palet gelap (tema gelap mengikuti sistem; nilai tema terang di atas
// tidak berubah). Latar gelap #0E1415 mengikuti dokumen review desain.
const kBackgroundDark = Color(0xFF0E1415);
const kSurfaceDark = Color(0xFF1C2526);
const kSurfaceVariantDark = Color(0xFF243235);
const kOutlineVariantDark = Color(0xFF3A4A4F);
const kOnSurfaceDark = Color(0xFFE6ECEC);
const kOnSurfaceVariantDark = Color(0xFF9FB0B5);
const kPrimaryDark = Color(0xFF8AB4F8);
const kOnPrimaryDark = Color(0xFF10243E);
const kPrimaryContainerDark = Color(0xFF1E3A5F);
const kOnPrimaryContainerDark = Color(0xFFD6E4FF);
const kCriticalContainerDark = Color(0xFF3B1E1C);
const kCriticalTextDark = Color(0xFFFF8A80);
const kWarningContainerDark = Color(0xFF3A2C08);
const kOnWarningDark = Color(0xFFFFD98A);

/// True bila tema aktif gelap (mengikuti sistem Android).
bool isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Warna kategori. Ikonnya bukan lagi IconData: lihat categoryIcon()
/// di category_icons.dart (6 kategori memakai gambar CustomPaint).
class CategoryStyle {
  final Color color;
  const CategoryStyle(this.color);
}

CategoryStyle categoryStyle(String category) {
  switch (category) {
    case 'HEMATOLOGI':
      return const CategoryStyle(Color(0xFFD32F2F));
    case 'HEMOSTASIS':
      return const CategoryStyle(Color(0xFF7B1FA2));
    case 'PARASITOLOGI':
      return const CategoryStyle(Color(0xFFEF6C00));
    case 'KIMIA KLINIK':
      return const CategoryStyle(Color(0xFF1565C0));
    case 'URINALISA':
      return const CategoryStyle(Color(0xFF00838F));
    case 'FAECES':
      return const CategoryStyle(Color(0xFF795548));
    case 'MIKROBIOLOGI':
      return const CategoryStyle(Color(0xFF2E7D32));
    case 'IMUNOSEROLOGI':
      return const CategoryStyle(Color(0xFF6A1B9A));
    default:
      return const CategoryStyle(Color(0xFF607D8B));
  }
}

/// Logo mikroskop: lingkaran biru cerah + ikon putih.
class LabLogo extends StatelessWidget {
  final double size;
  const LabLogo(this.size, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo laboratorium',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.biotech, color: Theme.of(context).colorScheme.surface, size: size * 0.55),
      ),
    );
  }
}

/// Header seksi berkelompok ala SakuMedis: ikon kotak kecil + judul tebal.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({required this.title, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(Icons.category, color: Theme.of(context).colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Baris info ala SakuMedis: ikon kotak pastel + judul + deskripsi + panah.
///
/// [icon] untuk pemakaian lama (halaman Tentang). [iconChild] bila ikon
/// berupa widget (ikon kategori custom): bila diisi, ia dipakai dan
/// [icon] diabaikan. Mode daftar kategori memakai iconChild dengan warna
/// kPrimary, sama seperti sebelumnya.
class InfoRow extends StatelessWidget {
  final IconData? icon;
  final Widget? iconChild;
  final String title;
  final String description;
  final VoidCallback? onTap;
  const InfoRow(
      {this.icon,
      this.iconChild,
      required this.title,
      required this.description,
      this.onTap,
      super.key});

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconChild ??
                    Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(description,
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

/// Baris kartu artikel: ikon kotak pastel kategori + judul + subjudul
/// kata kunci + panah kanan. Tanpa bookmark, sesuai perintah pengguna.
class ArticleRow extends StatelessWidget {
  final Article article;
  final VoidCallback onOpen;
  final bool showCategory;
  const ArticleRow(
      {required this.article, required this.onOpen, this.showCategory = false, super.key});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(article.category);
    final subtitle = article.keywords;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: categoryIcon(article.category, 26, style.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCategory) ...[
                      Text(article.category,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                    ],
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu kategori grid: ikon besar + judul.
class CategoryCard extends StatelessWidget {
  final String category;
  final int mode; // 2 = 2 kolom, 3 = 3 kolom, 1 = daftar
  final VoidCallback onTap;
  const CategoryCard(
      {required this.category,
      required this.mode,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    if (mode == 1) {
      return InfoRow(
          iconChild: categoryIcon(category, 24, kPrimary),
          title: category,
          description: '',
          onTap: onTap);
    }
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: categoryIcon(
                    category, mode == 3 ? 28 : 36, style.color),
              ),
              const SizedBox(height: 8),
              // Mode 3 kolom: kartu sempit (~101px di layar 360px) sehingga
              // label satu kata yang panjang putus di tengah kata
              // ("IMUNOSERO / LOGI"). FittedBox scaleDown mengecilkan
              // label HANYA bila tidak muat, jadi satu baris utuh; label
              // pendek tetap 14px seperti sebelumnya. Label ber-spasi
              // (KIMIA KLINIK) sudah putus rapi di spasi, jadi tetap
              // memakai Text 2 baris biasa. Mode 2 kolom cukup lebar
              // sehingga tidak diubah.
              if (mode == 3 && !category.contains(' '))
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(category,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1),
                )
              else
                Text(category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
