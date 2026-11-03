import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';
import 'demo_data.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Thrown internally when the server can't be reached or isn't serving the API.
class _ServerDown implements Exception {}

/// Client for the Calley mock REST API.
///
/// When the live server is unreachable (it currently serves a mismatched TLS
/// certificate and 404s for every route), calls fall back to the example
/// responses from the official Postman collection and [Api.demoMode] is set,
/// so the UI can show a "demo data" banner.
class Api {
  static const host = 'mock-api.calleyacd.com';
  static const baseUrl = 'https://$host';
  static const _timeout = Duration(seconds: 15);
  static bool demoMode = false;

  // The server's certificate is issued for a different hostname. Accept it
  // for this one API host only; every other host keeps normal TLS checks.
  static http.Client _client = IOClient(
    HttpClient()..badCertificateCallback = (cert, h, port) => h == host,
  );

  /// Lets tests substitute a fake HTTP client.
  @visibleForTesting
  static set client(http.Client c) => _client = c;

  static Map<String, String> get _headers => {'Content-Type': 'application/json'};

  static Map<String, dynamic> _handle(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    // An HTML 404 means the hosting panel answered, not the API.
    if (res.statusCode == 404 && !ct.contains('json')) throw _ServerDown();
    if (res.statusCode >= 500) throw _ServerDown();
    dynamic body;
    try {
      body = res.body.isEmpty ? {} : jsonDecode(res.body);
    } catch (_) {
      throw _ServerDown();
    }
    final map = body is Map<String, dynamic> ? body : <String, dynamic>{'data': body};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      demoMode = false;
      return map;
    }
    throw ApiException((map['message'] ?? map['error'] ?? 'Request failed (${res.statusCode})').toString());
  }

  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call, Map<String, dynamic> Function() demo) async {
    try {
      return _handle(await call().timeout(_timeout));
    } on ApiException {
      rethrow;
    } catch (_) {
      // SocketException, HandshakeException, timeout, or _ServerDown.
      demoMode = true;
      return demo();
    }
  }

  static Future<Map<String, dynamic>> _post(
          String path, Map<String, dynamic> data, Map<String, dynamic> Function() demo) =>
      _send(() => _client.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(data)), demo);

  static Future<Map<String, dynamic>> _get(String path, Map<String, dynamic> Function() demo) =>
      _send(() => _client.get(Uri.parse('$baseUrl$path'), headers: _headers), demo);

  static Future<Map<String, dynamic>> register(
          {required String username, required String email, required String password}) =>
      _post('/api/auth/register', {'username': username, 'email': email, 'password': password},
          () => {'message': 'User registered'});

  static Future<Map<String, dynamic>> sendOtp(String email) =>
      _post('/api/auth/send-otp', {'email': email}, () => {'message': 'OTP sent'});

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) =>
      _post('/api/auth/verify-otp', {'email': email, 'otp': otp}, () => {'message': 'OTP Verified'});

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/api/auth/login', {'email': email, 'password': password}, () => {
            'message': 'Login successful',
            'user': {
              '_id': demoListResponse['clientId'],
              'username': email.split('@').first,
              'email': email,
            }
          });

  static Future<Map<String, dynamic>> lists(String userId) =>
      _get('/api/list?userId=${Uri.encodeQueryComponent(userId)}', () => demoListResponse);

  static Future<Map<String, dynamic>> listDetail(String listId) =>
      _get('/api/list/$listId', () => demoListDetailResponse);
}

/// Returns the list items in a response. `GET /api/list` returns a single
/// list object, so an object with an `_id` is treated as a one-item list.
List<Map<String, dynamic>> extractList(Map<String, dynamic> json) {
  for (final k in ['lists', 'data', 'calls', 'items', 'list', 'contacts']) {
    final v = json[k];
    if (v is List) return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (v is Map) {
      final inner = extractList(Map<String, dynamic>.from(v));
      if (inner.isNotEmpty) return inner;
    }
  }
  if (json.containsKey('_id') && json.containsKey('name')) return [json];
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
