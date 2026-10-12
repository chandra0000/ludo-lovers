# Step 07 — Path-Based Pawn Movement Update

**Status:** A separate path-based movement resolver and test source have been committed. They are not yet integrated into `LudoEngine`; the full engine remains unfinished. Tests have not been executed in a Dart/Flutter environment.

## Added source

- `apps/mobile/lib/features/game/domain/engine/ludo_path_movement.dart`
- `apps/mobile/test/features/game/domain/engine/ludo_path_movement_test.dart`

## What the resolver covers

- Rejects dice values outside 1–6.
- Requires a six to leave the yard when configured.
- Enters at the player's route entry cell.
- Advances using player-relative progress, then resolves the destination through that player's ordered path.
- Transitions from the shared track into the player's private home lane.
- Supports exact finish and overshoot rejection.
- Rejects moves for already-finished pawns.
- Returns a typed resolution/failure rather than mutating a game state.

The resolver is intentionally small and pure. Captures, safe cells, stacking, bonus rolls, turn rotation, and win detection remain responsibilities of the game engine and must be integrated/tested separately.

## Important integration requirements

1. Add player-relative route progress to the canonical pawn state. Do not derive progress only from a global board cell.
2. Have `LudoEngine` call `LudoPathMovement` for every pawn move.
3. Ensure the game state is immutable and a rejected action never partially changes it.
4. Define and review the final board's ordered paths before using this in a real game. The tests use a small synthetic route to validate logic; they are not the final 52-cell production board geometry.
5. Reconcile the movement resolver with all configured rule-profile options, especially non-exact finish behavior and bonus-roll semantics.
6. Add capture, safe-cell, own-pawn stacking, consecutive-six, no-legal-move, and winner tests.
7. Confirm the package name in `pubspec.yaml`, then run formatter, analyzer, and all tests in a real Flutter SDK.

## Commands to run when the Flutter project is available

```sh
dart format apps/mobile/lib/features/game/domain/board/ludo_board_paths.dart apps/mobile/lib/features/game/domain/engine/ludo_path_movement.dart apps/mobile/test/features/game/domain/board/ludo_board_paths_test.dart apps/mobile/test/features/game/domain/engine/ludo_path_movement_test.dart
flutter test apps/mobile/test/features/game/domain/board/ludo_board_paths_test.dart
flutter test apps/mobile/test/features/game/domain/engine/ludo_path_movement_test.dart
flutter analyze
```

Run these from the Flutter package directory or adjust paths to match the workspace layout. The package metadata must exist first.

## Do not mark Step 07 complete yet

The files are committed, but there is no claim that the app compiles, tests pass, or online gameplay is ready. Complete integration and execute the test suite before proceeding to the visual board as a working feature.
