import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Locked product-owner palette. Never replace these base hex values.
  static const Color orange = Color(0xFFFF8928);
  static const Color green = Color(0xFF33FF28);
  static const Color blue = Color(0xFF289EFF);
  static const Color magenta = Color(0xFFF428FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color red = Color(0xFFFF3830);
  static const Color black = Color(0xFF080B0B);
  static const Color cream = Color(0xFFFFF8E1);

  // Keep readable copy tied to the approved Cream token.
  static const Color readableText = cream;
  static const Color mutedText = Color(0xFFB9A99F);
  static const Color panel = Color(0xFF15110F);
  static const Color panelRaised = Color(0xFF211713);
  static const Color panelHighlight = Color(0xFF2B1B14);

  static ThemeData get light {
    const scheme = ColorScheme.dark(
      primary: gold,
      onPrimary: black,
      secondary: magenta,
      onSecondary: readableText,
      tertiary: orange,
      onTertiary: readableText,
      error: red,
      onError: readableText,
      surface: panel,
      onSurface: readableText,
      outline: gold,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: black,
      canvasColor: black,
      cardColor: panel,
      dividerColor: gold.withValues(alpha: 0.30),
      splashColor: gold.withValues(alpha: 0.12),
      highlightColor: gold.withValues(alpha: 0.06),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: readableText,
        displayColor: readableText,
      ).copyWith(
        headlineMedium: ThemeData.dark().textTheme.headlineMedium?.copyWith(
          color: readableText,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
        titleLarge: ThemeData.dark().textTheme.titleLarge?.copyWith(
          color: readableText,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: ThemeData.dark().textTheme.bodyMedium?.copyWith(
          color: readableText,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: readableText,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withValues(alpha: 0.38)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          disabledBackgroundColor: panelHighlight,
          disabledForegroundColor: mutedText,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          foregroundColor: readableText,
          minimumSize: const Size(48, 50),
          side: BorderSide(color: gold.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: readableText,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: 0.30)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: readableText),
        hintStyle: const TextStyle(color: mutedText),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelHighlight,
        contentTextStyle: const TextStyle(color: readableText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
