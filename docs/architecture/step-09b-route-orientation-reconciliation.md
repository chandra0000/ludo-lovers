# Step 09B — Route Orientation Reconciliation

**Status:** Provisional shared route, explicit home-lane coordinate map, structural geometry audit, and reusable hit-testing implemented. Gameplay remains blocked until the route is reviewed against the approved board-cell topology and rules.

## Implemented in this increment

- Extended `ClassicLudoBoardDefinition` with immutable grid-cell anchors for each player's home lane and start marker.
- Preserved the approved quadrant/color order: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.
- Added `ClassicLudoBoardCoordinateFactory` with 52 provisional 15×15 shared-track cells and normalized coordinates for the private lanes.
- Defined each six-cell home lane explicitly as grid-cell centers rather than interpolating between endpoints.
- Updated `ClassicLudoBoardPainter` to render shared-track and home-lane cells from the same coordinate map.
- Added value equality for grid cells so uniqueness and overlap tests compare coordinates rather than object identity.
- Added tests for home-lane bounds, unique cells and separation from the shared track.
- Added `ClassicLudoBoardGeometryAudit` to check track length, uniqueness/bounds, connected neighboring coordinates (touching cells), distinct entry indexes, start-marker alignment, home-lane ordering/continuity, home-lane bounds/overlap, unique logical lane IDs and provisional safe-cell ranges.
- Added `BoardPawnPositionResolver`, an adapter from the existing local-engine `PawnRoutePosition` plus `LudoBoardPaths` to the renderer's logical cell IDs. It validates section/progress consistency and confirms that a coordinate exists; it does not determine move legality or make the provisional route gameplay-ready.
- Added resolver tests for player-relative track offsets, home-lane mapping, yard/finished positions and invalid progress.
- Reconciled the provisional physical start markers with route indexes: Orange 0, Green 13, Magenta 26, Blue 39. This mapping is still provisional pending visual/rules review.
- Added tests for route length/uniqueness/bounds, route adjacency and wraparound, normalized coordinate coverage, responsive pixel scaling, start-marker alignment, seat colors and lane IDs. The route audit explicitly identifies diagonal transitions at indexes 4, 17, 30 and 43; these are now a tested gameplay-readiness blocker.
- Kept safe-cell IDs and player entry offsets explicitly provisional; they are not approved online gameplay rules.

## Next reusable capability — coordinate hit-testing

`BoardCoordinateLayout.hitTest` now finds the nearest registered logical cell within a caller-supplied pixel radius. It validates input dimensions and touch values and returns null when the tap is outside the configured radius. This is a geometry utility only: it does not validate legal pawn moves or enable gameplay while the route remains provisional.

## Route audit finding — do not migrate to gameplay yet

The 52-cell route has four diagonal transitions at indexes 4, 17, 30 and 43. Existing adjacency tests prove only that consecutive grid positions touch; they do not establish that this is the correct physical path for the approved board. `ClassicLudoBoardCoordinateFactory.isGameplayReady` therefore remains false. Do not wire this route into pawn movement, capture rules, or online rules until the transitions are reconciled with a reviewed board-cell diagram. The final topology should follow the actual approved board design rather than assuming a diagonal is automatically invalid.

## Why the canonical coordinate route is still a separate task

The supplied composite reference is a visual/style reference, not a clean cell-by-cell board diagram. A conventional 52-cell route has now been added as a provisional coordinate source so the renderer and tests can share one mapping. It has not yet been visually approved against the reference, and the local-game engine fixture still needs migration/reconciliation before the route can be treated as production gameplay geometry.

## Next implementation increment

Next, validate the provisional route against a clean board reference and then migrate the local-game fixture to this shared source. The structural audit and pawn-position adapter are now implemented, but the adapter should only be used with routes whose geometry has been reviewed. The structural audit catches internal inconsistencies automatically, but it cannot prove visual fidelity or decide the intended rules. Keep these concepts separate:

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

The latest previously confirmed run #40 passed analysis, automated tests and Android debug APK build. New code commits trigger fresh validation. Run #60 passed the Flutter checks and automated tests, Android debug APK build, and artifact upload for its commit. The structural-audit commits that follow will trigger a new CI run. A passing CI build does not represent physical-device installation or visual approval.


## Pawn presentation layout scaffold

Added `BoardPawnLayout` as a presentation adapter for the next rendering increment. It maps player-relative main-track progress to the seat's provisional physical track entry, maps home-lane progress to the player's logical lane IDs, assigns four distinct yard slots, and places finished pawns at the center. It preserves a stack index for later multi-pawn offsets and validates malformed positions.

Automated tests cover orange/green track entries, home-lane mapping, four distinct yard slots, center finish, invalid inputs, and the gameplay-readiness guard. This is still a **presentation scaffold**, not a connected live pawn renderer. Because the 52-cell route remains provisional, do not use this layout for release gameplay until the board topology is visually reviewed and the local-engine route fixture is reconciled.


## Current status update — 2026-10-15

- Pipeline #84 passed for commit `1875c35b8f15eb19a05093edf1be737d45446620`.
- Confirmed CI steps: dependency resolution, Dart/Flutter analysis, automated tests, Android debug APK build, and artifact upload all succeeded.
- The board-preview widget-finder regression is resolved by placing the stable test key on the square board container.
- This CI result does not remove the geometry blocker: the route still has diagonal transitions at indexes 4, 17, 30 and 43, and `isGameplayReady` remains false.
- Do not connect the provisional route to the local-game engine simply because CI is green.

## Next implementation gate — approve route before engine migration

Before changing movement rules, obtain or create a clean, straight-on board-cell reference with these visible:
1. The complete 52-cell shared track.
2. The four start cells and direction of travel.
3. The six home-lane cells for each color.
4. Safe cells and the entry-to-home transition.
5. The existing quadrant mapping: Orange top-left, Green top-right, Blue bottom-left, Magenta bottom-right.

Then reconcile the cell IDs against the reference, update the coordinate fixture and seat entry metadata together, and add tests for the approved transitions and start positions. Only after those checks pass should the local engine's route fixture be migrated. The board's current composite style reference is not enough to infer every cell-level rule safely.
