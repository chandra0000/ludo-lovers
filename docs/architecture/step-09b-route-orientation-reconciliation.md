# Step 09B — Route Orientation Reconciliation

**Status:** Provisional route and shared coordinate map implemented; visual/rules approval and engine migration remain outstanding.

## Implemented in this increment

- Extended `ClassicLudoBoardDefinition` with immutable grid-cell anchors for each player's home lane and start marker.
- Preserved the approved quadrant/color order: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
- Added `ClassicLudoBoardCoordinateFactory` with 52 unique 15×15 shared-track cells and normalized coordinates for the private lanes.
- Updated `ClassicLudoBoardPainter` to render the shared-track cells from the same coordinate map.
- Reconciled the provisional physical start markers with route indexes: Orange 0, Green 13, Magenta 26, Blue 39. This mapping is still provisional pending visual/rules review.
- Added tests for route length/uniqueness/bounds, route adjacency and wraparound, normalized coordinate coverage, responsive pixel scaling, start-marker alignment, seat colors and lane IDs.
- Kept safe-cell IDs and player entry offsets explicitly provisional; they are not approved online gameplay rules.

## Why the canonical coordinate route is still a separate task

The supplied composite reference is a visual/style reference, not a clean cell-by-cell board diagram. A conventional 52-cell route has now been added as a provisional coordinate source so the renderer and tests can share one mapping. It has not yet been visually approved against the reference, and the local-game engine fixture still needs migration/reconciliation before the route can be treated as production gameplay geometry.

## Next implementation increment

Next, validate the provisional route against a clean board reference and then migrate the local-game fixture to this shared source. Keep these concepts separate:

1. **Visual seat:** quadrant, yard, color and home-lane direction.
2. **Shared physical track:** coordinate IDs 0–51.
3. **Player start:** physical track ID where that player's pawn enters.
4. **Player-relative progress:** movement index translated through the player's start ID.
5. **Safe-cell metadata:** chosen rules profile checked against the board layout.

When the route is approved, update the local-game fixture and movement tests together so rendering, movement, captures and hit-testing share the same source of truth.

## Acceptance criteria

- All 52 physical track cells are unique and connected, including wraparound.
- Four start cells are distinct and align with the four visual quadrants.
- Each player's six-cell home lane points inward to the central finish.
- Safe cells and start-cell safety are explicit, tested rules metadata.
- Painter consumes the shared track coordinate map; lane anchors are centralized in the seat definition.
- Existing movement tests remain green after fixture migration.
- Visual comparison against the supplied reference is recorded as a manual review; CI alone cannot prove visual fidelity.

## CI context

The latest previously confirmed run #40 passed analysis, automated tests and Android debug APK build. New code commits trigger fresh validation. A passing CI build does not represent physical-device installation or visual approval.
