# Team Up (2 vs 2) — implemented local rules

Status: local-mode implementation and acceptance tests. This is not an online or release-approved mode while the shared board route remains provisional.

## Teams and turn order

- Team A: Orange + Magenta.
- Team B: Green + Blue.
- Scheduled seats repeat in this order: Orange → Green → Magenta → Blue.
- The scheduled seat remains distinct from the active player when a turn is transferred.
- If a scheduled player has finished all four pawns, that scheduled turn is received by their teammate, provided the teammate still has unfinished pawns.
- If both teammates have finished all four pawns, that team's scheduled turn is skipped.
- A six, capture bonus, or finish bonus remains with the active roll recipient. The scheduled seat does not advance until that recipient's turn ends.
- When a player finishes their fourth pawn but their teammate is not finished, any earned bonus roll transfers to the teammate.

## Shared-cell and capture rules

- A player cannot capture their own pawns.
- Teammates may share an unsafe cell; a teammate's pawn is never a capture target.
- Safe cells protect every pawn, including pawns from opposing teams.
- Teammate pawns may share a cell and are always friendly.
- On a non-safe cell with opposing teams, the last-arriving pawn/stack owns capture priority. The mixed occupants initially remain present and the priority team is stored in immutable game state by shared-track cell.
- If a pawn from the protected (earlier-arriving) team leaves while the priority team still occupies the cell, all remaining pawns from the protected team at that cell are captured and returned to their yard. The pawn that left is not captured.
- If the last-arriving priority team leaves the cell first, the earlier-arriving team remains and the priority record is removed.
- When opposing stacks become equal-sized after an arrival, the last-arriving team immediately wins the cell and all opposing pawns there return to their yard.
- These rules apply to stacks of more than two occupants; stack membership is calculated by team, not by colour or animation order.
- Capture events are emitted for each pawn returned to the yard. Capture bonus behavior continues to use the configured local rule profile.

## Victory

- Team A wins only after all four Orange pawns and all four Magenta pawns are finished.
- Team B wins only after all four Green pawns and all four Blue pawns are finished.
- Finishing one player's four pawns does not end the match if their teammate still has an unfinished pawn.
- The winning team and the final player to finish are both retained in match state for the results UI.

## Classic compatibility

- Classic remains the default factory mode and uses the `classic-v1-provisional` rule profile.
- Team Up uses the separate `team-up-v1-provisional` profile.
- Team Up capture filtering and scheduled-seat behavior are gated by the Team Up profile flag. Classic capture behavior and turn advancement remain on their original paths.
- The game-mode screen exposes Team Up as an explicit separate choice; it does not change the Classic selection.

## Acceptance coverage

The automated suite covers:
- fixed team assignments and alternating scheduled order;
- rejection of incomplete or incorrectly ordered Team Up seats;
- finished-seat transfer to the correct teammate;
- bonus-six retention by the active teammate and return to the next scheduled seat after the bonus ends;
- friendly teammate stacking, safe-cell protection, last-arrival priority persistence, protected-stack departure capture, priority-stack departure protection, equal-sized stack resolution, and stacks with more than two occupants;
- Team A and Team B victory, plus no premature victory while one teammate has an unfinished pawn;
- explicit Team Up navigation, team identity banner, and transferred-turn indicator;
- Classic factory profile and independent Classic turn advancement.

The Flutter CI workflow runs Dart formatting, dependency resolution, launcher-icon generation, Flutter analysis, all tests, Android debug APK build, and APK artifact upload. A green workflow validates the committed code and build; it does not approve the provisional board geometry or online/server-authoritative play.
