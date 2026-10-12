# Step 07 — Board Paths and Unit-Test Foundation

**Status:** Logical path model and tests are committed. GitHub Actions run [38218035209](https://github.com/chandra0000/ludo-lovers/actions/runs/38218035209) passed all 29 tests before the latest hardening additions. New tests for route invariants are currently running in [38257113323](https://github.com/chandra0000/ludo-lovers/actions/runs/38257113323). The local game engine still requires real board geometry and UI integration before it is safe for playable gameplay.

## Added files

- `apps/mobile/lib/features/game/domain/board/ludo_board_paths.dart`
- `apps/mobile/test/features/game/domain/board/ludo_board_paths_test.dart`

## What the path model does

- Stores a player-specific ordered route around the shared main track.
- Stores that player's private home-lane cells.
- Exposes the entry cell and finish progress.
- Maps a player-relative progress value to a logical board cell.
- Checks whether a proposed movement overshoots the route.
- Validates route length, cell bounds, and duplicate main-track cells.
- The board-path collection now rejects duplicate player routes, inconsistent shared-track cell sets, unequal home-lane lengths, and home-lane cells that overlap the shared track or another player's home lane.
- Keeps logical geometry independent of Flutter widgets, Flame components, pixels, and animations.

## Important correctness boundary

The path model deliberately does not guess the final Ludo board geometry. The lists supplied to it must be created from the approved Ludo Lovers board design and independently checked against the board diagram.

The current `ludo_engine.dart` has not yet been refactored to use this route model. Its movement calculation remains a placeholder. Do not wire it to the visual board or use it for real matches until path integration and rule tests are complete.

## Test source added

The test file covers:
- Entry cell selection.
- Main-track mapping.
- Home-lane mapping.
- Progress beyond the route.
- Exact finish and overshoot examples.
- Invalid duplicate route cells.
- Player-specific path lookup.

These tests execute through the GitHub Actions Flutter workflow. The first successful run passed 29 tests; the newly added route-invariant tests still require the currently running CI result. To reproduce locally once Flutter is installed:

```sh
dart format apps/mobile/lib/features/game/domain/board/ludo_board_paths.dart apps/mobile/test/features/game/domain/board/ludo_board_paths_test.dart
flutter test apps/mobile/test/features/game/domain/board/ludo_board_paths_test.dart
flutter analyze
```

The exact package import in the test assumes the Flutter package name is `ludo_lovers`. Confirm it matches `apps/mobile/pubspec.yaml` when the Flutter app is created.

## Next engineering tasks

1. Confirm the final board layout and define four 52-cell player-relative routes (or the exact route length of the selected board rules). The current 8-cell routes are synthetic test fixtures only.
2. Add a pawn-relative `pathProgress` field or equivalent route-position model; do not infer progress solely from a global cell index.
3. Refactor legal-move calculation, home-lane transition, finish, and capture detection to use the path.
4. Add test fixtures for all four player routes and test wrap-around and home-lane entry.
5. Add engine tests for all Step 06 scenarios.
6. Run formatter, analyzer, and tests in a real SDK environment; resolve all failures before marking Step 07 complete.

## Brand reminder

The path model contains no styling. When rendering the board, use the exact approved colors: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`, gold `#FFD700`, red `#FF3830`, black `#080B0B`, and cream `#FFF8E1`. Preserve the existing Ludo Lovers logo unchanged.
