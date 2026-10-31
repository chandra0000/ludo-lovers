# Step 06 — Ludo Game Rules and Acceptance Tests

**Project:** Ludo Lovers  
**Roadmap step:** 06 — Ludo Game Rules  
**Status:** Confirmed rules specification. The local Team Up engine, mode-selection integration, gameplay identity/turn-transfer UI, and engine-level stack/turn/victory acceptance tests are implemented. The shared board route remains provisional, and online/server-authoritative gameplay is not implemented.  
**Purpose:** Agree on deterministic game rules before building the local game engine in Step 07.

## 1. Rule-profile decision

Ludo has regional variants. To avoid ambiguous gameplay, Ludo Lovers will start with a configurable rule profile rather than scattering rule assumptions through UI code.

**Proposed default profile: Classic Ludo Lovers**
- 2–4 players, one color per player, four pawns per player.
- Standard cross-shaped Ludo board with a shared main track and separate home lanes.
- A six is required to move a pawn out of its yard.
- Rolling a six grants another roll, subject to the consecutive-six rule below.
- Capturing an opponent grants an extra roll.
- Reaching the final home grants an extra roll.
- Exact count is required to enter the final home.
- Safe cells cannot be captured on.
- Three consecutive sixes end the current player's turn; movement caused by the third six is not allowed.
- A player wins when all four pawns reach the final home.
- The match ends when one player wins in 2-player / winner-takes-all modes; 3–4 player placement modes may continue to rank the remaining players.

These are proposed baseline rules. Before implementing, the user/product owner should approve or change the configurable choices in Section 8. Keep each rule in a rule profile so variants can be added without rewriting the engine.

## 2. Terms and board model

- **Yard/Home base:** The four starting spaces containing a player's unentered pawns.
- **Entry cell:** The player's designated starting cell on the shared track.
- **Main track:** Shared loop traversed by pawns after entry.
- **Safe cell:** A marked cell on which an opponent cannot capture a pawn.
- **Home lane:** The player's private final path from the main track to the center.
- **Final home:** The completed destination for one pawn.
- **Turn:** The sequence of rolls and legal actions assigned to one player.
- **Ply/action:** One server- or engine-accepted action such as a roll or pawn move.
- **Game state version:** Monotonically increasing version used to detect stale state in online play.

Represent pawn progress as a logical path index, not screen pixels. Board rendering maps logical cells to coordinates separately. Do not make movement legality depend on animation positions.

## 3. Players and turn order

- Support 2, 3, or 4 players for local mode; online matchmaking can select allowed seat counts by mode.
- Each player owns exactly four pawns.
- Seat order is fixed when a game begins and advances clockwise through active players.
- Finished players are skipped when choosing the next active player.
- A player who has finished all pawns cannot roll or move again.
- A turn has a defined current player, roll count, consecutive-six count, and pending action state.
- Only one legal action may be committed for a given state version. Duplicate/stale commands must not move a pawn twice.
- In online mode, the authoritative server validates all commands and publishes accepted state changes. The client only requests actions and renders the accepted result.

## 4. Dice rules

- A roll result is an integer from 1 through 6.
- Local mode can use a standard random source for casual play; online competitive mode must use the server's secure, auditable dice protocol.
- A roll is accepted only when the player owns the current turn and the game is in a roll-allowed state.
- A roll event is recorded once with game ID, player ID, roll number, state version, result, and applicable verification metadata.
- Repeated taps, network retries, or duplicated messages must not create multiple rolls for the same command/idempotency key.
- A six normally grants another roll, but the third consecutive six ends the turn and no move is made from that third roll.
- If the roll produces no legal moves, the engine automatically resolves the roll and advances the turn unless the active rule profile grants a further roll for that result (e.g. a six still follows the consecutive-six rule).
- No dice result or verification badge should be displayed as server-verified until verification has actually succeeded.

## 5. Pawn entry and movement

### Entering from yard
- A pawn may leave the yard only on a six.
- Entering places the pawn on its player's entry cell and counts as the action for that roll.
- A pawn already on the main track is not moved instead of entering unless the player chooses it as a legal option.
- If all pawns are in the yard and the roll is not a six, there are no legal moves.
- If the entry cell is occupied by the player's own pawn, the engine must apply the selected stacking rule. Proposed default: own pawns may share a cell unless the product chooses a no-stacking variant.
- If the entry cell has an opponent pawn and is not safe, entering captures that pawn according to the capture rule.

