# Step 07 — Canonical Engine Consolidation Decision

**Status:** Phase A1 complete: the legacy `LudoEngine` source file was removed in commit `1c834dfc2c96a44a22c3aa229d93bfb4ed82ffd5`, and CI passed. `PathBasedLocalGameEngine` is the sole active engine. Phase A3 has begun: `LudoRuleProfile` now centralizes engine rule settings and defensively freezes safe-cell indexes. This does not mean the rules or board are production-ready.

## Context gathered from the existing project notes

This decision consolidates the requirements recorded in:

- `step-07-edge-case-review-and-validation-plan.md`
- `step-07-engine-integration-progress.md`
- `step-07-movement-and-engine-review.md`
- `step-07-movement-and-engine-review.md` and `step-07-edge-case-review-and-validation-plan.md` edge-case notes
- `step-08-board-geometry-and-rendering-plan.md`
- `project-structure.md`
- `design-system-and-navigation.md`
- `flutter-design-system-foundation.md`
- the repository README and current Flutter CI workflow

Historically, the project had overlapping rule implementations. The legacy `ludo_engine.dart` has now been removed; its historical placeholder limitations are recorded here for context only. The active `PathBasedLocalGameEngine` uses the route model and movement resolver, but still has provisional rules, synthetic test paths, compatibility string labels for events, and incomplete board-position invariants.

## Decision

1. **Canonical rules foundation:** retain the path-based model (`LudoBoardPaths` + `LudoPathMovement` + path-based transition behavior) as the migration target because it represents movement in player-relative progress and uses explicit route data.
2. **Single public game-engine API:** migrate all callers and tests to one engine contract. Do not add new gameplay behavior to the legacy `LudoEngine` while consolidation is underway.
3. **Legacy status (2026-10-16):** repository tree/reference review found no imports or tests using `ludo_engine.dart`; `LudoEngine` is marked `@Deprecated` as a migration guard. Keep `PathBasedLocalGameEngine` canonical. Delete the legacy file in a separate cleanup commit after CI is green and a fresh content-wide search confirms no references.
4. **One accepted command, one state-version increment:** an accepted command creates one transition with a single new state version. Events produced by that command share the resulting state version and receive deterministic per-transition sequence numbers. Rejected commands leave the input state unchanged.
5. **Typed contracts:** replace string-only event names with a sealed/typed event model and represent player actions as typed commands. Keep errors typed. The presentation layer consumes events; it does not decide whether a move is legal.
6. **Deep immutability:** copy and expose unmodifiable collections for players, pawns, routes, safe-cell sets, event lists, and rule-profile collections. Validate invariants when constructing a state/profile.
7. **Explicit rules profile:** game behavior is configured by a named, versioned rules profile. The current six-to-enter, exact-finish, bonus-on-six/capture/finish, third-six penalty, capture-on-unsafe-cell, stack protection, and match-end defaults are provisional and must be confirmed before alpha.
8. **Route-driven movement:** no engine may infer home-entry distance from global cell numbers. Movement must use the selected player's ordered route. Safe-cell membership and capture positions must be expressed consistently in global track-cell coordinates.
9. **Local/AI/online separation:** local players and AI submit the same commands to the same pure rules engine. The online service later validates the same command/rules contract authoritatively; the mobile client never supplies authoritative competitive dice results.
10. **Rendering separation:** Flutter/Flame reads state and transition events and maps logical cells to board coordinates. UI, effects, animations, network calls, and persistence stay outside the pure rules engine.
11. **Brand invariant:** preserve the uploaded official Ludo Lovers logo unchanged. Use the approved colors exactly: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`, gold `#FFD700`, red `#FF3830`, black `#080B0B`, cream `#FFF8E1`.

## Required implementation sequence

### A. Freeze and document the rule profile
- Implemented foundation: `LudoRuleProfile` (`classic-v1-provisional`) centralizes the current engine flags and defensively copies safe-cell indexes. Profile defaults remain provisional.
- Next: add explicit typed event payloads and typed commands; the current event `kind` is an enum derived from a compatibility string.
- Record decisions for entering the track, safe cells, captures, stacks, bonus turns, consecutive sixes, home-lane entry, exact finishing, and match completion.
- Keep undecided variations marked as open decisions rather than silently treating defaults as final.

### B. Validate board paths before production gameplay
- Use the intended 15×15 visual grid and 52-cell shared track with six private home-lane cells only after checking them against the approved board diagram and chosen rule variant.
- Confirm four ordered player routes, entry cells, safe cells, private lanes, and finish behavior.
- Keep the current 8-cell fixtures as synthetic engine tests only.
- Add geometry tests for shared-track order, route wrap-around, home-lane mapping, safe cells, and route invariants.

