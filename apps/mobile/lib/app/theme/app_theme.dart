import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color orange = Color(0xFFFF8928);
  static const Color green = Color(0xFF33FF28);
  static const Color blue = Color(0xFF289EFF);
  static const Color magenta = Color(0xFFF428FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color red = Color(0xFFFF3830);
  static const Color black = Color(0xFF080B0B);
  static const Color cream = Color(0xFFFFF8E1);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
      primary: orange,
      secondary: magenta,
      surface: const Color(0xFF17191B),
      error: red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: black,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: cream,
            displayColor: cream,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: cream,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: black,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
