# Ludo Lovers — four-phase gameplay verification plan

**Status date:** 2026-11-01  
**Scope:** Android-first local gameplay prototype in `apps/mobile/`  
**Release posture:** The board route remains provisional. A green CI run is necessary, but it is not visual approval or real-device sign-off.

This plan is intentionally evidence-driven. A checkbox is only complete when the named automated test or device evidence exists on the same commit being reviewed.

## Phase 1 — asset and rendering stability

### Existing implementation to retain
- `ludo_board_glass.png` is the committed lossless artwork master; `ludo_board_glass.webp` is the committed phone-sized runtime derivative.
- `pubspec.yaml` declares the WebP runtime asset. `tool/optimize_game_artwork.py` regenerates it from the PNG source, and the Android CI workflow runs that generator before Flutter analysis, tests and APK build.
- `LocalGameScreen` uses a bounded `ResizeImage` provider (576 × 1024), preloads it with `precacheImage`, and has visible loading and image-error fallback states.
- `gameplay_board_asset_test.dart` loads the bundled WebP, checks its RIFF/WEBP signature and 300 KB budget, then decodes it within the phone render bounds and verifies the 9:16 aspect ratio.
- Keep the PNG as the design master; do not replace it with the lossy runtime derivative or change the approved composition as part of performance debugging.

### Acceptance work
- [ ] Record the committed PNG's exact dimensions and byte size; establish an explicit bundled-asset budget before replacing the source artwork with an optimized derivative.
- [ ] Verify decoded dimensions and aspect ratio against the committed PNG source, not only maximum dimensions.
- [ ] Test successful board rendering and a deliberately missing/corrupt asset; the error state must remain visible and must not leave a black/empty gameplay surface.
- [ ] Test the loading state before decode completes.
- [ ] Verify board, pawn and dice widgets are painted in the same frame after loading, for all four modes.
- [ ] Verify timers, listeners, image-stream listeners, animation work and owned controllers are cleaned up when the match route is popped. Injected controllers remain caller-owned.
- [ ] Repeat route entry/exit and confirm no pending timer callbacks call `setState` after disposal.

**Gate:** Do not call Phase 1 complete from a unit asset decode test alone; include widget rendering/error tests and a repeated navigation/disposal test.

## Phase 2 — board geometry

### Existing implementation to retain
- The canonical definition and fixture contain a 52-cell shared track, four player paths, five home-lane cells per player, and a separate center finish.
- Structural topology tests document the four candidate diagonal connectors at indexes 4, 17, 30 and 43.
- Safe cells are currently provisional: `{0, 8, 13, 21, 26, 34, 39, 47}`.
- Seat entries are Orange 0, Green 13, Magenta 26 and Blue 39.

### Library artwork comparison (2026-11-01)

Compared the available Library artwork variants: `ludo_board_glass.png`,
`Ludo Lovers: Royal Neon Showdown.png`, `Neon Gold Ludo Lovers Game UI.png`,
and `Ludo Lovers: Luxury Game UI Showcase.png`. The gameplay artwork is a
portrait 9:16 composition with a square 15 × 15 board. The current screen maps
that board into the 576 × 1024 design canvas at (17, 205) with a 542 × 542
playable square. The four displayed seat yards are top-left Orange, top-right
Green, bottom-left Blue, and bottom-right Magenta. The current 15 × 15 yard
centers and the entry markers (Orange (1,6), Green (8,1), Magenta (13,8),
Blue (6,13)) are consistent with the available game-board variants.

The variants are not pixel-identical: some show different pawn occupancy and
star decoration. Therefore, they are useful for confirming seat orientation
and broad pawn placement, but they do not authorize changing the route or
safe-cell IDs. The separately referenced original `1000545512.jpg` was not
found in the Library listing. Keep the route and safe-cell map provisional
until that exact reference or an explicitly approved replacement is available.

A regression test now checks the four yard groups against their four distinct
artwork quadrants and verifies each of the four pawn-well centers, not only
Orange's yard.

