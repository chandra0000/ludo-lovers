# Step 07 — Edge-case review and validation plan

**Status: source review in progress. Not verified by Dart/Flutter execution.**

## Repository readiness finding

The current default branch does not contain `apps/mobile/pubspec.yaml` or `apps/mobile/lib/main.dart`. The game-domain source and Flutter-style tests are present, but there is not yet a runnable Flutter app at the expected path. Therefore a GitHub Actions workflow that runs `flutter pub get`, `flutter analyze`, and `flutter test` would fail before checking the engine. Do not treat source files or test cases as passing tests.

## Review findings

1. **Synthetic routes only.** Current tests use short, overlapping 8-cell routes. They are useful for transition logic but are not the real board geometry and cannot validate the final Ludo board.
2. **Player skipping needs an explicit invariant.** `_advance` scans players once and leaves the index at the last examined player if no eligible pawn owner is found. That can silently select a player whose pawns are all finished. The engine should not silently continue when no active player exists.
3. **Started-game state should be well-formed.** Player IDs and pawn IDs are checked, but the state does not currently require every player to have at least one pawn. Empty per-player pawn sets make `every(...)` checks vacuously true and can create misleading winner detection.
4. **Capture assumes valid positions.** Capture lookup uses `other.position.progress!`. A malformed main-track position with null progress can throw at runtime instead of returning a controlled invalid-state error.
5. **Route consistency is incomplete.** Each individual path validates lengths and duplicate cells within its own route, but `LudoBoardPaths` does not validate duplicate player IDs, shared-track consistency, cross-player route cell mapping, or home-lane overlap. These checks must be designed with the final board diagram.
6. **State versions and events need a policy.** A single action can increment the version more than once. That can work if documented, but a clean command/transition contract should preferably increment once per accepted command and assign event sequence/version metadata consistently.
7. **Rule choices remain provisional.** Sixes, captures, safe cells, stacking, finishing, and bonus turns must be written as a versioned rules profile before alpha. The current stack protection option is not assumed to be universally correct.

## Required next work

- Create the actual Flutter project shell (including `pubspec.yaml` and `lib/main.dart`) before adding a Flutter CI workflow.
- Add invariant tests for finished-player skipping, malformed route positions, six/capture/finish bonus combinations, and no-eligible-player states.
- Build realistic route fixtures from the approved board design and validate every player's shared-track order and home lane.
- Decide whether the engine uses one version increment per command; then make tests assert the policy.
- Consolidate `ludo_engine.dart` and `PathBasedLocalGameEngine` only after executable tests cover the behavior; do not merge APIs blindly.
- Run `flutter analyze` and `flutter test` in CI or on a development machine before marking Step 07 complete.

## Exit criteria for Step 07

Step 07 is complete only when the app is a runnable Flutter project, rule behavior is documented, board paths are based on the approved geometry, tests execute successfully, and the old placeholder engine has been removed or explicitly adapted.
