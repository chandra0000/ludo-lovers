# Ludo Lovers — Board Route Acceptance

**Reviewed:** 2026-10-31  
**Current status:** Structural checks pass in CI; physical-device visual acceptance is the remaining board-layout gate.

## Board contract

- 15×15 logical grid.
- 52 unique physical shared-track cells, indexed 0–51.
- Entry offsets: Orange 0, Green 13, Magenta 26, Blue 39.
- 51 shared-track steps per player, followed by five private home-lane cells.
- Separate centre finish at grid coordinate (7,7).
- Owner-confirmed safe/star IDs: 0, 8, 13, 21, 26, 34, 39, 47.
- Turn order: Orange → Green → Magenta → Blue.

## Route and topology findings

The canonical coordinate sequence contains four intentional diagonal corner connectors: 4→5, 17→18, 30→31, and 43→44. Their exact endpoints are locked by the independent golden geometry test. The audit permits only these documented diagonal links; any other non-neighbour transition is an error.

Each player route is a rotation of the same physical loop. The route traverses 51 shared cells before entering its own five-cell lane. It does not traverse the outer corner immediately adjacent to that lane. The final shared cell connects orthogonally to the first lane cell for all four seats. Blue's route explicitly covers the 50→51→0 wraparound.

The geometry and movement contract is internally consistent in source and automated tests. This is a structural finding, not proof that every cell centre matches the artwork on a physical phone.

## Acceptance checklist

### Automated checks
- [x] Exactly 52 unique shared-track cells, all in the 15×15 grid.
- [x] Entry indexes and start markers agree.
- [x] Four documented diagonal connectors have exact expected endpoints.
- [x] No undocumented non-neighbour transition is accepted.
- [x] Player-relative paths share the same physical loop.
- [x] Each path has 51 traversed shared cells and five home-lane cells.
- [x] Home lanes are unique, continuous, in bounds, and do not overlap the shared track or each other.
- [x] Safe-cell IDs are unique/in range and centralized.
- [x] Blue wraparound and intermediate pawn movement have test coverage.
- [x] Centre finish is separate from track and home lanes.
- [x] Latest CI run #803 passed formatting, analysis, tests, Android debug build, and artifact upload.

### Physical Android acceptance
- [ ] Install the latest debug APK.
- [ ] Inspect the full board against the original supplied reference.
- [ ] Confirm cell centres and pawn starting positions for all four colours.
- [ ] Move pawns through straight sections, all four corner connectors, wraparound, and home lanes.
- [ ] Check captures and safe-cell behaviour in a local match.
- [ ] Check exact-finish and overshoot behaviour against the chosen local rules profile.
- [ ] Submit a full-screen phone screenshot for review.

## Current release decision

Keep `isVisualTopologyApproved` and `isGameplayReady` false until the physical-device checks above are completed. Do not change the approved artwork or the user's supplied layout measurements to make a test pass. If the screenshot reveals a mismatch, record the exact cell/coordinate and correct the canonical definition, route fixture, tests, and renderer together.

## Scope and limitations

The current build is suitable for **development installation and device validation**. It is not a production release. Online multiplayer, server-authoritative dice, and production rules approval are not included in this milestone.

Latest workflow: https://github.com/chandra0000/ludo-lovers/actions/runs/41158369544
