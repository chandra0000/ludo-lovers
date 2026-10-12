# Ludo Lovers Mobile App

This directory is the initial Flutter application foundation for Ludo Lovers.

## Current status

- Flutter package metadata and a minimal app entry point have been added.
- The landing screen and initial Material theme use the approved brand palette.
- Game engine source is still a separate development slice and has not been integrated into this screen.
- GitHub Actions has successfully run `flutter analyze` and the automated tests (29 tests passed in run [38218035209](https://github.com/chandra0000/ludo-lovers/actions/runs/38218035209)); later hardening tests are covered by subsequent CI runs.
- The Android platform folder is not committed yet. CI now generates it temporarily and attempts a debug APK build, then uploads the APK as a short-lived artifact when successful.

## Run on a development computer

Install the Flutter stable SDK and Android toolchain, then from this directory run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The GitHub Actions workflow at `.github/workflows/flutter-checks.yml` generates the Android platform files in its runner, resolves dependencies, runs `flutter analyze` and `flutter test`, and builds a debug APK. If the build succeeds, download the `ludo-lovers-debug-apk` artifact from the workflow run page. The generated Android files currently exist only in CI and are not committed into this repository.

## Assets

Do not replace or recreate the official Ludo Lovers logo. Confirm the actual logo asset file and license/location before adding it under `assets/branding/` and registering it in `pubspec.yaml`.

## Secrets

Never commit Supabase service-role keys, private keys, passwords, or production tokens. Client configuration must use only publishable/public project values and must still be protected by database RLS and server-side authorization.
