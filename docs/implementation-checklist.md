# Ludo Lovers implementation checklist

This checklist is the release-oriented source of truth for the next implementation steps. Keep changes on `main`, keep CI green, and do not mark the game gameplay-ready until the visual route is approved.

## Current baseline (2026-10-20)

- [x] Canonical board definition exists for the 52 shared-track cells, four seats, five home-lane cells per seat, and provisional safe-cell IDs.
- [x] Board geometry audit and cross-module source-of-truth tests exist.
- [x] Path-based local game engine supports roll, legal pawn selection, movement, captures, finish events, turn transitions, and version checks.
- [x] Board preview and local-game screens exist.
- [x] Premium board frame styling is on `main`.
- [x] Latest observed main-branch Flutter checks passed for commit `4f838cb7fc053c196c8abba0926d5ef6f7304040` (workflow run 369).
- [ ] Board route is approved against the user's original board reference.
- [ ] Gameplay readiness remains disabled until topology is approved.
- [x] Board-backed local match flow and widget-level interaction coverage are present in the repository; physical-device Android verification is still outstanding.
- [ ] Online/server-authoritative play is not implemented.

## Next steps — execute in this order

### 1. Verify a complete local match on the rendered board
- [x] Local match screen renders pawns from the controller's live engine state and animates pawn movement; widget coverage checks state changes and pawn animation.
- [x] Widget test covers roll → legal pawn highlighting → pawn selection/movement; turn/bonus-roll behavior is asserted.
- [x] Widget tests cover no-legal-move turn passing and six bonus-roll behavior.
- [x] Widget tests cover captures, entry-cell safety, safe-cell protection, and stacked-opponent protection.
- [x] Widget tests cover home-lane overshoot, finishing, winner state, post-win input lock, and clean rematch.
- [x] Existing local-game widget tests and engine-level rule tests cover the local match flow (see `apps/mobile/test/features/game/presentation/screens/local_game_screen_test.dart` and `apps/mobile/test/features/game/domain/engine/path_based_local_game_engine_test.dart`).
- [ ] Run the updated suite on CI after this checklist commit and confirm physical-device Android behavior.

### 2. Close the board-topology approval gate
- [ ] Compare all 52 track-cell coordinates, four player entry points, home-lane order, center finish, and safe cells against the user's original reference.
- [ ] Explicitly review the diagonal transitions at track indexes 4→5, 17→18, 30→31, and 43→44.
- [ ] Do not infer replacement coordinates from a generic Ludo board; the supplied reference is authoritative.
- [ ] Only after approval, update the canonical definition and derived route/coordinate mappings together, then update regression fixtures.
- [ ] Keep `isVisualTopologyApproved` / gameplay readiness false until the comparison is accepted.

### 3. Polish the Android gameplay HUD
- [ ] Match board proportions and player-panel placement to the approved reference at small and large Android sizes.
- [ ] Preserve the existing Ludo Lovers logo and approved brand palette: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`.
- [ ] Keep the premium black-and-gold finish restrained so it does not replace or distort the four player colors.
- [ ] Ensure dice and pawn controls expose meaningful labels and disabled/available states to accessibility services.

### 4. Quality gate for every change
Run from `apps/mobile/`:
```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```
- [ ] Confirm the workflow run belongs to the latest `main` commit and is green before starting another UI change.

## Explicitly out of scope until the local match and board are accepted

- Online multiplayer / server-authoritative dice
- Authentication, friends, rooms, wallet, achievements, and Love Mode
- Any claim that the provisional route is production-ready
