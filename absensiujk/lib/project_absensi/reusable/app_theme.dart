import 'package:flutter/material.dart';

import 'theme_controller.dart';

export 'theme_controller.dart';

/// Warna yang otomatis menyesuaikan mode terang / gelap.
/// Dipakai di semua layar menggantikan Color(0xFF...) yang di-hardcode.
class AppPalette {
  static bool get _dark => ThemeController.isDarkMode.value;

  static Color get bg => _dark ? const Color(0xFF1A1216) : const Color(0xFFFFF7FA);
  static Color get card => _dark ? const Color(0xFF2A1D24) : const Color(0xFFFFEAF1);
  static Color get card2 => _dark ? const Color(0xFF33242D) : const Color(0xFFFFF1F5);
  static Color get field => _dark ? const Color(0xFF3A2A33) : Colors.white;
  static Color get chip => _dark ? const Color(0xFF3D2A34) : const Color(0xFFFFDCE8);
  static Color get divider => _dark ? const Color(0xFF6B4A58) : const Color(0xFFB98B9B);

  static Color get textPrimary => _dark ? const Color(0xFFFBE8F0) : const Color(0xFF54283A);
  static Color get textSecondary => _dark ? const Color(0xFFC9A3B3) : const Color(0xFF9E7180);
  static Color get hint => _dark ? const Color(0xFFB58DA0) : const Color(0xFF8A5268);

  static Color get accent => const Color(0xFFE89AB7);
  static Color get accentLight => _dark ? const Color(0xFFF08CB0) : const Color(0xFFD96F96);
  static Color get accentDeep => const Color(0xFFC85A82);
  static Color get snack => const Color(0xFFE58BA6);
  static Color get soft => const Color(0xFFF3A6BD);
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF1A1216) : const Color(0xFFFFF7FA);
    final card = dark ? const Color(0xFF2A1D24) : const Color(0xFFFFEAF1);
    final text = dark ? const Color(0xFFFBE8F0) : const Color(0xFF54283A);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE89AB7),
        brightness: b,
      ).copyWith(surface: card),
      cardColor: card,
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        titleTextStyle: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800),
        contentTextStyle: TextStyle(color: text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: ThemeData(brightness: b).textTheme.apply(
            bodyColor: text,
            displayColor: text,
          ),
    );
  }
}
