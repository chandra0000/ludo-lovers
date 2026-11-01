# Ludo Lovers — four-phase gameplay verification plan

**Status date:** 2026-11-01  
**Scope:** Android-first local gameplay prototype in `apps/mobile/`  
**Release posture:** The board route remains provisional. A green CI run is necessary, but it is not visual approval or real-device sign-off.

This plan is intentionally evidence-driven. A checkbox is only complete when the named automated test or device evidence exists on the same commit being reviewed.

## Phase 1 — asset and rendering stability

### Existing implementation to retain
- The approved PNG remains the lossless master; the build generates `ludo_board_glass.webp` with `apps/mobile/tool/optimize_game_artwork.py`.
- The optimizer applies EXIF orientation, preserves aspect ratio/transparency, caps the longest edge at 1440 px, and targets 500 KB.
- `LocalGameScreen` uses a bounded `ResizeImage` provider (576 × 1024), preloads it with `precacheImage`, and has an image error fallback.
- `gameplay_board_asset_test.dart` loads and decodes the bundled WebP and checks the phone decode bounds.

### Acceptance work
- [ ] Record the generated WebP's exact width, height, byte size, source dimensions, and compression reduction in the CI log. Fail if the file is empty, malformed, not WebP, or exceeds the agreed hard runtime budget (currently 300 KB in the asset test).
- [ ] Verify decoded dimensions and aspect ratio against the source, not only maximum dimensions.
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
2. The existing board asset test proves bundle loading and codec decoding; it does not by itself prove a fully painted gameplay frame or successful fallback behavior.
3. CI green status does not certify physical-device visuals, memory behavior, or gameplay correctness outside the covered tests.
4. Online multiplayer, server-authoritative dice, and online fairness verification are outside this local-game verification plan.

## Required evidence for milestone sign-off

Attach to the milestone/PR:
- CI run URL and exact commit SHA.
- WebP dimensions and byte size from the build log.
- Test names/results for rendering, loading/error states, disposal, geometry, engine rules and all four modes.
- Device/layout matrix and screenshots.
- Repeated-entry/exit and memory observations.
- Explicit board visual approval decision; otherwise retain the provisional status.
