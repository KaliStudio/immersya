// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF0D1B2A),
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B263B),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1B263B),
      selectedItemColor: Color(0xFFE0E1DD),
      unselectedItemColor: Color(0xFF778DA9),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF415A77),
      foregroundColor: Color(0xFFE0E1DD),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF415A77),
      secondary: Color(0xFF778DA9),
      surface: Color(0xFF1B263B),
      onPrimary: Color(0xFFE0E1DD),
      onSecondary: Color(0xFFE0E1DD),
      onSurface: Color(0xFFE0E1DD),
    ),
  );
}