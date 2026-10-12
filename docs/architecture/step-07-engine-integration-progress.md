# Step 07 — Path-Based Engine Integration Progress

**Status:** Integration layer and initial integration-test source committed. This is not a claim that the Dart package compiles or tests pass; no Flutter/Dart test run has been performed.

## New files

- `apps/mobile/lib/features/game/domain/engine/path_based_local_game_engine.dart`
- `apps/mobile/test/features/game/domain/engine/path_based_local_game_engine_test.dart`

## What this layer now connects

The new `PathBasedLocalGameEngine` uses:
- `LudoBoardPaths` to retrieve the correct ordered route for each player.
- `LudoPathMovement` to resolve legal movement and finish state.
- Immutable-style state transitions for local roll and move actions.
- State-version checks to reject stale actions.
- Turn ownership checks.
- Capture checks against opponent pawns on non-safe cells.
- Third-consecutive-six handling and no-legal-move turn resolution.
- Events for movement, capture, finish, extra rolls, and match completion.

## Critical caveats

1. This is a new integration layer, not yet a replacement for the original `ludo_engine.dart`. The old engine still contains placeholder movement logic; do not use it as the final implementation.
2. Current test paths use a tiny synthetic 8-cell loop to test mechanics. This is not the production Ludo board. The final board route and safe cells must be defined and reviewed against the approved board design.
3. Own-pawn stacking and opponent stacking policies are not yet fully enforced in this integration layer.
4. The model currently uses simple local state and deterministic injected dice values. Online play must use server-authoritative commands and dice.
5. Some rule-profile options and multi-player placement behavior still need complete coverage.
6. Test source is committed but not executed. Confirm the package name/imports, then run formatter, analyzer, and test suite.

## Suggested verification commands

Run from the Flutter package workspace after `pubspec.yaml` and SDK are available:

```sh
dart format lib test
flutter test test/features/game/domain/board/ludo_board_paths_test.dart
flutter test test/features/game/domain/engine/ludo_path_movement_test.dart
flutter test test/features/game/domain/engine/path_based_local_game_engine_test.dart
flutter analyze
```

Adjust working directory and paths to match the actual workspace. Resolve every compile, analyzer, and test failure before connecting the engine to Flame.

## Next work

- Add full capture/safe-cell/stacking tests.
- Test home-lane entry and exact finish using the real 52-cell paths.
- Integrate or migrate the original engine API to this path-based implementation.
- Make all state collections deeply immutable.
- Define final route coordinates/cell mapping with the board design.
- Execute the tests in a real SDK environment.

## Brand consistency

The engine remains visual-style agnostic. The future board UI must use the exact approved palette `#FF8928`, `#33FF28`, `#289EFF`, `#F428FF`, `#FFD700`, `#FF3830`, `#080B0B`, and `#FFF8E1`. Preserve the existing official Ludo Lovers logo.
