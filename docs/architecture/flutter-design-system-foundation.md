# Ludo Lovers — Flutter Design System Foundation
**Roadmap:** Step 04  
**Status:** Implementation specification and starter code  
**Visual source of truth:** User-uploaded Ludo Lovers Visual Design System reference image.  
**Important:** These are proposed starter files. They have not been compiled or tested in a Flutter environment yet. Use the existing official logo unchanged.

## Goal
Create a single source of truth for color, typography, spacing, shape, and theme so every screen follows the approved reference. Exact brand colors below must not be approximated or replaced.

## Proposed starter file layout
```
apps/mobile/lib/app/theme/
  app_colors.dart
  app_spacing.dart
  app_typography.dart
  app_theme.dart
```

## 1. app_colors.dart
```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Exact colors transcribed from the approved reference image.
  static const brandOrange = Color(0xFFFF8928);
  static const playerGreen = Color(0xFF33FF28);
  static const playerBlue = Color(0xFF289EFF);
  static const brandMagenta = Color(0xFFF428FF);
  static const brandGold = Color(0xFFFFD700);
  static const brandRed = Color(0xFFFF3830);
  static const brandBlack = Color(0xFF080B0B);
  static const brandCream = Color(0xFFFFF8E1);

  // Semantic UI roles use the approved palette as their source.
  // Contrast-specific treatments may be derived, but must not redefine the brand colors.
  static const premiumDark = brandBlack;
  static const surface = Color(0xFF111516);
  static const surfaceElevated = Color(0xFF1A2022);
  static const textPrimary = brandCream;
  static const textSecondary = Color(0xFFD6D0BE);
  static const success = playerGreen;
  static const warning = brandGold;
  static const danger = brandRed;
  static const outline = Color(0xFF66552A);
}
```

### Palette transcription note
These values are the product owner's latest explicit specification. Some hex values appear visually inconsistent with their semantic names; preserve the supplied values exactly until the owner confirms a correction.

## 2. app_spacing.dart
```dart
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}
```

## 3. app_typography.dart
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const headline = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
```

## 4. app_theme.dart
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandOrange,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ).copyWith(
      primary: AppColors.brandOrange,
      secondary: AppColors.brandMagenta,
      error: AppColors.danger,
      onPrimary: AppColors.brandBlack,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.premiumDark,
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineMedium: AppTypography.headline,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.sectionTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySmall,
        labelSmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.premiumDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.brandBlack,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

> Compatibility note: Flutter APIs evolve. Confirm the Flutter SDK version before compiling; if the installed SDK does not support `CardThemeData`, use the corresponding `CardTheme` type for that version.

## 5. Applying the theme
When the Flutter app shell is created, configure the root app with:
```dart
MaterialApp(
  theme: AppTheme.dark,
  themeMode: ThemeMode.dark,
  home: const AppHomeScreen(),
);
```
This is an example of how the theme is connected, not a complete runnable app by itself. `AppHomeScreen` must be implemented separately.

## 6. Reusable widgets to build next
- `PrimaryButton`: gold/orange premium treatment with loading, disabled, and pressed states.
- `SecondaryButton`: outlined/quiet action on dark surface.
- `AppCard`: consistent dark surface, restrained gold-toned border, and padding.
- `StatusChip`: icon + label for Online, In Game, DND, Offline, Reconnecting, Verified.
- `PlayerAvatar`: avatar with optional frame and semantic label.
- `CoinBalance`: virtual-only coin count; never represents cash value.
- `LoadingView` and `ErrorView`: consistent loading and recovery UI.

Keep tap targets at least 48 logical pixels where practical. Avoid color-only status communication and validate text contrast on physical Android devices.

## 7. Implementation rules
1. UI widgets consume theme tokens instead of hardcoding colors and spacing.
2. The eight approved hex codes are fixed and must match the uploaded reference exactly.
3. Keep game rules and network calls out of presentation widgets.
4. Do not add backend secrets or service-role keys to Flutter assets/config.
5. Keep the official logo as a fixed asset and reference it from the branding assets directory when its actual file is available.
6. Add widget tests for shared components and theme behavior.
7. Use Flutter/Material components for app chrome; use Flame for the interactive board renderer.
8. Run formatter, analyzer, and tests in a real Flutter environment before treating this as implemented.

## 8. Acceptance checklist
- [ ] Design tokens exist in the planned Flutter files.
- [ ] Brand colors match all eight approved hex values exactly.
- [ ] Supporting colors preserve the reference's black/gold/cream premium look.
- [ ] Buttons and inputs use shared theme styling.
- [ ] Layout remains usable with text scaling and small screens.
- [ ] Shared widgets have tests.
- [ ] App builds and passes `flutter analyze` and `flutter test` in the chosen SDK.
- [ ] Documentation is not misrepresented as a built or tested app.

## Current status
The design-system starter specification is documented here. The repository still needs the actual Flutter project and source files to be created in a development environment, then formatted, compiled, and tested.
