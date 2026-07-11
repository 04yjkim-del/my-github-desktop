import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_session.dart';

/// Bearer 토큰·JSON fetch 래퍼.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) {
    return _request('GET', path, auth: auth, query: query);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) {
    return _request('POST', path, auth: auth, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) {
    return _request('PATCH', path, auth: auth, body: body);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) {
    return _request('DELETE', path, auth: auth, body: body);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required bool auth,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && AuthSession.isLoggedIn) {
      headers['Authorization'] = 'Bearer ${AuthSession.token}';
    }

    try {
      final response = await _send(method, uri, headers, body);
      final decoded = _decodeBody(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final error = decoded['error'];
      throw ApiException(
        error is Map ? (error['message'] as String? ?? '요청에 실패했습니다') : '요청에 실패했습니다',
        code: error is Map ? error['code'] as String? : null,
        status: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'API 서버에 연결할 수 없습니다. showup-server(localhost:3000)를 켜 주세요.',
        code: 'network_error',
        status: 0,
      );
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized').replace(queryParameters: query);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: encoded);
      default:
        throw ApiException('지원하지 않는 HTTP 메서드입니다: $method');
    }
  }

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'data': decoded};
  }
}
