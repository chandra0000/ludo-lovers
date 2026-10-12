# Step 08 — Board Geometry and Rendering Plan

**Status:** Board-coordinate foundation added; final route coordinates and Flame renderer are not implemented yet. The coordinate model and unit tests are committed, and CI validation is pending for these latest changes.

## Goal

Build an original Ludo Lovers board that is visually clear, touch-friendly, and faithful to the selected Ludo rules. Keep the rules model separate from pixel layout and animation.

## Geometry contract

- Use a logical 15 × 15 grid for the classic four-player board presentation.
- Model the shared perimeter as 52 ordered track positions for the selected classic ruleset.
- Model each player's private home lane as six progress positions, with the final center/home destination represented as a finish state rather than a capturable shared-track cell.
- Define each player's route as a player-relative ordered list of track indexes, followed by that player's private lane positions.
- Define a separate renderer mapping from each logical track/lane position to a normalized board coordinate. Do not use pixel coordinates in the game engine. A first pure-Dart mapping model now lives at `apps/mobile/lib/features/game/domain/board/board_coordinate_layout.dart`; it validates normalized coordinates and converts them to pixels for a supplied board size.
- Keep safe-cell indexes, starting cells, entry cells, home lanes, and finishing behavior in a single board-rules fixture. Do not scatter these constants through widgets or animation code.
- The 52-track/six-lane layout is the intended classic target and must be checked against the approved Ludo Lovers board design and the exact selected rule variant before gameplay is enabled.

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
- Coordinate model unit tests are in `apps/mobile/test/features/game/domain/board/board_coordinate_layout_test.dart`. Add rendering tests for square sizing, orientation, pawn overlap, and destination highlights when the Flame board renderer is introduced.
- Keep the 8-cell paths in current engine tests as synthetic fixtures only; they are not production board geometry.
- Do not enable online gameplay until the authoritative server uses the same versioned rules definition.

## Acceptance checklist

- [ ] Four verified route fixtures for the chosen ruleset.
- [ ] Safe cells and player starts cross-checked with the board art.
- [ ] Layout maps logical positions to normalized coordinates.
- [ ] Board scales to supported phone sizes without clipping.
- [ ] Pawns and selectable destinations remain distinguishable.
- [ ] Engine tests and rendering tests pass in CI.
- [ ] Existing logo is used as-is after its actual asset path is confirmed.
