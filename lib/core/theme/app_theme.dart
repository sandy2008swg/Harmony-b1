import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1DB954),
      secondary: Color(0xFF1DB954),
      surface: Color(0xFF181818),
    ),

    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF181818),
    ),
  );
}