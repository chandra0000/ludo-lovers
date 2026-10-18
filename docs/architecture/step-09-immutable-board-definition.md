# Step 09 — Immutable Board Definition

**Status:** Implemented as a metadata foundation; route coordinates and final gameplay mapping remain pending.

## What this increment establishes

- One typed, immutable definition of the four visible seats and their quadrants.
- Exact reference palette: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.
- Required quadrant order: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
- Separate yard-zone grid origins and five-cell private-lane ID ranges plus a separate center-finish state.
- Validation for unique seats, in-bounds 6×6 yard zones, distinct home-lane IDs, and safe-cell IDs within the shared track.

## Deliberate limits

This is not yet the coordinate map. It does not claim the current safe-cell list or route offsets have been visually approved. The existing design reference is a composite rather than a clean board-only asset, so cell centers and exact route adjacency must not be guessed from it. The current painter is still a visual prototype and does not consume this definition yet.

## Next

1. Agree the exact 15×15 route/start/safe-cell mapping against a clean board reference.
2. Add normalized cell-center coordinates and route adjacency validation.
3. Render the painter from the shared definition/coordinate map.
4. Add visual widget tests, then connect pawns to engine progress only after the mapping is verified.
