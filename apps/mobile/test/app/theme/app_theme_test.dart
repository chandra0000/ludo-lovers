import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/theme/app_theme.dart';

void main() {
  group('Ludo Lovers brand theme', () {
    test('preserves the approved visual-system palette', () {
      expect(AppTheme.orange, const Color(0xFFFF8928));
      expect(AppTheme.green, const Color(0xFF33FF28));
      expect(AppTheme.blue, const Color(0xFF289EFF));
      expect(AppTheme.magenta, const Color(0xFFF428FF));
      expect(AppTheme.gold, const Color(0xFFFFD700));
      expect(AppTheme.red, const Color(0xFFFF3830));
      expect(AppTheme.black, const Color(0xFF080B0B));
      expect(AppTheme.cream, const Color(0xFFFFF8E1));
    });

    test('keeps the shared theme dark with gold primary and black backdrop', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.black);
      expect(theme.colorScheme.primary, AppTheme.gold);
      expect(theme.colorScheme.error, AppTheme.red);
      expect(theme.cardTheme.color, AppTheme.panel);
    });
  });
}
