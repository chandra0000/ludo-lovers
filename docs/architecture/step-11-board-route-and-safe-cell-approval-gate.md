# Step 11 — Board route and safe-cell approval gate

## Current decision

**Status: NOT APPROVED for release gameplay.** The local board-backed match is an integration prototype only. Keep `ClassicLudoBoardCoordinateFactory.isGameplayReady` false until a human-reviewed board-cell reference is reconciled with the code and the acceptance tests pass.

The public Ludo King website is useful as general product context, but it is not a sufficiently precise cell-by-cell specification for this original Ludo Lovers board. Do not infer exact cell IDs or copy artwork from a marketing screenshot.

## Known blockers

- The current 52-cell loop contains non-orthogonal transitions at indexes **4, 17, 30 and 43**.
- Player start markers and entry offsets are provisional.
- The current safe-cell IDs `{0, 8, 13, 21, 26, 34, 39, 47}` are provisional metadata, not approved rules.
- The route, start cells, home-lane entry points and safe-cell treatment must be reviewed together. Fixing only the four diagonal transitions could silently shift cell indexes and invalidate entry offsets, capture rules, and safe-cell IDs.

## Approval checklist

1. **Lock the visual reference.** Use the original Ludo Lovers board artwork or a deliberately authored 15×15 cell diagram. Confirm the orientation: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
2. **Number every shared-track cell.** Record the exact 52-cell clockwise route in `(column, row)` coordinates. Every adjacent pair, including cell 51 back to cell 0, must be Manhattan distance 1.
3. **Reconcile seat entries.** For all four seats, verify that the entry index, rendered start marker, first main-track step, and route-relative progress describe the same square.
4. **Reconcile home lanes.** Confirm the six cells for each lane are consecutive, unique, do not overlap the shared track, and connect to the correct final approach.
5. **Approve safe cells from rules, not appearance.** Record each safe square's track index and visual coordinate; confirm whether each is a start square or a star/marked square under the chosen Ludo Lovers rules. Decide explicitly how stacks and captures work on safe squares.
6. **Run acceptance tests.** Test all four seat routes, wraparound, entry, home-lane transition, exact finish, overshoot, captures, safe-cell protection, stacked pawns, and reset. Add a test for every approved safe square.
7. **Open the release gate only after review.** The route audit must have zero blockers, all approved coordinate fixtures must match, and `isGameplayReady` must be changed only in the same reviewed change as the verified route and tests.

## Engineering rules

- Never silently change safe-cell IDs just to make the audit green.
- Keep the route and safe-cell IDs in one source of truth; rendering, hit testing and rules must consume that same mapping.
- Keep local match available as a clearly labelled development prototype while the gate is closed.
- Online/competitive matches must remain disabled until the route and rules are approved and server-authoritative state is implemented.

## Current next action

Obtain or create a clean board reference with visible cell boundaries and confirm the intended safe squares. Until then, keep the provisional route and safe-cell warning visible; a structurally passing test alone does not constitute visual approval.
