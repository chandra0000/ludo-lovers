# Step 03.2 — Project Structure and Dependency Plan

**Status:** Planned — not yet implemented in a Flutter project.

This document defines the initial mobile-app structure and package choices for Ludo Lovers. Keep the first build small; add packages only when a feature needs them.

## 1. Initial repository layout

```text
ludo-lovers/
├── apps/
│   └── mobile/
│       ├── android/
│       ├── assets/
│       │   ├── branding/
│       │   ├── boards/
│       │   ├── pawns/
│       │   ├── dice/
│       │   ├── avatars/
│       │   ├── frames/
│       │   ├── effects/
│       │   ├── audio/
│       │   └── fonts/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   ├── router.dart
│       │   │   ├── theme/
│       │   │   └── config/
│       │   ├── core/
│       │   │   ├── constants/
│       │   │   ├── errors/
│       │   │   ├── logging/
│       │   │   ├── network/
│       │   │   ├── storage/
│       │   │   └── utils/
│       │   ├── features/
│       │   │   ├── onboarding/
│       │   │   ├── home/
│       │   │   ├── profile/
│       │   │   ├── friends/
│       │   │   ├── game/
│       │   │   ├── rooms/
│       │   │   ├── love_mode/
│       │   │   ├── customization/
│       │   │   ├── wallet/
│       │   │   ├── achievements/
│       │   │   ├── notifications/
│       │   │   ├── chat/
│       │   │   ├── safety/
│       │   │   └── settings/
│       │   └── shared/
│       │       ├── buttons/
│       │       ├── cards/
│       │       ├── dialogs/
│       │       ├── indicators/
│       │       └── widgets/
│       └── test/
├── services/
│   └── game_server/
├── supabase/
│   ├── migrations/
│   └── seed.sql
├── docs/
│   ├── architecture/
│   ├── game-rules/
│   ├── api/
│   └── product/
└── README.md
```

Directories are a plan, not a claim that these files already exist. Create feature folders only as implementation begins.

## 2. Structure inside a feature

For larger features, use clear presentation/domain/data separation:

```text
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── screens/
    ├── widgets/
    └── controllers/
```

For tiny features, do not create empty layers just to match the template.

**Dependency direction:** Presentation → Domain → Data → external services. UI widgets must not make direct database calls.

## 3. Initial Flutter packages

Add packages when needed, and select compatible stable versions during actual setup.

| Package | Purpose | When |
| --- | --- | --- |
| `flame` | Board/game rendering and game loop | When the first board is implemented |
| `go_router` | App navigation | Initial navigation setup |
| `flutter_riverpod` | App/UI state management | When screens need shared state |
| `supabase_flutter` | Auth and app data | Backend foundation phase, not the first local prototype |
| `uuid` | Client-side IDs for non-authoritative local objects/tests | As needed |
| `shared_preferences` | Small non-sensitive local preferences | Settings phase |
| `flutter_test` | Widget and unit tests | Included with Flutter tooling |
| `mocktail` | Mock dependencies in tests | When repository/controller tests are added |

Package choices are provisional. Check compatibility and current maintenance when a computer is available. Do not add WebSocket or wallet packages until their protocol and use cases are defined.

## 4. First-build dependencies

The first playable local prototype should start with Flutter's built-in libraries and tests. Add navigation/state-management packages only when the app shell needs them. Add Flame when implementing the board. Supabase and the online game server come later.

## 5. Environment and secret handling

- Commit a safe `.env.example` only if environment variables are introduced.
- Add real local environment files to `.gitignore`.
- Never put service-role keys, private keys, passwords, or production secrets in Flutter assets or Git.
- Flutter mobile applications cannot safely hide a privileged server secret; privileged operations must run on trusted backend infrastructure.
- Use Supabase's client-safe publishable/anon key only with correctly configured Row Level Security policies.

## 6. First implementation milestones

1. Create the Flutter Android app in `apps/mobile/`.
2. Confirm it launches on an Android emulator or device.
3. Add the design tokens and theme.
4. Add app routing and a placeholder Home screen.
5. Write pure Dart Ludo rules and unit tests.
6. Add Flame board rendering and pawn interactions.
7. Complete one local match before starting online multiplayer.

**Next step after this document:** Step 03.3 — define the app shell, design tokens, and navigation contract.
