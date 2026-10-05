import 'package:flutter/material.dart';

import '../services/storage_services.dart';

class ThemeController {
  // Default terang. Nilai asli dimuat dari penyimpanan lewat load().
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  /// Panggil sekali di main() sebelum runApp().
  static Future<void> load() async {
    isDarkMode.value = await StorageServices.getTheme();
  }

  /// Ganti tema + simpan, supaya tetap sama saat app dibuka lagi.
  static Future<void> setDark(bool value) async {
    isDarkMode.value = value;
    await StorageServices.saveTheme(value);
  }
}
