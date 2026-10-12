# Step 07 — Edge-case review and validation plan

**Status: validation in progress. GitHub Actions run [38218035209](https://github.com/chandra0000/ludo-lovers/actions/runs/38218035209) passed `flutter analyze` and all 29 tests. Additional edge-case guards and tests have since been committed and are awaiting their CI run. Step 07 is not complete.**

## Repository readiness finding

The Flutter package foundation now exists at `apps/mobile/pubspec.yaml` and `apps/mobile/lib/main.dart`, with a temporary branded landing screen, theme, widget smoke test, and GitHub Actions workflow. The first two CI runs exposed a test-fixture issue in the illegal-move test. The fixture was corrected to keep a legal move available while selecting a pawn whose move overshoots. The next run passed dependency resolution, `flutter analyze`, and all 29 tests. A subsequent hardening commit now requires every player to have at least one pawn and replaces a null-assertion in capture lookup with a clear `StateError`; two regression tests cover those cases, and their CI result is pending.

There is still no generated `apps/mobile/android/` platform scaffold, so this does not yet prove that an Android APK can be built or launched. The local game engine also remains domain-only and is not integrated into the UI. Do not describe the app as playable or Step 07 as complete until the relevant checks and integration work pass.

## Review findings

1. **Synthetic routes only.** Current tests use short, overlapping 8-cell routes. They are useful for transition logic but are not the real board geometry and cannot validate the final Ludo board.
2. **Player skipping needs an explicit invariant.** `_advance` now skips players whose pawns are all finished and throws `StateError` if nobody can continue. Regression tests cover both behaviors.
3. **Started-game state should be well-formed.** The state constructor now rejects a player with no pawns; a regression test covers this invariant. Board-specific section/progress consistency still needs validation against `LudoBoardPaths`.
4. **Capture assumes valid positions.** Capture lookup now detects a main-track pawn with null progress and throws a descriptive `StateError` instead of failing via a null assertion. A regression test covers this defensive path.
5. **Route consistency is incomplete.** Each individual path validates lengths and duplicate cells within its own route, but `LudoBoardPaths` does not validate duplicate player IDs, shared-track consistency, cross-player route cell mapping, or home-lane overlap. These checks must be designed with the final board diagram.
6. **State versions and events need a policy.** A single action can increment the version more than once. That can work if documented, but a clean command/transition contract should preferably increment once per accepted command and assign event sequence/version metadata consistently.
7. **Rule choices remain provisional.** Sixes, captures, safe cells, stacking, finishing, and bonus turns must be written as a versioned rules profile before alpha. The current stack protection option is not assumed to be universally correct.

## Required next work

- Keep the Flutter shell and CI workflow; confirm the rerun passes, then generate the Android platform scaffold before claiming an Android build.
- Keep expanding invariant tests for malformed route positions, six/capture/finish bonus combinations, and no-eligible-player states; finished-player skipping and no-eligible-player handling already have regression tests.
- Build realistic route fixtures from the approved board design and validate every player's shared-track order and home lane.
- Decide whether the engine uses one version increment per command; then make tests assert the policy.
- Consolidate `ludo_engine.dart` and `PathBasedLocalGameEngine` only after executable tests cover the behavior; do not merge APIs blindly.
- Run `flutter analyze` and `flutter test` in CI or on a development machine before marking Step 07 complete.

## Exit criteria for Step 07

Step 07 is complete only when the app is a runnable Flutter project, rule behavior is documented, board paths are based on the approved geometry, tests execute successfully, and the old placeholder engine has been removed or explicitly adapted.
