// CONTOH main.dart — gabungkan dengan main.dart kamu yang sekarang.
// Intinya: (1) ThemeController.load() sebelum runApp,
//          (2) MaterialApp dibungkus ValueListenableBuilder + theme/darkTheme/themeMode.
import 'package:absensiujk/project_absensi/views/auth/login_screen.dart';
import 'package:flutter/material.dart';

import 'package:absensiujk/project_absensi/reusable/app_theme.dart';
// import halaman splash (logo pembuka)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load(); // baca pilihan tema yang tersimpan
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const LoginScreen(),
        );
      },
    );
  }
}
