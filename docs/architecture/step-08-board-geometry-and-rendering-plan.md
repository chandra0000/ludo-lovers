# Step 08 — Board Geometry and Rendering Plan

**Status:** Initial canonical board fixture and route validation tests are now in place; the final board art and full movement integration still require validation against the approved Ludo Lovers board diagram before shipping gameplay.

## Goal

Build an original Ludo Lovers board that is visually clear, touch-friendly, and faithful to the selected Ludo rules. Keep the rules model separate from pixel layout and animation.

## Geometry contract

- Use a logical 15 × 15 grid for the classic four-player board presentation.
- Model the shared perimeter as 52 ordered track positions for the selected classic ruleset.
- Model each player's private home lane as six progress positions, with the final center/home destination represented as a finish state rather than a capturable shared-track cell.
- Define each player's route as a player-relative ordered list of track indexes, followed by that player's private lane positions.
- Define a separate renderer mapping from each logical track/lane position to a normalized board coordinate. Do not use pixel coordinates in the game engine.
- Keep safe-cell indexes, starting cells, entry cells, home lanes, and finishing behavior in a single board-rules fixture. Do not scatter these constants through widgets or animation code.
- The 52-track/six-lane layout is the intended classic target and must be checked against the approved board design and the exact selected rule variant before gameplay is enabled.

## Canonical fixture now in place

The project now includes a canonical four-player board fixture at:

`apps/mobile/lib/features/game/domain/board/classic_ludo_board_fixture.dart`

It defines the standard 52-cell shared track with four rotated player routes:

- orange starts at index 0
- blue starts at index 13
- green starts at index 26
- magenta starts at index 39

Each player also gets a six-cell private home lane, and the values are validated in:

`apps/mobile/test/features/game/domain/board/classic_ludo_board_fixture_test.dart`

This gives the project a consistent, testable route contract before the board renderer or UI is wired to gameplay.

## Suggested rendering layers

1. Board background and four home areas.
2. Shared-track cells and player-colored start/entry markers.
3. Private home lanes and center finish area.
4. Safe-cell markers.
5. Pawn layer.
6. Selection/valid-destination highlights.
7. Movement shadows and landing effects.
8. Flutter overlay for player status, turn, dice control, chat/emotes, menu, and connection state.

## Coordinate and animation rules

- Store normalized cell centers (0.0–1.0) or logical row/column coordinates in the board layout, not absolute device pixels.
- Derive cell size from available square constraints; support narrow phones, safe areas, and different aspect ratios.
- Pawns should remain readable at small sizes and must not obscure the cell's safe/start marker.
- For stacked pawns, use a deterministic offset layout and preserve hit targets for each pawn.
- Animate one logical step at a time. The renderer receives authoritative/local-engine transitions and never calculates whether a move is legal.
- A selected pawn highlights only destinations already returned by the game rules layer.
- Use the exact brand palette: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`, gold `#FFD700`, red `#FF3830`, black `#080B0B`, and cream `#FFF8E1`. Preserve the existing logo unchanged.

## Before connecting gameplay

- Verify all four ordered routes against the final board diagram.
- Verify route wrap-around, each player's start cell, safe cells, home entry, and home-lane order.
- Add geometry tests asserting that each route visits the expected shared-track indexes once and ends at the correct home lane.
- Coordinate model unit tests are in `apps/mobile/test/features/game/domain/board/board_coordinate_layout_test.dart`.
- Keep the route contract explicit and test-backed before UI integration.
- Do not enable online gameplay until the authoritative server uses the same versioned rules definition.

## Acceptance checklist

- [x] Canonical 52-cell shared-track fixture is defined for four players.
- [x] Route validations protect shared tracks from overlap and home-lane collisions.
- [ ] Verify the route fixture against the final board art and approved rule variant.
- [ ] Layout maps logical positions to normalized coordinates.
- [ ] Board scales to supported phone sizes without clipping.
- [ ] Pawns and selectable destinations remain distinguishable.
- [ ] Engine tests and rendering tests pass in CI.
- [ ] Existing logo is used as-is after its actual asset path is confirmed.
