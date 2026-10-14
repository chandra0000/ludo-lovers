# Step 09 — Reference-Aligned Board Geometry Implementation Plan

**Status:** Planning contract added; coordinate mapping is not yet implemented.  
**Approved visual source:** `docs/product/approved-visual-reference-baseline.md` and the user-supplied Ludo Lovers design reference (received 2026-10-14).

## Recommendation

Implement the board as a tested 15×15 normalized coordinate map, but do not invent a cell-by-cell route from a low-resolution composite image. The supplied reference establishes the intended visual style and quadrant colors; it does not provide a clean, unoccluded board asset with a reliable cell grid. First use it as the visual acceptance reference, then encode a standard route only after its orientation and start/safe-cell rules have been reviewed.

## Reference orientation to preserve

- Top-left home quadrant: Orange `#FF8928`
- Top-right home quadrant: Green `#33FF28`
- Bottom-left home quadrant: Blue `#289EFF`
- Bottom-right home quadrant: Magenta `#F428FF`
- Center finish: premium gold/cream focal point on the dark/polished board.
- Shared track: readable 15×15 Ludo layout, with the classic cross-shaped home lanes.
- Keep the outer board square and responsive; all logical cell coordinates must be normalized to `0.0–1.0`.

**Important:** player turn order and visual quadrant order are separate concerns. Never infer that the current player-path list order is also the board's clockwise display order. The existing fixture uses path offsets for rules, while the reference has its own visible quadrant arrangement; the mapping must explicitly reconcile these.

## Required geometry model

The coordinate map must provide:
- All 52 shared-track cell IDs `0..51`.
- Six private-lane cells for each player: Orange `200..205`, Blue `210..215`, Green `220..225`, Magenta `230..235`.
- Each player's visible yard/token start areas separately from track cells (yard locations are not shared-track cells).
- Each player's track-entry/start cell and the safe-cell set as explicit, reviewed metadata.
- Normalized cell centers, not arbitrary corner coordinates, so token placement and hit-testing share one coordinate source.

## Acceptance tests before engine/render integration

1. Every required logical ID has exactly one coordinate.
2. All normalized coordinates are finite and within `[0, 1]`.
3. The 52 shared-track coordinates form the intended connected route with valid adjacency; wraparound from cell 51 to cell 0 is correct.
4. Home-lane coordinates connect to the correct player's entry cell and terminate at the central finish.
5. Each player start and each safe/star cell match the approved board orientation/rules profile.
6. No two unrelated cells occupy the same center; intentional shared center/finish visuals are represented separately rather than duplicate route IDs.
7. Pixel conversion is correct for multiple square sizes and device densities.
8. Pawn hit-testing, rendering and animation all consume this same coordinate map.
9. Tests assert quadrant color assignment: Orange TL, Green TR, Blue BL, Magenta BR.
10. Golden/widget visual review checks the rendered preview against the approved reference before gameplay is wired.

## Scope boundary

This work must not change the existing game rules or mark the board as playable. The current safe-cell IDs `{0, 8, 13, 21, 26, 34, 39, 47}` are provisional until the route orientation and rules profile are reconciled. Keep them clearly provisional in code/docs until review.

## Next coding sequence

1. Add a typed immutable board definition containing route IDs, home-lane IDs, quadrant positions, start IDs and safe-cell metadata.
2. Add an explicit coordinate-map factory for the reviewed 15×15 route.
3. Add adjacency, wraparound, quadrant, home-lane, duplicate-center and completeness tests.
4. Update the painter to draw from the same geometry definition rather than maintaining separate hand-drawn positions.
5. Add widget/golden validation and only then connect pawns to the engine.
