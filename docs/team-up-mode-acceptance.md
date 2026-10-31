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
- On an unsafe cell occupied by multiple opposing pawns, Team Up captures only the pawn with the greatest `lastMovedAtVersion` (the most recent arrival).
- If imported/test state gives multiple opposing pawns the same arrival version, pawn ID ascending is the deterministic tie-break.
- Captured pawns return to their own yard. Capture bonus behavior continues to use the configured local rule profile.

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
- teammate protection, opposing safe-cell protection, and last-arrival capture priority (including deterministic tie-break);
- Team A and Team B victory, plus no premature victory while one teammate has an unfinished pawn;
- explicit Team Up navigation, team identity banner, and transferred-turn indicator;
- Classic factory profile and independent Classic turn advancement.

The Flutter CI workflow runs Dart formatting, dependency resolution, launcher-icon generation, Flutter analysis, all tests, Android debug APK build, and APK artifact upload. A green workflow validates the committed code and build; it does not approve the provisional board geometry or online/server-authoritative play.
