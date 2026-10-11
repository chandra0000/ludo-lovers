# Step 07 — Local Game Engine

**Status:** Initial source foundation committed; not yet compiled, analyzed, or tested. Do not treat this as a playable game engine yet.

## Source file

`apps/mobile/lib/features/game/domain/engine/ludo_engine.dart`

This file establishes a pure-Dart starting point for:
- Game/player/pawn state models.
- Rule-profile configuration.
- Roll and move commands.
- Typed command rejection errors.
- State transitions and domain events.
- A first pass at legal pawn selection and capture handling.

It deliberately imports neither Flutter nor Flame. Rendering will be a separate layer.

## Important implementation gaps before this can be used in a playable build

1. **Board paths:** The current `_distanceToHomeEntry` method is a placeholder, not a correct Ludo path model. Replace it with explicit per-player ordered path data, including each player's main-track segment and home-lane transition. Do not ship gameplay using the placeholder.
2. **Home-entry calculation:** Movement must count from the pawn's current path index to that player's home-lane entry. The current foundation does not yet encode this correctly.
3. **Entry capture / stacking:** Implement collision checks for a pawn entering on its start cell and enforce the configured own-pawn/opponent-stacking rules.
4. **Rule correctness:** Verify consecutive sixes, no-legal-move handling, extra rolls, exact finishing, placement modes, and finished-player skipping against the approved rule profile.
5. **State immutability:** Defensively freeze or otherwise protect list/map/set inputs and outputs so callers cannot mutate state without a transition.
6. **Command identity:** Add command IDs/idempotency handling before online integration. State-version checking alone is not sufficient for network retries.
7. **Errors:** Add a dedicated stale-state error and ensure all rejected actions leave the state unchanged.
8. **Tests:** Add executable Dart unit tests before calling Step 07 complete.

## Required next implementation sequence

1. Add board geometry and `LudoPath` data model with a separate path per player.
2. Replace the placeholder distance calculation with path-based movement.
3. Implement and test yard entry, track movement, home-lane entry, exact finish, captures, safe cells, stacking, bonus rolls, and turn rotation.
4. Add unit tests for the Step 06 RULE-001 through RULE-022 scenarios.
5. Run `dart format`, `flutter analyze`, and `flutter test` in a real Flutter/Dart environment and fix every failure.
6. Only then connect the pure engine to Flutter/Flame presentation.

## Trust boundary

The roll value is injected into `RollDice` to keep local tests deterministic. In online mode, the authoritative game server must produce and validate the roll. Never accept a mobile-client-provided dice value as the source of truth for a competitive online match.

## Brand and UI boundary

The engine contains no colors, images, pixel coordinates, or animation code. The renderer must use the approved reference palette:
- Orange `#FF8928`
- Green `#33FF28`
- Blue `#289EFF`
- Magenta `#F428FF`
- Gold `#FFD700`
- Red `#FF3830`
- Black `#080B0B`
- Cream `#FFF8E1`

Keep the existing Ludo Lovers logo unchanged.
