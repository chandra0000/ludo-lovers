# Step 11 — Board route and safe-cell review

**Status:** In progress. Local board-backed match exists for development; the board route is not approved for release.

## Current verified state

- Latest confirmed GitHub Actions run at review time: run #196, green for analysis, automated tests, Android debug APK build and artifact upload.
- The local match screen renders engine state on the board, lets the user roll, highlights legal pawns, accepts pawn taps, shows turn state and supports restart.
- This is a local prototype only. It explicitly opts into provisional routes and must not be represented as production-ready or used for online/competitive play.
- The current 52-cell coordinate fixture reports non-orthogonal transitions at indexes 4, 17, 30 and 43. The gameplay readiness gate therefore remains closed.
- The provisional safe-cell profile is `[0, 8, 13, 21, 26, 34, 39, 47]`: four start cells at offsets `0, 13, 26, 39`, plus the current classic-rule hypothesis of a star eight cells after each start.

## Evidence and limits

Generic classic Ludo rules commonly describe 52 shared-track cells, four start squares, and four star safe squares; some rulesets vary on stacking, captures and bonus rolls. For example:

- https://ludo-classic.github.io/rules.html
- https://playboardgames.org/how-to-play/ludo
- https://github.com/bocaletto-luca/Ludo

These references are useful for cross-checking common conventions, but they are not the approved Ludo Lovers board art and do not prove that our custom coordinates, orientation, seat offsets or exact safe cells match the intended visual design. The open-source implementation is a reference only; do not copy its artwork or code.

## Next acceptance gate

Before enabling gameplay readiness:

1. Compare a clear, straight-on image of the intended Ludo Lovers board with all 52 physical shared-track cells numbered in movement order.
2. Confirm the direction and entry square for Orange (top-left), Green (top-right), Blue (bottom-left), and Magenta (bottom-right).
3. Mark the four start squares and four intended star/safe squares on that exact board image.
4. Confirm home-lane direction and the six visual cells for each player, including the transition from the shared track.
5. Update the coordinate factory, painter, seat entries, route fixture and safe-cell metadata as one change.
6. Add transition-by-transition tests and prove each player path is a rotation of the same physical 52-cell route.
7. Only set `isGameplayReady` true after geometry audit, route mapping, movement acceptance tests and visual review all pass.

## Release guardrails

- Do not infer missing geometry from a small composite brand sheet or from a generic internet board.
- Keep safe-cell metadata explicitly provisional until the custom board is reviewed.
- Keep the local prototype warning visible.
- Do not connect online matchmaking or competitive play to the provisional route.
- CI passing means code analysis/tests/build pass; it does not constitute visual approval or real-device playtesting.
