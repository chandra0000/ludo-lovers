# Ludo Lovers board-route acceptance checklist

## Status

**Not approved for gameplay or competitive use.** The route and safe-cell mapping are provisional. Keep `ClassicLudoBoardCoordinateFactory.isGameplayReady` false until a straight-on board reference is reviewed and the acceptance checks below pass.

This checklist deliberately records the current defects without guessing which grid cells should replace them. The current board art/reference does not provide enough cell-by-cell evidence to safely infer those corrections.

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
- [ ] Confirm each private home lane's six physical cells and finish position.
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
