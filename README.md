# ATLM Pocket Guide

Buku saku ATLM yang didigitalkan untuk Android, ditulis dengan Flutter.
Disusun oleh Muhammad Krisnadi Wibowo.

Aplikasi ini memuat 72 artikel referensi laboratorium dalam 8 kategori
(Hematologi, Hemostasis, Parasitologi, Kimia Klinik, Urinalisa, Faeces,
Mikrobiologi, Imunoserologi). Seluruh artikel dan pencarian tersimpan
lokal di perangkat; aplikasi tidak memakai login, backend, sinkronisasi,
cloud, AI API, iklan, maupun donasi.

Fitur:
- Pencarian artikel lokal
- Detail artikel bertab Materi / Bukti / Sumber
- Rumus ditampilkan sebagai gambar (tetap terbaca tanpa koneksi)
- Bench Mode: layar tetap menyala selama dipakai di meja kerja
- Kartu "Catatan penting" di akhir artikel (tertutup secara default)

## Build

Build release lewat GitHub Actions: setiap push ke `main` yang menyentuh
`pubspec.yaml`, `lib/`, `assets/`, atau `android/` menjalankan
`.github/workflows/flutter-build.yml` (pub get, analyze, build APK
release) dan mengunggah APK sebagai artifact `atlm-flutter-apk`.

Build lokal (Flutter SDK + Android SDK sudah terpasang):

```sh
flutter pub get
flutter analyze
flutter build apk --release
```

## Struktur

- `lib/` — kode aplikasi (Beranda, kategori, detail artikel, ikon kategori)
- `assets/articles.json` — data artikel (72 artikel, 8 kategori)
- `assets/formulas/` — gambar rumus (PNG, dibundel agar tetap offline)
- `android/` — konfigurasi Android (package `id.atlm.pocketguide`)
- `.github/workflows/flutter-build.yml` — build APK release di Actions

## Kredit ikon

Ikon kategori memakai Health Icons (Resolve to Save Lives, lisensi MIT)
dan satu ikon Streamline (pot sampel feses, lisensi CC BY 4.0).
