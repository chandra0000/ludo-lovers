# Board Route and Topology Validation

**Last reviewed:** 2026-10-31  
**Branch:** `main`  
**Latest verified CI:** Run #803 — success  
**Status:** Structurally validated candidate; device visual acceptance pending. Gameplay release gate remains closed.

## 1. Canonical board contract

The board definition is the single source of truth for the 15×15 coordinate grid, shared-track cells, player markers, private home lanes, safe-cell IDs, and centre finish.

| Contract | Current value |
|---|---|
| Physical shared loop | 52 unique cells, IDs 0–51 |
| Player entry offsets | Orange 0; Green 13; Magenta 26; Blue 39 |
| Player-relative shared movement | 51 cells before private lane |
| Home lane | 5 cells per player |
| Centre finish | Separate cell (column 7, row 7) |
| Safe/star IDs | 0, 8, 13, 21, 26, 34, 39, 47 |
| Turn order | Orange → Green → Magenta → Blue |

The route fixture rotates the same physical 52-cell loop for each seat. A pawn advances through 51 shared cells, then enters its own five-cell lane. The remaining adjacent corner cell is retained in the physical loop but is not part of that player's movement sequence.

## 2. Topology audit

The shared route contains exactly four diagonal transitions:

| Transition | From | To | Classification |
|---|---|---|---|
| 4 → 5 | (5,6) | (6,5) | Documented corner connector |
| 17 → 18 | (8,5) | (9,6) | Documented corner connector |
| 30 → 31 | (9,8) | (8,9) | Documented corner connector |
| 43 → 44 | (6,9) | (5,8) | Documented corner connector |

These four diagonal links are explicitly enumerated in the geometry contract. They are not silently treated as orthogonal. Any additional diagonal or non-neighbour jump is an unmapped topology defect.

Each player's final traversed shared cell joins the first private-lane cell orthogonally:

| Player | Final shared cell | First home-lane cell |
|---|---|---|
| Orange | track 50 at (0,7) | (1,7) |
| Green | track 11 at (7,0) | (7,1) |
| Blue | track 37 at (7,14) | (7,13) |
| Magenta | track 24 at (14,7) | (13,7) |

The route tests also check unique/in-bounds coordinates, loop wraparound, player entry alignment, home-lane continuity and uniqueness, lane/track separation, safe-cell ranges, and the separate centre finish.

## 3. What is validated versus what is not

### Automated structural validation — implemented

- [x] Canonical 52-cell shared-track definition.
- [x] Four entry offsets and marker-to-entry alignment.
- [x] Four known diagonal corner connectors are explicit and locked by golden-coordinate tests.
- [x] Unknown non-neighbour transitions are rejected by the audit.
- [x] Four player-relative paths use the same shared physical cells.
- [x] 51 shared movement cells per player, followed by five private-lane cells.
- [x] Home lanes are unique, consecutive, in bounds, and separate from the shared loop and each other.
- [x] Owner-confirmed safe/star IDs are centralized and range-checked.
- [x] Blue wraparound and intermediate route movement have explicit tests.
- [x] Board rendering and pawn positions use normalized grid-cell centres.

### Physical-device visual acceptance — pending

- [ ] Install the latest debug APK on an Android phone.
- [ ] Compare the full board and pawn centres against the original board reference.
- [ ] Check all four colours, all four corner connectors, home lanes, and centre finish.
- [ ] Check that the board is not clipped, stretched, or offset on the actual device.
- [ ] Check pawn movement visually for Orange, Green, Magenta, and especially Blue.
- [ ] Capture a screenshot of the full gameplay screen and review it before approval.

Widget tests and a successful APK build cannot prove device-specific scaling, clipping, touch alignment, or visual correspondence with the supplied artwork.

## 4. Release gates

The code intentionally keeps:

- `ClassicLudoBoardDefinition.isVisualTopologyApproved = false`
- `ClassicLudoBoardCoordinateFactory.isGameplayReady = false`

Do not change either flag merely because CI is green. Change them only after the reference image, on-device rendering, selected rules profile, and end-to-end local gameplay have all been reviewed and explicitly approved.

## 5. Latest CI evidence

GitHub Actions run #803 completed successfully on 2026-10-31 for commit `dc87b7a6e02e2100c54ea054c0b0342a1945afb0`. The workflow passed formatting, dependency resolution, Flutter analysis, automated tests, Android debug APK build, and artifact upload.

This proves the development APK is buildable. It does not constitute visual topology approval or production release approval.

Workflow: https://github.com/chandra0000/ludo-lovers/actions/runs/41158369544
