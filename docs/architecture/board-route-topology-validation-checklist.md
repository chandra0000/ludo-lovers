# Board Route and Topology Validation Checklist

Last reviewed: 2026-10-21  
Branch: `main`

## Current decision

**Status: structurally consistent, but not approved for gameplay/release yet.**

The canonical route currently has 52 unique in-bounds cells and closes its loop. Automated structural and route-movement tests cover the documented route shape, player-relative progress, wraparound, home lanes, provisional safe cells, and the separate center finish. The route intentionally retains four diagonal corner transitions at indexes **4, 17, 30, and 43**. These are documented as the current v1 reference-board connections; they are not being silently converted to orthogonal steps because doing so can change the board's cell count, player entry spacing, and visual alignment.

The source explicitly keeps `isVisualTopologyApproved = false` and `isGameplayReady = false`. That is correct until the rendered board is reconciled with the approved visual reference and the user signs off on it. A passing structural test is not the same as proof that every route cell matches the artwork.

## Verified in source / current CI observation

- [x] One canonical 52-cell shared-track definition.
- [x] Four player entries: Orange 0, Green 13, Magenta 26, Blue 39.
- [x] Track coordinates are unique and inside the 15×15 board grid.
- [x] Four documented diagonal transitions only: 4→5, 17→18, 30→31, 43→44.
- [x] Five unique, consecutive home-lane cells per player; lanes do not overlap each other or the shared track.
- [x] Provisional safe-cell set is in range and matches the current profile: 0, 8, 13, 21, 26, 34, 39, 47.
- [x] Center finish is separate from the shared track and home lanes.
- [x] Blue wraparound and home-lane movement have explicit assertions.
- [x] Gameplay readiness remains blocked pending visual approval.
- [x] Latest observed CI run #499: formatting, dependency resolution, Flutter analysis, and automated tests passed. Android debug APK build was still running at the time of this review; full pipeline success is **not yet confirmed**.

## Remaining checklist — complete in this order

### 1. Compare the actual board rendering to the approved reference
- [ ] Use the exact approved board image as the visual source of truth (not a generic Ludo board).
- [ ] Compare every track cell in order, starting at Orange's entry and following the loop.
- [ ] Confirm whether the four diagonal corner transitions are genuinely present in the approved artwork. Record the decision explicitly.
- [ ] Check that the rendered route cells, colored start markers, star/safe markers, and pawn centers align with the actual artwork at phone aspect ratios.
- [ ] Confirm all four player quadrants and exact brand colors: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.

### 2. Resolve route orientation and entry mapping
- [ ] Confirm each player's forward direction and the first cell entered after leaving its yard.
- [ ] Confirm the entry spacing and route orientation against the reference; do not change entry indexes based on appearance alone.
- [ ] Confirm the final shared-track approach connects to the correct player's own home lane, especially Blue's wraparound path.
- [ ] Keep route/seat/home-lane/safe-cell metadata in the single canonical source; remove duplicate mappings if discovered.

### 3. Confirm rule metadata
- [ ] Verify all safe/star cells against the approved board and the selected Ludo rules profile.
- [ ] Confirm whether each player entry is safe in this rules profile.
- [ ] Verify capture protection on safe cells and capture behavior on ordinary cells using engine tests.
- [ ] Confirm the five-cell home-lane length and exact-finish/overshoot policy against the selected rules profile.

### 4. Required automated acceptance tests
- [x] Exactly 52 unique shared-track cells, all in bounds.
- [x] Loop closure and permitted-neighbour transition audit.
- [x] Exact player entry indexes and marker-to-route agreement.
- [x] Per-player intermediate movement cells, including wraparound.
- [x] Home-lane continuity, uniqueness, bounds, and non-overlap.
- [x] Provisional safe-cell IDs in range and resolvable.
- [x] Finish-cell separation and readiness-gate tests.
- [ ] Add/adjust golden coordinate assertions only after the visual comparison is signed off.
- [ ] Add a widget/rendering test proving pawn centers align to the canonical cell centers for all four colors.
- [ ] Re-run all board tests and the full Flutter pipeline after any route change.

### 5. Release gate
- [ ] User approves the board preview against the exact reference.
- [ ] Visual topology approval flag is changed only after that approval.
- [ ] Gameplay readiness stays false until topology and rules are approved and the integrated local match flow passes.
- [ ] Confirm the full CI run passes formatting, dependencies, analysis, all tests, Android debug APK build, and artifact upload.

## Board-related test files

- `apps/mobile/test/features/game/domain/board/classic_ludo_board_visual_topology_contract_test.dart`
- `apps/mobile/test/features/game/domain/board/reference_board_route_movement_test.dart`
- `apps/mobile/test/features/game/domain/board/classic_ludo_release_gate_test.dart`
- `apps/mobile/test/features/game/domain/board/provisional_safe_square_contract_test.dart`
- `apps/mobile/test/features/game/domain/board/board_gameplay_readiness_gate_test.dart`

## Guardrails

- Do not mark the topology gameplay-ready just because structural tests pass.
- Do not replace the four diagonal transitions with orthogonal cells without reconciling the result against the exact board reference and re-running route, entry, safe-cell, and pawn-animation tests.
- Keep changes small and on `main`, and keep CI green.