### Acceptance work
- [ ] Assert exactly 52 unique, in-bounds shared cells and verify every transition, including 51 → 0, against the approved topology contract.
- [ ] Assert the four entry markers and route offsets against the approved board artwork.
- [ ] Assert five unique, in-bounds, connected home-lane cells per seat and a distinct center finish.
- [ ] Confirm all safe/star cell IDs against the approved artwork and selected rules profile.
- [ ] Test pawn-to-pixel mapping for every track and home-lane cell at compact, mainstream and large phone sizes, plus a tablet viewport.
- [ ] Test both logical position and hit target alignment at straight segments, each corner, wraparound, entry and home-lane transitions.
- [ ] Compare screenshots from a physical Android device with the user's straight-on board reference. Do not infer missing coordinates from generic Ludo artwork.
- [ ] Keep `isVisualTopologyApproved` and `isGameplayReady` false until the visual comparison and route/rules review are signed off.

**Gate:** Structural checks passing does not approve the route. No production/gameplay-ready flag until visual geometry and safe-cell mapping are confirmed.

## Phase 3 — game engine

The canonical engine is pure Dart and must remain independent of Flutter/Flame rendering. Preserve immutable snapshots, expected-version checks, typed events, and deterministic rule-profile injection.

### Acceptance work
- [ ] Dice input accepts only values 1–6 and rejects invalid values without mutating state.
- [ ] Pawn unlocking requires the configured entry roll; non-legal pawn IDs and stale versions are rejected.
- [ ] Three consecutive sixes follow the selected rules profile: the third six ends the turn and cannot be used for movement under the currently documented classic rules.
- [ ] Captures occur only on unprotected cells; safe cells and Team Up teammate protection are covered.
- [ ] Bonus-turn combinations (six, capture and finish) have explicit, table-driven tests.
- [ ] No-legal-move rolls automatically pass the turn according to the rules profile.
- [ ] Exact-finish and overshoot behavior are covered.
- [ ] Finished players are skipped correctly; a finished player cannot act again.
- [ ] Victory, completed-match immutability, and winner/team winner handling are covered.
- [ ] Verify the same rule cases for Classic and Team Up where their rules differ.

**Gate:** The rules document and executable `LudoRuleProfile` must agree. Any ruleset variation must be explicit rather than inferred by the UI.

## Phase 4 — integration and stress testing

### Acceptance work
- [ ] Run the full integration matrix for VS AI, 2-player, 4-player and Team Up.
- [ ] Verify mode-specific player counts, scheduled turns, AI ownership, teammate behavior and match completion.
- [ ] Verify navigation into a match, restart/rematch, back navigation and route disposal.
- [ ] Run portrait tests at compact (360 × 800 logical), mainstream (393 × 873), large phone and tablet sizes; verify no overflow, clipped board, hidden dice or inaccessible controls.
- [ ] Run at least 50 automated match-entry/exit cycles with fake time where possible; assert no active timers/listeners/controllers remain after each exit.
- [ ] Run a longer match stress test with repeated rolls, pawn movement, captures and AI turns.
- [ ] Capture memory before/after repeated navigation and after garbage collection; investigate sustained growth rather than treating one noisy sample as a leak.
- [ ] Check Android responsiveness: frame jank during dice/pawn animation, input latency, image decode stalls, background/foreground transitions and system UI restoration.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` from `apps/mobile/`.
- [ ] Verify the workflow for the exact final commit is `completed / success`, including the Android debug APK build and artifact upload.

**Gate:** Do not claim the matrix passed until each mode and target layout has a recorded test result. Physical-device responsiveness and visual approval must be reported separately from CI.

## Current known blockers and safeguards

1. Board route, corner transitions and safe-cell placement are still provisional pending exact artwork review.
2. The board asset test proves bundle loading and codec decoding; widget lifecycle tests separately cover loading and failed-asset fallback, but a full painted-frame assertion for every mode remains required.
3. CI green status does not certify physical-device visuals, memory behavior, or gameplay correctness outside the covered tests.
4. Online multiplayer, server-authoritative dice, and online fairness verification are outside this local-game verification plan.

## Required evidence for milestone sign-off

Attach to the milestone/PR:
- CI run URL and exact commit SHA.
- Committed PNG dimensions and byte size; record optimized derivative metrics only if a derivative becomes the runtime asset.
- Test names/results for rendering, loading/error states, disposal, geometry, engine rules and all four modes.
- Device/layout matrix and screenshots.
- Repeated-entry/exit and memory observations.
- Explicit board visual approval decision; otherwise retain the provisional status.
