import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        primary: const Color(0xFF1565C0),
        secondary: const Color(0xFFFFA000),
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111111),
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          height: 1.45,
          color: Color(0xFF222222),
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          height: 1.4,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}
