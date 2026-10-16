# Ludo Lovers Mobile App

This directory is the initial Flutter application foundation for Ludo Lovers.

## Current status

- Flutter package metadata and a minimal app entry point have been added.
- The landing screen and initial Material theme use the approved brand palette.
- A canonical **provisional** board route fixture and local rules engine are implemented, with typed domain events and configurable rule profiles.
- Route tests cover 52-cell paths, per-seat entry offsets, home-lane isolation, wrap transitions, exact finish, and overshoot behavior.
- The displayed route still has four diagonal transitions and is intentionally blocked from gameplay readiness until reconciled with the approved board reference.
- The Local Game Lab tests engine transitions; the rendered board is not yet connected to a complete playable match.
- GitHub Actions runs the automated Flutter checks and uses the same constraints documented in the repository architecture notes.
- The Android platform folder is not committed yet. CI generates it temporarily and attempts a debug APK build, then uploads the APK as a short-lived artifact when successful.

## Run on a development computer

Install the Flutter stable SDK and Android toolchain, then from this directory run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Board fixture and rules boundary

The project now includes an explicit canonical route definition for classic Ludo board geometry in
`lib/features/game/domain/board/classic_ludo_board_fixture.dart`.

This fixture is intentionally separate from rendering and should be treated as the rules-model boundary for movement logic. The renderer consumes logical board state; it does not invent game rules.

## Assets

Do not replace or recreate the official Ludo Lovers logo. Confirm the actual logo asset file and license/location before adding it under `assets/branding/` and registering it in `pubspec.yaml`.

## Secrets

Never commit Supabase service-role keys, private keys, passwords, or production tokens. Client configuration must use only publishable/public project values and must still be protected by database and backend access controls.
