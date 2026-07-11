import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 JWT를 기기에 저장·복원합니다.
class AuthSession {
  AuthSession._();

  static const _tokenKey = 'showup_user_token';

  static String? _memoryToken;

  static String? get token => _memoryToken;

  static bool get isLoggedIn =>
      _memoryToken != null && _memoryToken!.isNotEmpty;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _memoryToken = prefs.getString(_tokenKey);
  }

  static Future<void> save(String token) async {
    _memoryToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clear() async {
    _memoryToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
