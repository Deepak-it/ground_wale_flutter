import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF1D1D1D);
  static const Color card = Color(0x14FFFFFF);
  static const Color cardStrong = Color(0x1FFFFFFF);
  static const Color accent = Color(0xFFDDF730);
  static const Color mutedText = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: bg,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }
}
