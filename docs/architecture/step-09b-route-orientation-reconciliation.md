# Step 09B — Route Orientation Reconciliation

**Status:** Required before writing the production coordinate map.

## Why this checkpoint exists

The immutable board definition now preserves the requested visual quadrants:

- Orange — top-left
- Green — top-right
- Blue — bottom-left
- Magenta — bottom-right

The current local-game fixture uses track offsets Orange 0, Blue 13, Green 26, Magenta 39. Those offsets are not yet proven to match the approved visual orientation. The current painter's start markers are also illustrative, not authoritative route metadata. Building a coordinate map before resolving this would risk placing a player's legal route at another player's visible start.

## Decision for the next implementation increment

Create one canonical clockwise 52-cell coordinate route, then explicitly map each seat to its start cell. Keep these concepts separate:

1. **Visual seat:** quadrant, yard, color and home-lane direction.
2. **Shared physical track:** coordinate IDs 0–51.
3. **Player start:** the physical track ID where that player's pawn enters.
4. **Player-relative progress:** a movement index translated through the player's start ID.
5. **Safe-cell metadata:** derived from the chosen rules profile and checked against the approved board layout.

Do not assume that a player-list ordering or a plus-13 offset is automatically correct for the displayed quadrant order. When this mapping is implemented, update the fixture and tests together so movement, captures, rendering and hit-testing all share the same source of truth.

## Acceptance criteria

- All 52 physical track cells are unique and connected, including wraparound.
- The four start cells are distinct and align with the four visual quadrants.
- Each player's six-cell home lane points inward to the central finish.
- Safe cells and start-cell safety are explicit, tested rules metadata.
- The painter consumes the canonical coordinate map; it no longer owns separate hard-coded start positions.
- Existing movement tests remain green after the engine fixture is migrated.
- Visual comparison against the supplied reference is recorded as a manual review; CI alone cannot prove visual fidelity.

## Current CI context

Workflow run #40 passed after the missing Flutter import and const-lint fixes. Workflow #39 failed on its earlier commit and is superseded by #40 for the current source state. The passing workflow validates analysis, automated tests and Android debug APK build; it does not represent physical-device installation or visual approval.