### C. Consolidate the engine contract
- Define typed commands, typed events, typed failures, immutable state, and a deterministic transition result.
- Require exactly one state-version increment per accepted command; rejected commands must not mutate state.
- Validate every pawn's section/progress combination against its player's route.
- Make turn advancement skip players who have finished all pawns and return a controlled terminal outcome if no eligible player remains.
- Decide and test whether a player finishing all pawns immediately ends the match or determines placement while remaining players continue.

### D. Expand acceptance tests
Required suites:
- yard entry with and without a six, if the selected profile permits either;
- legal track movement and route wrap-around;
- home-lane entry and progression;
- exact finish and overshoot;
- safe-cell protection and capture;
- own/opponent stacks and the selected stack policy;
- all combinations of bonus rolls on six, capture, and finish;
- consecutive-six behavior;
- no legal move and finished-player skipping;
- winner/match completion and actions after completion;
- wrong-player, stale-version, malformed-state, duplicate-ID, and invalid-roll rejection;
- state/event version and sequence consistency;
- deterministic replay of the same command sequence.

### E. Integrate only after the engine is stable
- Build the Flame board renderer from a verified logical-cell-to-coordinate map.
- Highlight only legal destinations returned by the engine.
- Animate typed transition events, including stepwise pawn movement and landing shadows; animation never changes rules or state.
- Finish a full local match before prioritizing Supabase, online play, social features, voice, tournaments, or virtual economy.

## Quality gates

A step is complete only when all relevant gates pass:

- `dart format` has no unformatted changed files.
- `flutter analyze` passes.
- `flutter test` passes, including new regression tests.
- GitHub Actions succeeds for the committed revision.
- Board-specific tests use verified route data, not the 8-cell synthetic fixtures.
- Documentation describes what is implemented versus planned.
- The Android debug APK build passes in CI; this alone does not prove that a human has installed and tested it on a physical device.

## Current limitations — do not overstate progress

- The local engine is not yet connected to the Flutter/Flame board.
- Existing engine tests have used synthetic short routes.
- Final board geometry and safe-cell mapping still require validation against the approved board design.
- Rule defaults are provisional.
- The legacy `LudoEngine` source file is removed and CI passed on commit `1c834dfc2c96a44a22c3aa229d93bfb4ed82ffd5`. Historical documents may still mention the former file and should not be read as current implementation status.
- Passing CI validates the current code and tests only; it does not establish production readiness or prove every game-rule combination correct.


## Board topology consolidation — 2026-10-18

- The canonical 52-cell physical coordinate sequence is now declared in `ClassicLudoBoardDefinition.sharedTrackCells`; `ClassicLudoBoardCoordinateFactory.sharedTrack` is a compatibility alias to that exact list, not a second coordinate table.
- The four seat-entry indexes, home-lane coordinate lists and logical home-lane IDs remain on the canonical seat definitions. `ClassicLudoBoardFixture` derives its player-relative paths and entry map from those seats.
- `LudoRuleProfile` defaults its safe-cell set from `ClassicLudoBoardDefinition.provisionalSafeTrackCellIds`; the geometry helper reads the same set. These values are still provisional and are not a visual approval of the board.
- Added `canonical_board_source_of_truth_test.dart` to assert the shared-track alias identity, route/entry alignment, home-lane alignment, safe-cell agreement, and the release blocker.
- Do not infer cell geometry from the composite brand collage. The currently recorded non-orthogonal transitions remain indexes 4, 17, 30 and 43; `isGameplayReady` must remain false until a clear cell diagram validates the route or a documented v1 topology is explicitly approved.
- Latest inspected CI run was #219 (commit `de36cb96dba532dd39ec98310ac1b7b8c5d23205`). Formatting and analysis passed, but automated tests failed in two UI tests because they expected stale labels (`Local Match Preview` and `PROTOTYPE ONLY`) that are no longer rendered by the current screen. The Android debug build was skipped after the test failure. The test assertions have been aligned to the current UI and the new topology regression suite added; a fresh CI run must confirm the fix before this increment is considered green.


## Local Android playtest hardening — 2026-10-18

- The local match screen is explicitly labelled as a local playtest. This is intentional while board topology and safe-cell IDs remain provisional; it is not an online/competitive release.
- The board destination preview now reads movement flags from the active engine profile instead of duplicating hard-coded rule booleans in presentation code.
- The engine now rejects malformed pawn route positions before accepting roll/move commands: yard positions must have null progress; track progress must stay on the shared track; home-lane progress must be inside that player's lane; finished progress must equal the route finish value.
- Added regression coverage for invalid position rejection and for deriving logical home-lane ID ranges from canonical seat metadata, removing a duplicate map from geometry.
- Reference used: Flutter's official testing guidance recommends unit/widget tests for logic and UI behavior and integration tests for whole-app/device behavior. This increment strengthens deterministic engine/widget gates; a physical Android install/play session is still required before calling the build device-verified.
- Next gate: confirm the route against a clear board-cell diagram, keep `isGameplayReady == false` until then, and expand device-level testing after the board contract is approved.


