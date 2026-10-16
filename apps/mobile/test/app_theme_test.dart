import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/theme/app_theme.dart';

void main() {
  group('AppTheme brand palette', () {
    test('preserves the four approved brand colors', () {
      expect(AppTheme.orange, const Color(0xFFFF8928));
      expect(AppTheme.green, const Color(0xFF33FF28));
      expect(AppTheme.blue, const Color(0xFF289EFF));
      expect(AppTheme.magenta, const Color(0xFFF428FF));
    });

    test('keeps the app theme dark and readable', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.black);
      expect(theme.colorScheme.onSurface, AppTheme.readableText);
    });
  });
}