### Moving on the track
- A pawn moves forward by exactly the rolled number of logical cells.
- Pawns never move backward.
- A pawn must follow its own path into its home lane; it cannot continue around the main loop once its path reaches the home-lane entry.
- Movement must not overshoot the final home. If the roll exceeds the exact remaining count, that pawn is not a legal choice.
- Only pawns with a legal destination can be selected.
- If several pawns are legal, the player chooses one.
- The engine calculates legal moves before animation begins; animation never decides the result.

## 6. Captures, safe cells, and stacking

- Landing on an opponent pawn on a non-safe cell captures it and returns it to its yard.
- A move may capture only the opponent pawn(s) defined by the active capture profile.
- Proposed default: one opponent pawn can occupy a track cell at a time; if an opponent stack exists because a variant allows it, capture behavior must be explicit and tested.
- Landing on a safe cell never captures.
- A pawn cannot capture another pawn inside a private home lane.
- Own-pawn stacking is configurable. Baseline proposal: own pawns may share a cell; they remain separate selectable pawns.
- Safe-cell locations must come from board configuration, not hardcoded UI coordinates.
- Capture events are explicit domain events and can award an extra roll according to the rule profile.

## 7. Turn resolution and bonus rolls

The engine resolves a completed turn in this order:
1. Validate the active player and state version.
2. Validate the roll/action and calculate legal moves.
3. Apply the selected legal pawn move, if one exists.
4. Resolve capture(s).
5. Resolve pawn reaching final home.
6. Check whether the player has won.
7. Decide whether an extra roll is granted.
8. Otherwise reset consecutive-six tracking as appropriate and advance to the next active player.

Proposed default extra-roll conditions:
- Roll a six, except when it is the third consecutive six.
- Capture an opponent pawn.
- Move a pawn into final home.

If multiple bonus conditions happen on the same move, they do not stack into multiple immediate rolls; the player receives one extra roll. Product owner can change this in the rule profile.

## 8. Configurable rule profile

Implemented foundation: `apps/mobile/lib/features/game/domain/engine/ludo_rule_profile.dart` defines immutable `LudoRuleProfile`, consumed by `PathBasedLocalGameEngine`. It defensively copies and freezes safe-cell indexes and validates profile identity/version, safe-cell indexes, and the consecutive-six limit. Do not read these settings directly from widgets. The profile defaults are provisional, not product-approved.

Initial fields:
- `playerCount`: 2, 3, or 4.
- `pawnsPerPlayer`: default 4.
- `sixRequiredToEnter`: default true.
- `extraRollOnSix`: default true.
- `extraRollOnCapture`: default true.
- `extraRollOnFinish`: default true.
- `maxConsecutiveSixes`: default 3.
- `thirdSixEndsTurnWithoutMove`: default true.
- `safeCellIndexes`: board-specific list.
- `allowOwnPawnStacking`: proposed default true.
- `allowOpponentStacking`: default false.
- `requireExactFinishRoll`: default true.
- `finishEndsMatchImmediately`: mode-dependent.
- `noLegalMovePolicy`: automatic turn resolution.
- `bonusRollsStack`: default false.
- `captureReturnsPawnToYard`: default true.

A mode selects a named rule profile. Example modes may change seat count, turn timer, AI participation, or scoring, but must not silently change Classic rules.

## 9. Match end and results

- A pawn becomes finished only after a legal exact-count move reaches final home.
- A player wins when all four pawns are finished.
- Match result is emitted exactly once.
- A finished game rejects further rolls and moves.
- In winner-takes-all mode, stop when the first player wins.
- In placement mode, continue until the required placements are determined or the mode's stopping condition is met.
- XP, cosmetics, and virtual-coin rewards are not calculated by the board renderer; they are separate result/economy concerns and must be validated by the trusted service.

## 10. Deterministic domain events

The engine should emit typed events such as:
- `GameStarted`
- `TurnStarted`
- `DiceRolled`
- `LegalMovesCalculated`
- `PawnEntered`
- `PawnMoved`
- `PawnCaptured`
- `PawnFinished`
- `ExtraRollGranted`
- `TurnEnded`
- `PlayerFinished`
- `GameCompleted`

Each accepted event should be reproducible from the prior state plus the accepted command and rule profile. Keep event payloads free of UI pixel coordinates. In online mode, include sequence/state-version metadata and make the event stream authoritative.

## 11. Invalid actions that must be rejected

- A player rolls out of turn.
- A player moves a pawn before a roll is accepted.
- A player selects a pawn that is not theirs.
- A player selects a pawn with no legal destination.
- A pawn move overshoots final home.
- A pawn is moved twice for one accepted roll.
- A player submits a stale state version.
- A command arrives after game completion.
- A finished player tries to act.
- A malformed or out-of-range dice result is injected into the domain layer.
- A client submits a winner, capture, coin balance, or dice outcome as authoritative truth in online mode.

