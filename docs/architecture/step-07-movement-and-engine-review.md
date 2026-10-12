# Step 07 — Movement and Engine Rule Review

**Status:** Additional source validation and test cases committed. Tests have not been run.

## Added in this review

- Added constructor invariants for local game state: 2–4 unique non-empty player IDs, valid current-player index, pawn ownership by a participating player, unique non-empty pawn IDs, valid pending dice value, and non-negative version/consecutive-six counters.
- Added a guard against configuring zero or a negative maximum consecutive-six count.
- Added tests for rejecting a second dice roll while a move is pending, rejecting an illegal pawn move without mutating the original state, and rejecting duplicate player/pawn identities.
- Existing movement tests cover yard entry, route progress, home-lane entry, exact finish, overshoot, invalid dice, and already-finished pawns.
- Existing engine tests cover capture, safe cells, stack protection, third-six turn loss, no-legal-move handling, and match completion.

## Rule behavior currently encoded (provisional)

- Six is required to leave the yard.
- Exact roll is required to finish.
- A six grants another roll.
- A single opponent pawn is captured on a non-safe cell.
- Under the default local MVP setting, a stack of two or more opponent pawns is protected.
- A capture grants another roll.
- Three consecutive sixes ends the turn without moving.
- The match ends when a player finishes all pawns.

These are implementation defaults, not yet a signed-off final rules document. Confirm variants before treating them as production rules.

## Must-do before Step 08

1. Run `flutter analyze` and `flutter test` in a configured Flutter SDK.
2. Fix every compile, lint, and test failure.
3. Build and verify actual player route definitions against the final board geometry; current engine tests use synthetic routes.
4. Audit edge cases: multiple pawns per cell, home-lane collisions, finished-player turn skipping, all-pawns-finished detection, bonus-roll combinations, and event/version sequencing.
5. Consolidate the path-based engine with the older engine only after the behavior is testable and the API is agreed.

## Scope note

The code is still a local rules foundation. It is not an online-authoritative game engine, not connected to Supabase, and not a playable app build. No tests or static analysis were executed as part of these commits.
