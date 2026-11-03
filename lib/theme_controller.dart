import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengatur tema manual: Sistem / Terang / Gelap.
/// Pilihan disimpan lokal (SharedPreferences) dan berlaku instan
/// tanpa perlu membuka Pengaturan.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString('theme_mode')) {
        case 'light':
          mode.value = ThemeMode.light;
          break;
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        default:
          mode.value = ThemeMode.system;
      }
    } catch (_) {
      // Preferensi tampilan tidak boleh menggagalkan aplikasi dibuka:
      // lanjut dengan mode sistem.
      mode.value = ThemeMode.system;
    }
  }

  static Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'theme_mode',
          m == ThemeMode.light
              ? 'light'
              : m == ThemeMode.dark
                  ? 'dark'
                  : 'system');
    } catch (_) {
      // Penyimpanan gagal: mode di memori tetap berlaku sesi ini.
    }
  }

  /// Alih cepat Gelap <-> Terang dari tombol di Beranda.
  /// Target dihitung dari mode tersimpan (bukan brightness konteks yang
  /// bisa basi saat rebuild/transisi) — aman dari ketukan ganda cepat.
  static Future<void> toggle(BuildContext context) async {
    final current = mode.value == ThemeMode.system
        ? (Theme.of(context).brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light)
        : mode.value;
    await setMode(
        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
