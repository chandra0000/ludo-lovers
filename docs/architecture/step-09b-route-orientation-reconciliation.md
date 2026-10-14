# Step 09B — Route Orientation Reconciliation

**Status:** In progress — shared visual anchors are centralized; canonical 52-cell route mapping remains outstanding.

## Implemented in this increment

- Extended `ClassicLudoBoardDefinition` with immutable grid-cell anchors for each player's home lane and start marker.
- Preserved the approved quadrant/color order: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
- Changed `ClassicLudoBoardPainter` to draw yards, home lanes and start markers from the shared seat definition instead of maintaining its own duplicate coordinates.
- Added tests for seat ordering/colors, unique home-lane IDs, unique provisional entry offsets and in-bounds visual anchors.
- Kept safe-cell IDs and player entry offsets explicitly provisional; they are not approved online gameplay rules.

## Why the canonical coordinate route is still a separate task

The supplied composite reference is a visual/style reference, not a clean cell-by-cell board diagram. The existing preview has illustrative lane/start anchors, and the local-game fixture uses offsets Orange 0, Blue 13, Green 26, Magenta 39. Those offsets have not yet been reconciled against a confirmed physical track. Inventing 52 coordinates and declaring them production-ready would risk mismatching pawn movement with the visible board.

## Next implementation increment

Create one canonical clockwise 52-cell coordinate route, then explicitly map each seat to its physical start cell. Keep these concepts separate:

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
- Painter consumes the canonical coordinate map; it has no duplicate start/lane anchors.
- Existing movement tests remain green after fixture migration.
- Visual comparison against the supplied reference is recorded as a manual review; CI alone cannot prove visual fidelity.

## CI context

The latest previously confirmed run #40 passed analysis, automated tests and Android debug APK build. New code commits trigger fresh validation. A passing CI build does not represent physical-device installation or visual approval.