Invalid commands should return a typed error without partially changing the game state.

## 12. Acceptance test matrix

| ID | Scenario | Expected result |
|---|---|---|
| RULE-001 | Roll 1–5 with all pawns in yard | No pawn enters; turn resolves according to no-legal-move and bonus rules |
| RULE-002 | Roll six with pawn in yard | A yard pawn can enter on its entry cell |
| RULE-003 | Multiple legal pawns | All and only legal pawns are offered |
| RULE-004 | Move pawn by roll value | Path index advances by exactly that value |
| RULE-005 | Overshoot final home | Move is illegal |
| RULE-006 | Exact count reaches final home | Pawn becomes finished |
| RULE-007 | Land on opponent on unsafe cell | Opponent returns to yard; capture event emitted |
| RULE-008 | Land on opponent on safe cell | No capture |
| RULE-009 | Capture occurs | One bonus roll if enabled; bonuses do not stack |
| RULE-010 | First or second consecutive six | Apply normal six/bonus behavior |
| RULE-011 | Third consecutive six | Turn ends and no move is applied from third roll |
| RULE-012 | Roll has no legal move | Turn resolves automatically; no stuck UI state |
| RULE-013 | All four pawns finish | Player wins; result emitted once |
| RULE-014 | Action submitted by wrong player | Rejected; state unchanged |
| RULE-015 | Duplicate command | Applied at most once |
| RULE-016 | Stale state version | Rejected or resynchronized; no double move |
| RULE-017 | Command after game completion | Rejected |
| RULE-018 | Finished player selected for next turn | Skipped |
| RULE-019 | Two bonus conditions on same move | At most one extra roll |
| RULE-020 | Different board orientation | Logical rules remain the same; renderer mapping changes only |
| RULE-021 | Invalid dice value 0 or 7 | Rejected by domain validation |
| RULE-022 | Online client claims its own winner/coins | Ignored/rejected; server decides |

## 13. Suggested pure-Dart domain API

Keep these independent of Flutter and Flame:
- `LudoRuleProfile`
- `LudoGameState`
- `LudoPlayerState`
- `LudoPawnState`
- `LudoCommand` (RollDice, MovePawn)
- `LudoEvent`
- `LudoEngine` with functions to validate commands, calculate legal moves, and return the next state plus events.
- `LudoPath` / board configuration mapping logical indexes to cells.
- Typed rejection reasons such as `NotYourTurn`, `RollRequired`, `IllegalMove`, `OvershootFinish`, `GameAlreadyCompleted`, `StaleStateVersion`.

Prefer immutable state transitions: `nextState = engine.apply(state, command, profile)`. Unit-test this engine without a UI or network connection. Keep random number generation behind a dice-provider interface so deterministic tests can supply fixed rolls.

## 14. Product decisions to confirm before Step 07

The current baseline is a proposal. Confirm or revise:
1. **Third consecutive six:** Should it end the turn with no move from that third roll? Proposed: yes.
2. **Own pawns on same cell:** Allow stacking? Proposed: yes.
3. **Capture bonus:** Extra roll for capturing? Proposed: yes.
4. **Finish bonus:** Extra roll for reaching final home? Proposed: yes.
5. **Safe cells:** Use standard marked safe cells, including each player's entry cell and star-marked cells according to the chosen board layout? Proposed: yes; exact cell indexes will be defined with board geometry.
6. **2–4 player end condition:** Classic 2-player winner-takes-all; 3–4 player mode can continue for placements? Proposed: configurable by mode.

These decisions must be settled before coding the engine so tests describe one unambiguous behavior.


## 16. Team Up mode — confirmed product rules

Team Up is a separate 2-vs-2 variant. These rules must not alter Classic mode.

### Teams and fixed scheduled order

- **Team A:** Orange + Magenta.
- **Team B:** Green + Blue.
- Scheduled seat order is always **Orange → Green → Magenta → Blue → repeat**.
- The scheduled order never changes, even when a player finishes all four pawns.

### Friendly stacks and opposing stacks

