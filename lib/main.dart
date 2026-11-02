import 'package:flutter/material.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.init();
  runApp(const CalleyApp());
}

class CalleyApp extends StatelessWidget {
  const CalleyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final Widget home = Session.user != null
        ? const DashboardScreen()
        : (Session.hasLanguage ? const LoginScreen() : const LanguageScreen());
    return MaterialApp(
      title: 'Calley',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: home,
    );
  }
}
