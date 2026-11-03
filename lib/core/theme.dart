import 'package:flutter/material.dart';

/// Colours sampled from the Get Calley Figma design.
class C {
  static const primary = Color(0xFF2563EB);
  static const navy = Color(0xFF1E3A6E);
  static const bg = Color(0xFFF8F9FB);
  static const tint = Color(0xFFEFF3FB);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFD1D5DB);
  static const pending = Color(0xFFF7A93B);
  static const pendingBg = Color(0xFFFFEEDB);
  static const done = Color(0xFF2B7FF3);
  static const doneGreen = Color(0xFF16A34A);
  static const doneBg = Color(0xFFDDF7E3);
  static const schedule = Color(0xFF8B5CF6);
  static const scheduleBg = Color(0xFFEFE8FD);
  static const whatsapp = Color(0xFF25D366);
}

ThemeData appTheme() {
  final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary));
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: C.text, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIconColor: C.muted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.border)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.primary, width: 1.4)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
