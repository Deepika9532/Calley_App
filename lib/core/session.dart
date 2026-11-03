import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static late SharedPreferences _p;
  static Map<String, dynamic>? user;
  static String language = 'English';

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    language = _p.getString('lang') ?? 'English';
    final u = _p.getString('user');
    if (u != null) user = Map<String, dynamic>.from(jsonDecode(u));
  }

  static bool get hasLanguage => _p.containsKey('lang');

  static Future<void> setLanguage(String l) async {
    language = l;
    await _p.setString('lang', l);
  }

  static Future<void> saveUser(Map<String, dynamic> u) async {
    user = u;
    await _p.setString('user', jsonEncode(u));
  }

  static Future<void> logout() async {
    user = null;
    await _p.remove('user');
    await _p.remove('listId');
  }

  /// Phone entered at registration, remembered per email (the API doesn't store it).
  static Future<void> savePhone(String email, String phone) => _p.setString('phone:$email', phone);
  static String get phone => _p.getString('phone:$email') ?? '';

  /// Calling list chosen on the Settings screen.
  static String? get selectedListId => _p.getString('listId');
  static Future<void> selectList(String id) => _p.setString('listId', id);

  static String get userId => (user?['_id'] ?? user?['id'] ?? user?['userId'] ?? '').toString();
  static String get name => (user?['username'] ?? user?['name'] ?? 'Calley User').toString();
  static String get email => (user?['email'] ?? '').toString();
}
