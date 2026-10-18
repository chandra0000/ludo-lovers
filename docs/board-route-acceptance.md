# Ludo Lovers board-route acceptance checklist

## Status

**Not approved for gameplay or competitive use.** The route and safe-cell mapping are provisional. Keep `ClassicLudoBoardCoordinateFactory.isGameplayReady` false until a straight-on board reference is reviewed and the acceptance checks below pass.

This checklist deliberately records the current defects without guessing which grid cells should replace them. The current board art/reference does not provide enough cell-by-cell evidence to safely infer those corrections.

## Independent reference cross-check (2026-10-18)

A read-only comparison against the public `rojanparajuli/Flutter_ludo` board constants found that its 52-cell shared-track sequence, start indexes `0, 13, 26, 39`, and safe-cell indexes `0, 8, 13, 21, 26, 34, 39, 47` match this repository's current values when row/column coordinates are normalized. Reference: https://github.com/rojanparajuli/Flutter_ludo/blob/master/lib/constant/board_constants.dart

This is useful corroboration, not approval to enable gameplay: the reference uses a different home-stretch/finish indexing model (five shared-to-center stretch cells plus a separate finished position), while this app previously modelled six physical home-lane cells. The user has confirmed the intended convention: five coloured home-lane cells plus a separate centre finish, and the board definition, logical path lengths, and tests now use that model. The remaining approval blocker is visual confirmation of the shared-track corner connections, entry orientation, and safe-cell placement before changing the release gate. Do not copy third-party code into this repository.

The four diagonal coordinate transitions listed below also occur in that reference sequence. They may represent intentional corner connections rather than incorrect route order; review the rendered cell/track artwork before deciding whether the geometry audit should permit these specific transitions. Keep `isGameplayReady` false until the entire visual route, home-lane model, and rules profile are reconciled and tested.

## Known shared-track discontinuities

The current 52-cell loop has four non-orthogonal transitions:

| From index | From coordinate (column, row) | To index | To coordinate (column, row) | Required review |
| ---: | --- | ---: | --- | --- |
| 4 | (5, 6) | 5 | (6, 5) | Confirm the intended track cell sequence around the upper-left turn. |
| 17 | (8, 5) | 18 | (9, 6) | Confirm the intended track cell sequence around the upper-right turn. |
| 30 | (9, 8) | 31 | (8, 9) | Confirm the intended track cell sequence around the lower-right turn. |
| 43 | (6, 9) | 44 | (5, 8) | Confirm the intended track cell sequence around the lower-left turn. |

Do not simply remove these diagnostics or mark the route ready. A valid replacement must be consistent with the actual board cells and every seat-relative route.

## Acceptance checklist

- [ ] Obtain/review a clear, straight-on board image or annotated cell-by-cell reference.
- [ ] Confirm the shared-track order clockwise or counter-clockwise, including all four corners.
- [ ] Confirm the exact entry/start cell and direction for orange, green, blue, and magenta.
- [ ] Confirm each private home lane's five physical cells and the separate centre finish position.
- [ ] Confirm all safe cells against the same reference and the chosen written rules profile.
- [ ] Verify the shared track has exactly 52 unique cells, all inside the 15×15 grid.
- [ ] Verify every consecutive shared-track pair, including index 51 back to 0, is orthogonally adjacent.
- [ ] Verify home lanes do not overlap the shared track or one another and connect to their intended final route cell.
- [ ] Verify each player-relative path is a rotation of the same shared physical track and enters the correct private lane.
- [ ] Run board geometry, route mapping, movement, safe-cell, capture, finish, and board-backed widget acceptance tests.
- [ ] Review any intentional rule differences (safe squares, capture stacks, six bonus, exact finish) and document the selected rule profile.
- [ ] Only after all evidence and tests agree, deliberately update the release gate and its tests.

## Current engineering safeguards

- The logical movement engine remains pure Dart and separate from Flutter presentation.
- The route geometry audit reports the four known diagonal transitions.
- Local Game Lab / board-backed UI remains a development prototype and visibly warns that route and safe cells are provisional.
- No online multiplayer, server-authoritative dice, or release-ready gameplay is claimed by this document.
