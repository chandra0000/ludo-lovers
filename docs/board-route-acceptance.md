# Ludo Lovers board-route acceptance checklist

## Status

**Structural route validation implemented; visual/gameplay approval still blocked.** The project owner confirmed safe/star IDs `{0, 8, 13, 21, 26, 34, 39, 47}`. Keep `ClassicLudoBoardCoordinateFactory.isGameplayReady` false until a fresh phone screenshot confirms the rendered route and pawn centers match the approved board reference.

This checklist deliberately records the current defects without guessing which grid cells should replace them. The current board art/reference does not provide enough cell-by-cell evidence to safely infer those corrections.

## Independent reference cross-check (2026-10-18)

A read-only comparison against the public `rojanparajuli/Flutter_ludo` board constants found that its 52-cell shared-track sequence, start indexes `0, 13, 26, 39`, and safe-cell indexes `0, 8, 13, 21, 26, 34, 39, 47` match this repository's current values when row/column coordinates are normalized. Reference: https://github.com/rojanparajuli/Flutter_ludo/blob/master/lib/constant/board_constants.dart

This is useful corroboration, not approval to enable gameplay. The selected Ludo Lovers convention is five coloured home-lane cells plus a separate centre finish. The route fixture now traverses all 52 shared cells before entering the private lane, and tests lock each player-relative path. The project owner confirmed safe/star IDs. Remaining approval blocker: inspect a fresh on-device rendering for cell-center alignment and clipping before changing the release gate. Do not copy third-party code into this repository.

The four diagonal coordinate transitions listed below also occur in that reference sequence. The geometry audit now treats exactly these four one-cell diagonal corner links as structurally valid, while reporting any other non-neighbour transition as a defect. The four corner links are structurally locked. Each player also branches diagonally from its final shared cell into its own home lane after traversing all 52 cells. This is structural validation only: `isGameplayReady` remains false behind `isVisualTopologyApproved` until the rendered board is checked on-device.

## Known diagonal corner transitions

The current 52-cell loop has four non-orthogonal transitions:

| From index | From coordinate (column, row) | To index | To coordinate (column, row) | Required review |
| ---: | --- | ---: | --- | --- |
| 4 | (5, 6) | 5 | (6, 5) | Structurally locked; verify visual alignment on-device. |
| 17 | (8, 5) | 18 | (9, 6) | Structurally locked; verify visual alignment on-device. |
| 30 | (9, 8) | 31 | (8, 9) | Structurally locked; verify visual alignment on-device. |
| 43 | (6, 9) | 44 | (5, 8) | Structurally locked; verify visual alignment on-device. |

Do not simply remove these diagnostics or mark the route ready. The listed transitions are retained as diagnostic review points, not presumed defects. A valid route must remain consistent with the actual board cells and every seat-relative route.

## Acceptance checklist

- [ ] Obtain/review a clear, straight-on board image or annotated cell-by-cell reference.
- [ ] Confirm the shared-track order clockwise or counter-clockwise, including all four corners.
- [ ] Confirm the exact entry/start cell and direction for orange, green, blue, and magenta.
- [ ] Confirm each private home lane's five physical cells and the separate centre finish position.
- [x] Safe/star cell IDs confirmed by the project owner: 0, 8, 13, 21, 26, 34, 39, 47. Keep rule semantics local-prototype-only until the rules profile is formally locked.
- [x] Add acceptance tests for exactly 52 unique shared-track cells inside the 15×15 grid.
- [x] Add acceptance tests for every consecutive shared-track pair, including wraparound and the four explicitly validated diagonal corner connections.
- [x] Add acceptance tests for lane uniqueness, non-overlap, continuity, and the final shared-cell-to-lane connection.
- [x] Add acceptance tests that each player-relative path traverses all 52 physical shared cells exactly once, then enters its own lane at progress 52.
- [ ] Run board geometry, route mapping, movement, safe-cell, capture, finish, and board-backed widget acceptance tests.
- [ ] Review any intentional rule differences (safe squares, capture stacks, six bonus, exact finish) and document the selected rule profile.
- [ ] Only after all evidence and tests agree, deliberately update the release gate and its tests.

## Current engineering safeguards

- The logical movement engine remains pure Dart and separate from Flutter presentation.
- The route geometry audit validates all 52 player-relative steps, the four known diagonal corner connections, home-lane branches, entries, safe-cell IDs, and rejects other non-neighbour transitions; the visual-approval release gate remains closed.
- Local Game Lab / board-backed UI remains a development prototype and visibly warns that route and safe cells are provisional.
- No online multiplayer, server-authoritative dice, or release-ready gameplay is claimed by this document.
