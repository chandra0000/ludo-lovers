# Step 09B — Route Orientation Reconciliation

**Status:** Provisional shared route and explicit home-lane coordinate map implemented. A strict readiness guard now blocks gameplay use because four transitions are diagonal; visual/rules approval and engine migration remain outstanding.

## Implemented in this increment

- Extended `ClassicLudoBoardDefinition` with immutable grid-cell anchors for each player's home lane and start marker.
- Preserved the approved quadrant/color order: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
- Added `ClassicLudoBoardCoordinateFactory` with 52 provisional 15×15 shared-track cells and normalized coordinates for the private lanes.
- Defined each six-cell home lane explicitly as grid-cell centers rather than interpolating between endpoints.
- Updated `ClassicLudoBoardPainter` to render shared-track and home-lane cells from the same coordinate map.
- Added value equality for grid cells so uniqueness and overlap tests compare coordinates rather than object identity.
- Added tests for home-lane bounds, unique cells and separation from the shared track.
- Reconciled the provisional physical start markers with route indexes: Orange 0, Green 13, Magenta 26, Blue 39. This mapping is still provisional pending visual/rules review.
- Added tests for route length/uniqueness/bounds, route adjacency and wraparound, normalized coordinate coverage, responsive pixel scaling, start-marker alignment, seat colors and lane IDs. The route audit explicitly identifies diagonal transitions at indexes 4, 17, 30 and 43; these are now a tested gameplay-readiness blocker.
- Kept safe-cell IDs and player entry offsets explicitly provisional; they are not approved online gameplay rules.

## Route audit finding — do not migrate to gameplay yet

The 52-cell route has four diagonal jumps at transition indexes 4, 17, 30 and 43. The existing adjacency test only proves that cells touch, not that a pawn follows orthogonal cell-to-cell movement. `ClassicLudoBoardCoordinateFactory.isGameplayReady` therefore remains false. This is intentional: do not wire this route into the local game engine, hit-testing, capture rules, or online rules until a reviewed 52-cell orthogonal route replaces it and the tests are updated.

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