## CI failure follow-up — local playtest hardening

- Pipeline #223 failed in one engine test, not in formatting or static analysis: 143 tests passed and `skips a player whose pawns are all finished` failed because its fixture listed a green player without defining a green route.
- The test fixture now defines a valid green path, matching the three players declared in that test state. This keeps the production invariant check strict rather than weakening it to accommodate an incomplete fixture.
- Re-run the full CI gate before treating this fix as verified. The board readiness gate remains false until topology is approved.


## Deterministic replay acceptance — 2026-10-18

- Added an engine regression test that replays the same accepted roll-and-move command sequence from the same immutable initial state.
- The test compares resulting turn/version/pawn state and typed event payload/order, making deterministic local replay an explicit quality gate before AI or server-authoritative play is introduced.
- Pipeline #224 passed on commit `d9afdbe2e35efd3c956104659a2ada59166000f8`. This confirms the existing formatting, analysis, tests, and debug APK workflow on that revision; the new replay test requires its own pipeline run.
- Next gameplay priority remains visual route acceptance: do not enable production readiness or finalize safe cells until the clear board-cell diagram and route orientation are reconciled.


## Board-backed turn and pawn HUD regression — 2026-10-18

- Pipeline #225 passed on commit `230fe6846119dc0dcab3356cf132da60d1f1acf3`, including the deterministic replay regression.
- Added a widget-level flow that rolls a non-six while all pawns are in the yard, verifies the turn advances and no previous-player pawn remains selectable, then rolls a six for the next player and moves that player's pawn.
- The widget test also checks that the visible current-turn label and `OUT 1/4` pawn counter reflect the controller state after movement.
- This validates synchronization between engine state, legal pawn hit targets, and the board HUD in a deterministic widget environment. It is not a substitute for a physical-device playtest.
- Board route and safe cells remain provisional; no production readiness flag is enabled by this test.


## Pending-roll interaction guard — 2026-10-18

- Extended the board-backed widget test to assert that the Roll Dice button is disabled while a roll is waiting for a legal pawn selection.
- After the pawn move resolves and an extra turn is granted, the test asserts that Roll Dice becomes available again.
- This guards against duplicate-roll UI actions and verifies the roll control follows the engine's pending-roll state. The provisional board route remains unapproved.


## Completed-match action guard — 2026-10-18

- Added a regression test that submits both a roll and a pawn move against a completed state.
- Both commands must fail with the typed `gameCompleted` error before any state can change; the test verifies winner, pending roll, version, and pawn positions remain unchanged.
- This protects the engine contract independently of UI button disabling, so a stale or direct command cannot continue a finished match.
- Pipeline #227 passed on commit `8630a859061634ada1577ceb49f3dd710b079a55`; this new regression requires its own CI run.
- Board topology and safe-cell IDs remain provisional. Next gameplay work should prioritize a clear topology reference and route approval; do not enable production readiness or infer cell order from style imagery.


## Winner and rematch widget regression — 2026-10-18

- Added deterministic initial-state injection to `LocalGameController` for focused widget tests; normal construction and reset continue to use the factory's fresh-game state.
- Added a board-backed widget regression that starts one orange pawn two steps from finish, completes the match with a deterministic roll, and verifies the winner banner, disabled roll action, hidden pawn targets, and visible Play Again control.
- The same test taps Play Again and checks that completion/winner/pending roll clear, all pawns return to the yard, the first turn returns to orange, and rolling is re-enabled.
- This test verifies UI behavior for the engine's terminal state without changing or approving the provisional route. Board topology and safe-cell positions remain provisional.
- Pipeline #228 passed on commit `216ab248a2bc9f3039fd8ded04cd02f90e7db327`; this regression requires its own CI run.


## Immutable snapshots and accepted-command regression — 2026-10-18

- Extended the roll/move engine test to prove that accepted commands produce new snapshots without mutating the initial or intermediate state; the earlier rolled snapshot keeps its pending six and yard pawn after a later move.
- Asserted the six bonus-turn behavior at the state boundary.
- Added a collection-immutability regression: constructor inputs are defensively copied, and exposed player/pawn lists reject mutation.
- This is engine-level coverage only; the route topology and safe-cell map remain provisional. Capture and finish cases are covered by existing focused tests and will continue to be extended without treating the provisional topology as approved.
