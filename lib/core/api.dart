import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Thin client for the Calley mock REST API.
class Api {
  static const baseUrl = 'https://mock-api.calleyacd.com';
  static const _timeout = Duration(seconds: 20);

  static Map<String, String> get _headers => {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> _handle(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? {} : jsonDecode(res.body);
    } catch (_) {
      body = {'message': res.body};
    }
    final map = body is Map<String, dynamic> ? body : {'data': body};
    if (res.statusCode >= 200 && res.statusCode < 300) return Future.value(map);
    throw ApiException(
        (map['message'] ?? map['error'] ?? 'Request failed (${res.statusCode})').toString());
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(data))
          .timeout(_timeout);
      return await _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Check your connection.');
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout);
      return await _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Check your connection.');
    }
  }

  static Future<Map<String, dynamic>> register(
          {required String username, required String email, required String password}) =>
      _post('/api/auth/register', {'username': username, 'email': email, 'password': password});

  static Future<Map<String, dynamic>> sendOtp(String email) =>
      _post('/api/auth/send-otp', {'email': email});

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) =>
      _post('/api/auth/verify-otp', {'email': email, 'otp': otp});

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/api/auth/login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> lists(String userId) =>
      _get('/api/list?userId=${Uri.encodeQueryComponent(userId)}');

  static Future<Map<String, dynamic>> listDetail(String listId) => _get('/api/list/$listId');
}

/// Pulls the first list-like value out of a loosely shaped response.
List<Map<String, dynamic>> extractList(Map<String, dynamic> json) {
  for (final k in ['lists', 'data', 'calls', 'items', 'list', 'contacts']) {
    final v = json[k];
    if (v is List) return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (v is Map) {
      final inner = extractList(Map<String, dynamic>.from(v));
      if (inner.isNotEmpty) return inner;
    }
  }
  return [];
}

String pick(Map<String, dynamic> m, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

int pickInt(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is num) return v.toInt();
    if (v is String && int.tryParse(v) != null) return int.parse(v);
    if (v is List) return v.length;
  }
  return 0;
}