- Teammates are friendly regardless of pawn colour. Orange and Magenta are friendly; Green and Blue are friendly.
- Friendly teammate pawns may share a cell and form a friendly stack. They never capture one another.
- Opposing teams can interact under the Team Up stack-capture rule.
- Safe cells protect every pawn, including opposing-team pawns; no capture occurs on a safe cell.
- For a non-safe cell with a mixed opposing-team encounter, the last-arriving pawn/stack has capture priority. Initially, all occupants may remain present. If a pawn from the protected opposing stack leaves and the last-arriving side remains, the remaining opposing pawn(s) are captured immediately and returned to their yard. If the last-arriving side leaves first, the earlier stack remains.
- Equal-sized opposing stacks use the same last-arrival priority: the last-arriving stack wins and the opposing stack is returned to its yard.
- Capture priority and stack membership must be represented in domain state/events, not inferred from animation positions. Every colour combination must use team membership, not hard-coded colour-specific capture logic.
- The exact lifecycle for stacks with more than two opposing occupants must be covered by engine tests before the mode is marked gameplay-ready.

### Dice-turn transfer for a finished player

A player who has all four pawns in final home still has their scheduled dice roll. The result is transferred to their teammate for that teammate to use. The fixed scheduled seat order remains unchanged.

- When Orange has finished all four pawns, Orange's scheduled roll is transferred to Magenta.
- When Magenta has finished all four pawns, Magenta's scheduled roll is transferred to Orange.
- When Green has finished all four pawns, Green's scheduled roll is transferred to Blue.
- When Blue has finished all four pawns, Blue's scheduled roll is transferred to Green.
- A teammate receives both their own scheduled rolls and rolls transferred by their finished teammate.
- A six's bonus roll is transferred to the same receiving teammate and follows the same bonus-roll rules. Transfer does not itself advance or reorder the scheduled seats.
- If both teammates have finished all four pawns, there is no eligible recipient and that scheduled roll is skipped normally.
- The match ends immediately when either team has all eight pawns in final home.

### Team victory

- Team A wins only when all four Orange pawns and all four Magenta pawns are finished.
- Team B wins only when all four Green pawns and all four Blue pawns are finished.
- Finishing one player's four pawns is not a team victory; it activates the teammate roll-transfer rule.

### Team Up acceptance tests

| ID | Scenario | Expected result |
|---|---|---|
| TEAM-001 | Orange and Magenta occupy the same non-safe cell | Friendly stack; no capture |
| TEAM-002 | Green and Blue occupy the same non-safe cell | Friendly stack; no capture |
| TEAM-003 | Orange meets Green or Blue on a safe cell | All pawns are protected |
| TEAM-004 | Opposing pawn arrives on a non-safe cell occupied by a stack | Arrival priority is recorded; occupants are not prematurely removed |
| TEAM-005 | A pawn from the earlier opposing stack leaves first | Remaining pawn(s) from that stack are captured immediately if the last-arriving side remains |
| TEAM-006 | Last-arriving pawn/stack leaves first | Earlier stack remains |
| TEAM-007 | Equal-sized opposing stacks meet | Last-arriving stack wins according to the documented priority |
| TEAM-008 | Orange has finished all four pawns and Orange's scheduled turn arrives | Orange rolls; result is assigned to Magenta |
| TEAM-009 | Green has finished all four pawns and Green's scheduled turn arrives | Green rolls; result is assigned to Blue |
| TEAM-010 | Transferred roll is a six | Bonus roll transfers to the same recipient |
| TEAM-011 | Both Orange and Magenta have finished | Orange and Magenta scheduled turns have no recipient and are skipped |
| TEAM-012 | All Orange and Magenta pawns are finished | Team A wins immediately |
| TEAM-013 | Only one Team A player has finished | Team A has not won |
| TEAM-014 | Classic mode uses the existing profile | Team Up transfer/stack rules do not affect Classic |
| TEAM-015 | Any colour combination from opposing teams meets | Same team-based rule is applied; no colour-specific special case |

The local Team Up mode is now integrated into the game-mode selection screen and local gameplay UI. The engine stores last-arrival priority in immutable `LocalGameState.teamUpCapturePriorityByCell`, validates mixed-stack state, resolves protected-stack departures and equal-sized stacks, and emits capture events for every pawn returned to its yard. Engine acceptance tests cover the TEAM-001–TEAM-015 behavior, including stacks with more than two occupants, both team victories, bonus-roll transfer, and Classic isolation. Team Up remains local-only; the shared board route is still provisional and must pass visual/topology approval before the mode can be considered release-ready. Online/server-authoritative play remains future work.

## 15. Scope and next step

This document remains the rules specification. A provisional profile and part of the local engine are implemented, but the full acceptance matrix is not yet executable and board topology is not approved. Next, expand classic 52-cell route tests and convert compatibility string events to typed event payloads before connecting the visual board.

**Brand consistency:** The board renderer and HUD must use the approved Ludo Lovers palette exactly: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`, gold `#FFD700`, red `#FF3830`, black `#080B0B`, and cream `#FFF8E1`. The existing official logo remains unchanged.
