# Priority 2 — Board route and safe-cell approval gate

**Status: BLOCKED / provisional.** Do not enable production or competitive gameplay from this fixture yet.

## What is now checked automatically

- Exactly 52 unique, in-bounds shared-track coordinates.
- Every sequential transition, including wraparound, is orthogonally adjacent or one of the four explicitly documented diagonal corner links.
- Four distinct player entries align with their physical start-marker coordinates.
- Home lanes have five unique, in-bounds, consecutive cells and do not overlap the shared track or one another; the centre finish is a separate position.
- The provisional safe-cell profile equals the four player start IDs plus the cell eight track steps after each start.
- Gameplay readiness remains false while any route or profile check fails.

## Current result

The route audit accepts exactly four documented diagonal corner transitions: 4→5, 17→18, 30→31 and 43→44. Structural validation passes for these transitions, but visual topology approval remains the release blocker. Safe IDs {0, 8, 13, 21, 26, 34, 39, 47} match the currently selected *provisional* rule profile, but this does not prove that those IDs land on the intended printed start/star squares in the final board artwork.

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
- [ ] Verify safe-cell IDs against the printed stars and start cells.
- [ ] Add explicit route fixtures/tests for every transition and all four player-relative paths.
- [ ] Reconcile the local-engine fixture with the approved physical route.
- [ ] Run analysis, unit/widget tests, and Android debug build.
- [ ] Manually inspect the rendered board and play a complete local match on Android.
- [ ] Only then consider setting gameplay readiness to true.

## Priority 1 status — local board-backed match

The local prototype already renders engine state on the board, rolls a test/local die, highlights legal pawns, submits moves through the controller/engine, and supports reset. It remains a prototype because the board topology is not approved. Keep rules in the pure Dart engine and do not duplicate move legality in the widget.

## Non-goals for this increment

No route coordinates were guessed or silently changed. No production gameplay gate was opened. No network, authentication, wallet, or online authority was added.
