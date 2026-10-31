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
- Teammate pawns are excluded from capture candidates before the opponent-stack policy is applied.
- Team Up uses the existing configured local opponent-stack policy; it does not invent a new priority rule. With the default `captureOnlySingleOpponentPawn: true`, a single opposing pawn on an unsafe cell is captured, while a stack of multiple opposing pawns is protected. If a profile explicitly sets this flag to false, the existing profile behavior captures every opposing pawn in that stack.
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
- teammate protection and capture priority, opposing safe-cell protection, single-opponent capture, and protection of a multi-pawn opposing stack under the existing default policy;
- Team A and Team B victory, plus no premature victory while one teammate has an unfinished pawn;
- explicit Team Up navigation, team identity banner, and transferred-turn indicator;
- Classic factory profile and independent Classic turn advancement.

The Flutter CI workflow runs Dart formatting, dependency resolution, launcher-icon generation, Flutter analysis, all tests, Android debug APK build, and APK artifact upload. A green workflow validates the committed code and build; it does not approve the provisional board geometry or online/server-authoritative play.
