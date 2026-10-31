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


## Orthogonal topology gate — 2026-10-31 implementation update

A dedicated code-level topology audit now lives in
`apps/mobile/lib/features/game/domain/board/classic_ludo_board_topology.dart`.
It is separate from the older structural audit, which permits the four documented
diagonal artwork connectors.

The strict orthogonal audit reports these unresolved edges:

| Edge | From | To |
|---:|---|---|
| 4 → 5 | (5,6) | (6,5) |
| 17 → 18 | (8,5) | (9,6) |
| 30 → 31 | (9,8) | (8,9) |
| 43 → 44 | (6,9) | (5,8) |

The 51 → 0 wrap remains orthogonally adjacent: (0,6) → (1,6).

### Important mathematical constraint

The current four entry markers are (1,6), (8,1), (13,8), and (6,13).
All four have the same checkerboard parity. In an orthogonal grid, every move
flips checkerboard parity. Therefore a 13-edge interval must end on the
opposite parity, but each consecutive pair of current entry markers has the
same parity. The strict audit reports all four 13-edge entry intervals as
parity conflicts.

This means the following requirements cannot all be true at once with the
current integer 15×15 coordinates:

- keep all four current entry-marker coordinates;
- keep entry indexes 0, 13, 26, and 39;
- make every shared-track edge orthogonally adjacent.

No route-coordinate rewrite can satisfy all three. The code now exposes this
as a hard topology blocker instead of treating documented diagonals as
orthogonal or silently changing the approved board layout.

### Implementation status

- [x] Added a dedicated orthogonal topology audit.
- [x] Added exact tests for all four diagonal edges and the 51 → 0 wrap.
- [x] Added checkerboard-parity diagnostics for all four 13-edge seat intervals.
- [x] Gameplay readiness now requires a valid orthogonal topology as well as
  explicit visual approval.
- [x] Preserved the current seat markers, safe-cell IDs, home lanes, and brand
  palette; no unapproved coordinate changes were made.
- [ ] Reconcile the contradiction against the owner's original board artwork:
  either confirm that the four diagonal corner connectors are intentional
  movement edges, or approve revised entry-marker coordinates/route indexing.
- [ ] Only after that decision, update the canonical track, seat entries,
  player-relative routes, safe-cell IDs if necessary, painter/hit-testing,
  and all movement tests as one coordinated change.
- [ ] Complete physical Android screenshot and full-match validation.

**Release decision:** the strict orthogonal topology gate is intentionally
closed. The existing 52-cell candidate remains provisional. Passing the
structural audit or CI does not override this gate.
