import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengatur tema manual: Sistem / Terang / Gelap.
/// Pilihan disimpan lokal (SharedPreferences) dan berlaku instan
/// tanpa perlu membuka Pengaturan.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
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
  }

  static Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode',
        m == ThemeMode.light
            ? 'light'
            : m == ThemeMode.dark
                ? 'dark'
                : 'system');
  }

  /// Alih cepat Gelap <-> Terang dari tombol di Beranda.
  /// Mengikuti apa yang sedang terlihat di layar.
  static Future<void> toggle(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    await setMode(dark ? ThemeMode.light : ThemeMode.dark);
  }
}
