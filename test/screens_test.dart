import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calley_app/core/session.dart';
import 'package:calley_app/core/theme.dart';
import 'package:calley_app/screens/register_screen.dart';
import 'package:calley_app/screens/otp_screen.dart';
import 'package:calley_app/screens/login_screen.dart';
import 'package:calley_app/screens/getting_started_screen.dart';
import 'package:calley_app/screens/app_drawer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Session.init();
    await Session.saveUser({'_id': '1', 'username': 'Swati', 'email': 'swati@cstech.in'});
  });

  final screens = <String, Widget>{
    'register': const RegisterScreen(),
    'otp': const OtpScreen(email: 'a@b.com', phone: '7676286822'),
    'login': const LoginScreen(),
    'getting started': const GettingStartedScreen(),
    'drawer': Scaffold(body: AppDrawer(onSettings: () {})),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} lays out on a 384x800 phone', (t) async {
      t.view.physicalSize = const Size(720, 1500);
      t.view.devicePixelRatio = 1.875;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: appTheme(), home: e.value));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    });
  }
}
