# Step 10 — Local Game Integration Gate

**Status:** Planning and safety gate. The local engine exists, but the production board route is not approved.

## Objective

Deliver a first playable local match without allowing the renderer and rules engine to disagree about pawn positions.

## Current code facts

- `PathBasedLocalGameEngine` implements local roll/move transitions, legal-pawn lookup, captures, bonus rolls, turn rotation and completion.
- `LudoPathMovement` resolves yard entry, main-track progress, home-lane movement, exact finish and overshoot.
- `ClassicLudoBoardCoordinateFactory` defines 52 provisional display cells.
- The provisional track has non-orthogonal transitions at indexes 4, 17, 30 and 43.
- `ClassicLudoBoardCoordinateFactory.isGameplayReady` is intentionally false.
- `BoardPawnLayout` and `BoardPawnPositionResolver` are presentation adapters; they do not approve the route or enforce move legality.

## Required order

### Gate A — Approve topology

Before route migration:
1. Use a clear, straight-on board diagram to identify all 52 shared-track cells in movement order.
2. Confirm the four start cells and clockwise/counter-clockwise direction for each seat.
3. Confirm all six home-lane cells and the exact transition from shared track to each lane.
4. Mark safe cells and document the chosen rules variant, including start-cell safety, stacked pawns, capture bonus, six-roll and finish bonus.
5. Update the route, seat offsets, safe-cell metadata and painter mapping together.
6. Add tests for every transition, route wraparound, entry indexes, home-lane entry and safe-cell mapping.

Do not infer rule metadata from the small board thumbnail in the composite brand sheet.

### Gate B — Connect engine to approved routes

1. Create one canonical `LudoBoardPaths` fixture from the approved physical route.
2. Add a test proving each player-relative path is the same 52 physical cells rotated to that player's start.
3. Add an explicit adapter from engine progress to physical cell ID; avoid maintaining independent offset logic in multiple files.
4. Ensure safe-cell IDs are physical track IDs and are translated consistently for all players.
5. Keep yard and finished positions separate from shared-track hit testing.
6. Do not turn on gameplay readiness until all Gate A and Gate B tests pass.

### Gate C — Wire interactions

1. Start a local game with four seats and four pawns per seat.
2. Roll a local dice value through an injectable dice interface (seeded/fixed dice in tests).
3. Derive legal pawn IDs from engine state.
4. Highlight only legal pawns and their destination cells.
5. On tap, submit the move to the engine using the current state version.
6. Render the returned state and animate the pawn to the returned physical destination.
7. Reject stale taps, out-of-turn actions and illegal moves without changing game state.

The UI must not duplicate Ludo rules. The engine returns state; the board only renders it.

### Gate D — Acceptance tests for Alpha 0.1

- Four players and sixteen pawns initialize with unique IDs.
- A non-six cannot enter a pawn from the yard when the chosen rules require six.
- Six allows entry to the correct player start cell.
- Legal moves match the displayed highlights.
- A move across track wraparound resolves to the correct physical cell.
- Captures occur only on eligible, non-safe cells.
- Safe cells protect pawns according to the chosen rules.
- Home-lane entry and exact finish work for all four colors.
- Overshooting the finish is rejected when exact finish is required.
- Third consecutive six, bonus rolls and no-legal-move turn rotation follow the documented rules.
- Completed matches reject additional actions.
- The same fixed dice sequence produces deterministic state transitions.
- Flutter analysis, unit/widget tests and Android debug APK build pass.

## Out of scope until Alpha 0.1 is stable

Supabase authentication, online matchmaking, chat, virtual coin transactions and server-side fairness. Online games must later use an authoritative server; the local dice interface must not be reused as a source of authority for competitive online games.

## Device validation

CI confirms static analysis, automated tests and APK compilation only. A real Android installation and a complete manual match remain separate acceptance checks.
