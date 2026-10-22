# Priority 2 — Board route and safe-cell approval gate

**Status: BLOCKED / provisional.** Do not enable production or competitive gameplay from this fixture yet.

## What is now checked automatically

- Exactly 52 unique, in-bounds physical shared-track coordinates; each player traverses 51 cells from the 52-cell physical loop before branching into its own home lane.
- Every sequential transition, including wraparound, is orthogonally adjacent or one of the four explicitly documented diagonal corner links.
- Four distinct player entries align with their physical start-marker coordinates.
- Home lanes have five unique, in-bounds, consecutive cells and do not overlap the shared track or one another; the last traversed track cell connects to the first lane cell through the approved one-cell orthogonal/diagonal branch; the centre finish is a separate position.
- The provisional safe-cell profile equals the four player start IDs plus the cell eight track steps after each start.
- Gameplay readiness remains false while any route or profile check fails.

## Current result

### Route branch correction: implemented structurally

The corrected route keeps all 52 physical cells for shared geometry but traverses only 51 per player before turning into the five-cell home lane. The outer corner immediately beside each home entrance is not traversed. Final shared cells are Orange 50 at (0,7), Green 11 at (7,0), Blue 37 at (7,14), and Magenta 24 at (14,7). Each joins its first private-lane cell orthogonally: Orange to (1,7), Green to (7,1), Blue to (7,13), and Magenta to (13,7). The five lane cells and separate centre finish are preserved.

### Diagonal corner decision: accepted as explicit connectors in the provisional trace

For the current 15×15 coordinate trace, the four non-orthogonal links are **formally accepted as intentional corner connectors**, not treated as accidental gaps:

| Track transition | From coordinate (column,row) | To coordinate (column,row) |
| --- | --- | --- |
| 4 → 5 | (5,6) | (6,5) |
| 17 → 18 | (8,5) | (9,6) |
| 30 → 31 | (9,8) | (8,9) |
| 43 → 44 | (6,9) | (5,8) |

The test suite locks these exact endpoints and requires every other sequential transition to be orthogonally adjacent. This is a **structural decision for the current provisional route**, not a claim that the artwork has been visually approved. If the straight-on reference contradicts a connector, update the canonical definition and its fixtures together rather than adding a renderer-only workaround.

The canonical contract is: 51 shared cells traversed per player's route from the 52-cell physical loop (entry offsets Orange 0, Green 13, Blue 39, Magenta 26); five private home-lane cells per seat; a separate centre finish at grid cell (7,7); and owner-confirmed safe IDs {0, 8, 13, 21, 26, 34, 39, 47}. The four shared-loop corner diagonals and four orthogonal track-to-lane joins after 51 steps are explicitly audited. Automated checks assert that the coordinate factory, player-path fixture, entry markers, home lanes and current local rules profile agree on these values. The safe-cell positions are owner-confirmed; formal competitive rules and on-device visual alignment remain separate approval gates.

**Gameplay remains blocked.** Structural route validation is now implemented, but a fresh Android screenshot has not been visually reviewed against the board reference. Do not set `isVisualTopologyApproved` to true or enable `isGameplayReady` based only on passing structural tests.

The safe-square pattern is based on a common Ludo variant in which each start square and a star square eight track steps later are safe. Rules vary by board and implementation; the source links below are supporting references, not authority for the custom Ludo Lovers board.

## References reviewed

- [Playboardgames — Ludo rules and board overview](https://playboardgames.org/how-to-play-ludo): describes a 52-square loop and eight safe squares (four starts plus four star squares).
- [Ludo World — complete rules guide](https://ludoworld.netlify.app/how-to-play-ludo): describes start IDs and star squares eight steps after a start as one common mapping.
- [Wikipedia — Ludo board game](https://en.wikipedia.org/wiki/Ludo): overview of the track, home lanes, and variant differences.

These references do not establish the exact route order for the Ludo Lovers board. The approved brand reference must be a straight-on, legible 15×15 board with all shared cells, starts, star squares, home lanes, and travel direction visible.

## Release gate checklist

- [ ] Approve the board image and selected rules variant.
- [ ] Trace all 52 shared cells in movement order from that image.
- [ ] Verify all four entry cells, their clockwise order, and home-lane transitions.
- [x] Record owner-confirmed safe-cell IDs: 0, 8, 13, 21, 26, 34, 39, 47.
- [x] Add explicit route fixtures/tests for all 52 cells, every shared transition, all four player-relative paths, and each track-to-home-lane branch.
- [x] Reconcile local player-relative paths with the canonical 52-cell physical route.
- [ ] Run analysis, unit/widget tests, and Android debug build.
- [ ] Manually inspect the rendered board and play a complete local match on Android.
- [ ] Only then consider setting gameplay readiness to true.

## Priority 1 status — local board-backed match

The local prototype already renders engine state on the board, rolls a test/local die, highlights legal pawns, submits moves through the controller/engine, and supports reset. It remains a prototype because the board topology is not approved. Keep rules in the pure Dart engine and do not duplicate move legality in the widget.

## Non-goals for this increment

No route coordinates were guessed or silently changed. No production gameplay gate was opened. No network, authentication, wallet, or online authority was added.
