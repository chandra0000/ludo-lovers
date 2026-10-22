# Board Route and Topology Validation Checklist

Last reviewed: 2026-10-21  
Branch: `main`

## Current decision

**Status: structural route audit and full 52-cell player traversal are implemented; safe/star IDs are confirmed by the project owner. Visual sign-off on the rendered board remains pending, so gameplay/release stays blocked.**

The canonical route has 52 unique in-bounds cells and closes its loop. Each player's movement route traverses 51 cells from the 52-cell physical loop, then turns directly into its own home lane and skips the outer corner `(entry + 51) % 52` beside the lane entrance. Automated structural and route-movement tests cover route shape, player-relative progress, wraparound, home lanes, owner-confirmed safe cells, and the separate center finish. The route intentionally retains four diagonal corner transitions at indexes **4, 17, 30, and 43**. These are documented as the current v1 reference-board connections; they are not being silently converted to orthogonal steps because doing so can change the board's cell count, player entry spacing, and visual alignment.

The supplied straight-on mockup (`1000545512.jpg`) shows the same four-player quadrant arrangement, central 3×3 hub, colored home lanes, and apparent travel orientation as the canonical coordinates. The four diagonal links are consistent with the turns around that central hub. The project owner has confirmed safe/star IDs `{0, 8, 13, 21, 26, 34, 39, 47}`. The mockup is still insufficient to prove pixel-perfect route-cell alignment at runtime. The app screenshots (`1000546499.jpg`, `1000546326.jpg`) are implementation evidence, not the target specification. Keep `isVisualTopologyApproved = false` and `isGameplayReady = false` until the rendered preview is checked on a phone.

## Verified in source / current CI observation

- [x] One canonical 52-cell shared-track definition.
- [x] Four player entries: Orange 0, Green 13, Magenta 26, Blue 39.
- [x] Track coordinates are unique and inside the 15×15 board grid.
- [x] Four documented diagonal transitions only: 4→5, 17→18, 30→31, 43→44.
- [x] Five unique, consecutive home-lane cells per player; lanes do not overlap each other or the shared track.
- [x] Provisional safe-cell set is in range and matches the current profile: 0, 8, 13, 21, 26, 34, 39, 47.
- [x] Center finish is separate from the shared track and home lanes.
- [x] Blue wraparound and home-lane movement have explicit assertions.
- [x] Cross-checked the four entry directions against the supplied straight-on board mockup: Orange moves right then up, Green down then right, Magenta left then down, Blue up then left.
- [x] Board Preview uses a square aspect ratio; the painter and pawn layer use the same normalized cell-center mapping on that square canvas.
- [x] Added an independent 52-coordinate acceptance fixture, explicit entry-direction and home-lane orientation checks, and a cell-center alignment test in `approved_reference_geometry_acceptance_test.dart`.
- [x] Added a widget rendering test that checks the preview canvas is square and preview pawn markers use canonical track-cell centres; this is automated canvas validation, not on-device visual sign-off.
- [x] Gameplay readiness remains blocked pending safe-cell visual approval.
- [x] CI run #512 passed formatting, dependency resolution, Flutter analysis, all automated tests, and Android debug APK build for commit `efe07db5e2de651b1ac2f5b0d8721e388de7ca5f`. This does not constitute visual sign-off or gameplay readiness.

## Remaining checklist — complete in this order

### 1. Compare the actual board rendering to the approved reference
- [x] Use the supplied straight-on board mockup as the geometry reference; treat Android runtime screenshots as implementation evidence only.
- [x] Compare the 52-cell canonical sequence with the 15×15 mockup's perimeter around the central hub; the broad route shape and quadrant orientation agree.
- [x] Confirm the four diagonal corner links at indexes 4, 17, 30, and 43 as the current intended connectors around the central 3×3 hub; independent golden tests now lock their endpoints.
- [x] Confirm the four quadrant colors and their forward directions against the mockup.
- [x] Record owner-confirmed safe/star IDs: `{0, 8, 13, 21, 26, 34, 39, 47}`.
- [ ] Manually inspect the rendered board preview on-device at phone size and confirm all route-cell and pawn centers visually align. This requires a fresh Android screenshot from the actual device; widget tests cannot verify device-specific clipping, scaling, or visual overlap.

### 2. Resolve route orientation and entry mapping
- [x] Confirm each player's forward direction and entry cell: Orange 0, Green 13, Magenta 26, Blue 39.
- [x] Confirm entry spacing and the 13-cell rotational separation in the shared-track mapping.
- [x] Confirm each final traversed shared cell connects to its own lane; Blue wraps through physical IDs 50, 51, 0; each player traverses final shared cell `(entry + 50) % 52` and enters its own home lane at progress 51, skipping `(entry + 51) % 52`.
- [x] Keep route/seat/home-lane/safe-cell metadata in the canonical board definition and fixture.

### 3. Confirm rule metadata
- [x] Safe/star IDs confirmed by the project owner against the board artwork: `{0, 8, 13, 21, 26, 34, 39, 47}`.
- [x] Each player entry is safe in the current local test profile.
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
- [x] Added independent golden coordinate assertions for all 52 shared-track cells and the four diagonal endpoints.
- [x] Added entry-direction, exact home-lane orientation, and normalized pawn-center alignment assertions for the square board canvas.
- [ ] Add/execute an on-device rendering review for all four colored pawns and selected-pawn highlights. A fresh full-board Android screenshot is still required.
- [x] Full Flutter pipeline passed for the prior rendering-test commit (#512); re-run is required after this new end-to-end test commit.

### 5. Release gate
- [ ] User approves the board preview against the exact reference; approval is blocked until a fresh Android screenshot is reviewed.
- [ ] Visual topology approval flag is changed only after that approval.
- [ ] Gameplay readiness stays false until topology and rules are approved and the integrated local match flow passes.
- [ ] Confirm the full CI run passes formatting, dependencies, analysis, all tests, Android debug APK build, and artifact upload.

## Turn order and local sound feedback

- [x] Canonical player/turn sequence is Orange → Green → Magenta → Blue; a deterministic engine test covers no-move turn rotation.
- [x] Local match screen provides best-effort platform sound feedback for dice rolls, each animated pawn step, pawn entry from the yard, capture, finish, and match completion.
- [x] Sound effects can be muted/unmuted from the match app bar without changing game state.
- [ ] Verify sound playback on a physical Android device. Platform click/alert sounds are used as a safe initial implementation; dedicated authored audio assets are not yet included.
- [ ] Re-run and confirm the full Flutter/Android CI pipeline for the current commits.

## Board-related test files

- `apps/mobile/test/features/game/domain/board/approved_reference_geometry_acceptance_test.dart`
- `apps/mobile/test/features/game/domain/board/classic_ludo_board_visual_topology_contract_test.dart`
- `apps/mobile/test/features/game/domain/board/reference_board_route_movement_test.dart`
- `apps/mobile/test/features/game/domain/board/classic_ludo_release_gate_test.dart`
- `apps/mobile/test/features/game/domain/board/provisional_safe_square_contract_test.dart`
- `apps/mobile/test/features/game/domain/board/board_gameplay_readiness_gate_test.dart`

## Guardrails

- Do not mark the topology gameplay-ready just because structural tests pass.
- Do not replace the four diagonal transitions with orthogonal cells without reconciling the result against the exact board reference and re-running route, entry, safe-cell, and pawn-animation tests.
- Keep changes small and on `main`, and keep CI green.
