# Priority 2 — Board Route and Safe-Cell Approval

**Status:** Structurally validated candidate; physical-device visual approval pending.  
**Latest CI:** Run #803 — successful, including Android debug APK build and artifact upload.

## Canonical contract

- 52 unique physical shared-track cells.
- Player entry offsets: Orange 0, Green 13, Magenta 26, Blue 39.
- Each player traverses 51 shared cells before entering a five-cell private home lane.
- Separate centre finish at (7,7).
- Owner-confirmed safe/star IDs: {0, 8, 13, 21, 26, 34, 39, 47}.
- Turn order: Orange → Green → Magenta → Blue.

## Route topology

The route's only diagonal physical-loop transitions are the four documented corner connectors:

| Transition | Coordinates |
|---|---|
| 4 → 5 | (5,6) → (6,5) |
| 17 → 18 | (8,5) → (9,6) |
| 30 → 31 | (9,8) → (8,9) |
| 43 → 44 | (6,9) → (5,8) |

The geometry audit explicitly distinguishes these documented links from unknown non-neighbour jumps. The final shared cell for each player joins its first home-lane cell orthogonally. The player path is a 51-cell traversal of the 52-cell physical loop, then five private-lane cells. Blue wraparound through physical IDs 50, 51, and 0 is covered by movement tests.

## Validation result

### Passed in automated checks
- Shared-track uniqueness, bounds, and 52-cell count.
- Player entry markers and route offsets.
- Exact endpoints of the four documented diagonal connectors.
- Detection of any undocumented diagonal/non-neighbour transition.
- Player-relative route rotation and wraparound.
- Five-cell home-lane uniqueness, continuity, bounds, and non-overlap.
- Safe-cell ID range and centralization.
- Separate centre finish.
- Pawn movement and route mapping test coverage.

### Still required on a real Android phone
- Compare the rendered board to the original supplied reference.
- Check cell-centre alignment, pawn starting positions, and hit targets.
- Exercise all four pawn colours through corners, wraparound, and home-lane entry.
- Confirm capture/safe-square behaviour and finish/overshoot policy.
- Review a full-screen screenshot before changing either readiness flag.

## Release gate

The source intentionally retains:

`ClassicLudoBoardDefinition.isVisualTopologyApproved = false`  
`ClassicLudoBoardCoordinateFactory.isGameplayReady = false`

Do not enable either gate based only on a green pipeline. Structural tests cannot establish physical-device visual alignment or user approval of the selected board/rules variant.

## Development installation

The latest successful workflow uploaded the artifact `ludo-lovers-debug-apk`. It is suitable for installing on an Android phone for development validation. It is a debug build, not a Play Store/production release.

Workflow: https://github.com/chandra0000/ludo-lovers/actions/runs/41158369544
