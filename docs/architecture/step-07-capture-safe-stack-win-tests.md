# Step 07 — Local Engine Rule-Test Expansion

**Status:** Source and tests committed; not executed yet. This is not a playable or verified game build.

## What changed

- Added configurable stack handling to `PathBasedLocalGameEngine`.
- Default MVP rule: a cell occupied by two or more opponent pawns is treated as a protected stack; landing there does not capture them.
- Kept capture handling disabled on configured safe cells.
- Added focused test cases for:
  - capturing one opponent pawn on a non-safe cell;
  - not capturing an opponent on a safe cell;
  - protecting a two-pawn opponent stack under the default rule;
  - completing the match when the final pawn reaches home, recording the winner, and rejecting further rolls after completion.

## Current rule decisions that still need product confirmation

Ludo variants differ. Before release, confirm the intended rules for stacked pawns, safe cells, extra turns for sixes/captures/finishing, three consecutive sixes, and whether the first player to finish all pawns wins immediately. The stack behavior is configurable in code so it can be changed deliberately.

## Known limitations

- Tests use synthetic 8-cell routes and are not a representation of the final 52-cell Ludo board.
- Board routes and safe-cell indexes must be created from the approved board diagram and reviewed.
- No Dart/Flutter test run or static analysis has been performed in this environment. These are committed test sources, not proof that the tests pass.
- The path-based engine remains separate from the earlier `ludo_engine.dart`; consolidation and a full rule audit are still required.
- Multiplayer, authoritative server validation, persistence, and visual rendering are not part of this local engine test set.

## Next actions

1. Run `flutter test` and `flutter analyze` in a configured Flutter environment.
2. Fix any compile/test failures before adding more gameplay.
3. Decide and document the official stack/safe-cell/bonus-turn rules.
4. Build the real board path fixture and test all player routes against the board diagram.
5. Consolidate the engine API before beginning Step 08 (board rendering).
