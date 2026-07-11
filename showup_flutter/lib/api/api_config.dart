/// API 서버 주소 설정.
/// 개발: showup-server `http://localhost:3000`
/// 운영: `https://api.showup.me`
class ApiConfig {
  static const String prodBaseUrl = 'https://api.showup.me';
  static const String devBaseUrl = 'http://localhost:3000';

  /// Chrome 웹에서 로컬 서버 테스트 시 기본값.
  static String baseUrl = devBaseUrl;

  static void useProduction() => baseUrl = prodBaseUrl;

  static void useDevelopment([String? url]) => baseUrl = url ?? devBaseUrl;
}
