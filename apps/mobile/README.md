# Ludo Lovers Mobile App

This directory is the initial Flutter application foundation for Ludo Lovers.

## Current status

- Flutter package metadata and a minimal app entry point have been added.
- The landing screen and initial Material theme use the approved brand palette.
- Game engine source is still a separate development slice and has not been integrated into this screen.
- This foundation has **not yet been compiled, analyzed, or tested** in a Flutter SDK.

## Run on a development computer

Install the Flutter stable SDK and Android toolchain, then from this directory run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The GitHub Actions workflow at `.github/workflows/flutter-checks.yml` runs analysis and tests in a cloud runner when commits are pushed.

## Assets

Do not replace or recreate the official Ludo Lovers logo. Confirm the actual logo asset file and license/location before adding it under `assets/branding/` and registering it in `pubspec.yaml`.

## Secrets

Never commit Supabase service-role keys, private keys, passwords, or production tokens. Client configuration must use only publishable/public project values and must still be protected by database RLS and server-side authorization.
