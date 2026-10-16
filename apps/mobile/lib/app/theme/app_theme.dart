import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Canonical brand values. Keep these hex codes unchanged.
  static const Color orange = Color(0xFFF15206);
  static const Color green = Color(0xFF2DF732);
  static const Color blue = Color(0xFF35930F);
  static const Color magenta = Color(0xFFF42227);
  static const Color gold = Color(0xFFFF7300);
  static const Color red = Color(0xFF377530);
  static const Color black = Color(0xFF000600);
  static const Color cream = Color(0xFFF75821);

  static const Color panel = Color(0xFF15110F);
  static const Color panelRaised = Color(0xFF211713);
  static const Color mutedText = Color(0xFFB9A99F);

  static ThemeData get light {
    const scheme = ColorScheme.dark(
      primary: orange,
      onPrimary: black,
      secondary: magenta,
      onSecondary: black,
      error: red,
      onError: cream,
      surface: panel,
      onSurface: cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: black,
      canvasColor: black,
      cardColor: panel,
      dividerColor: gold.withValues(alpha: 0.35),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: cream,
            displayColor: cream,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: cream,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withValues(alpha: 0.45)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cream,
          minimumSize: const Size(48, 50),
          side: BorderSide(color: gold.withValues(alpha: 0.75)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: 0.35)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: cream),
        hintStyle: const TextStyle(color: mutedText),
      ),
    );
  }
}
