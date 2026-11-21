import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF100D12);
  static const surface = Color(0xFF1D171F);
  static const burgundy = Color(0xFF781F3B);
  static const gold = Color(0xFFD6B36A);
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: gold, secondary: burgundy, surface: surface),
    appBarTheme: const AppBarTheme(backgroundColor: background, foregroundColor: Colors.white, elevation: 0),
    useMaterial3: true,
  );
}
