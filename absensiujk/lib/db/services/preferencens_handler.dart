import 'package:shared_preferences/shared_preferences.dart';

/// Helper class untuk mengelola penyimpanan data lokal (Session/Preferences) menggunakan package SharedPreferences.
class PreferenceHandler {
  static SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences.
  /// Wajib dipanggil sekali di awal aplikasi (misalnya di main.dart) sebelum membaca/menulis data.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyIsLogin = "isLogin";
  static const String _keyUserEmail = "userEmail";
  static const String _keyAuthToken = "authToken";
  static const String _keyLoginTime = "loginTime";

  /// Menyimpan status login pengguna (true/false) ke dalam SharedPreferences.
  static Future<bool> setLogin(bool isLogin) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setBool(_keyIsLogin, isLogin);
  }

  /// Getter static untuk mengecek apakah pengguna sudah login atau belum.
  static bool get isLogin {
    return _prefs?.getBool(_keyIsLogin) ?? false;
  }

  /// Menyimpan email pengguna yang sedang login.
  static Future<bool> setUserEmail(String email) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setString(_keyUserEmail, email);
  }

  /// Mendapatkan email pengguna yang tersimpan.
  static String get userEmail {
    return _prefs?.getString(_keyUserEmail) ?? '';
  }

  /// Menyimpan token autentikasi sesi.
  static Future<bool> setAuthToken(String token) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setString(_keyAuthToken, token);
  }

  /// Mendapatkan token autentikasi yang tersimpan.
  static String get authToken {
    return _prefs?.getString(_keyAuthToken) ?? '';
  }

  /// Menyimpan waktu login.
  static Future<bool> setLoginTime(String time) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setString(_keyLoginTime, time);
  }

  /// Mendapatkan waktu login.
  static String get loginTime {
    return _prefs?.getString(_keyLoginTime) ?? '';
  }

  /// Menghapus key status login, token, dan data sesi saat logout.
  static Future<void> logOut() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLogin);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyLoginTime);
  }
}
