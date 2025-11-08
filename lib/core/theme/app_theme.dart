import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6C63FF),
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    cardColor: const Color(0xFF16213E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFF6B9D),
      tertiary: Color(0xFF4ECDC4),
      surface: Color(0xFF16213E),
      error: Color(0xFFFF4757),
    ),
  );
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6C63FF),
    scaffoldBackgroundColor: const Color(0xFFF7F7F7),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFF6B9D),
      tertiary: Color(0xFF4ECDC4),
      surface: Colors.white,
      error: Color(0xFFFF4757),
    ),
  );
}
