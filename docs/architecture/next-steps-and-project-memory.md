# Ludo Lovers — project memory and next implementation steps

**Last reviewed:** 2026-10-20  
**Repository:** `chandra0000/ludo-lovers`  
**Default working branch:** `main`  
**Flutter app:** `apps/mobile/`

This is the quick handoff document for resuming work without re-discovering decisions. Keep it current when a milestone or release gate changes.

## Current status at a glance

- **Latest verified CI at this update:** workflow **#397** succeeded for commit `9877971ac95523b5a309b1406d1c035b84a506fd` — [view run](https://github.com/chandra0000/ludo-lovers/actions/runs/39369167976). It includes formatting, dependency resolution, Flutter analysis, automated tests, Android debug APK build, and artifact upload.
- **Product status:** engineering prototype / local gameplay alpha. A green CI run means the checked code builds and tests pass; it does **not** mean board topology is visually approved or the app is launch-ready.
- **Board release gate:** still closed. Keep `isVisualTopologyApproved` / `isGameplayReady` false until the user's original board artwork is reviewed cell-by-cell.
- **Online features:** no production online multiplayer, server-authoritative dice, authentication, friends/rooms, or secure coin ledger is available yet.
- **Brand:** keep the supplied Ludo Lovers logo unchanged unless the user explicitly requests a redesign. Exact player palette: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`. Tagline: “Play • Connect • Love”.

## Non-negotiable engineering rules

1. Make small, focused changes directly on `main` as requested.
2. After each commit, inspect the workflow triggered by that exact commit. Do not start another feature while CI is red.
3. A workflow is green only after the whole run concludes successfully, including APK build and artifact upload—not just tests or analysis.
4. Keep the game rules in the pure-Dart domain engine. Presentation code renders state and sends actions; it must not become a second rules engine.
5. Preserve immutable game state, version checks, typed transition events, and one canonical route/board definition.
6. Do not make the provisional board gameplay-ready based on generic Ludo references or assumptions. Obtain visual confirmation against the user's original board.
7. Do not claim online/backend/release features exist until implemented and verified end-to-end.
8. Keep the provisional-route warning visible in development UI until topology approval.

## Board decisions already recorded

- Four seats/colors: Orange, Green, Blue, Magenta.
- The agreed route model is **five coloured home-lane cells plus a separate centre finish**.
- Shared track has 52 cells; current safe-cell IDs are `{0, 8, 13, 21, 26, 34, 39, 47}`, pending visual approval.
- The current geometry audit explicitly documents diagonal links at indexes `4→5`, `17→18`, `30→31`, and `43→44`. These are structural allowances, not proof that the art is correct.
- Current route/start orientation and safe-cell placement remain provisional. Do not edit the release gate until the reference confirms the cell sequence, entries, home lanes and safe squares.
- Keep the current original palette and fixed logo. Do not substitute colors from an unrelated mockup.

For the detailed evidence and acceptance checks, see [board-route-acceptance.md](../board-route-acceptance.md).

## Implementation order

### P0 — Keep CI trustworthy

- [x] Workflow #397 passed for the commit listed above.
- [ ] For every subsequent change, check the newest run and confirm the full workflow succeeds.
- [ ] If a run fails, inspect the failing step/log, make the smallest correction, and rerun before continuing.

### P1 — Verify the actual board before enabling gameplay

- [ ] Use a clear, straight-on image of the original board, ideally with the 15×15 grid visible.
- [ ] Trace all 52 shared-track cells in order and verify the four corner transitions.
- [ ] Confirm each seat's start cell, direction and private-lane entry.
- [ ] Confirm all five home-lane cells and the separate centre finish.
- [ ] Confirm every safe/star cell against the same reference and written rules profile.
- [ ] Update the canonical board definition, paths, painter/hit testing, and regression fixtures together.
- [ ] Enable `isGameplayReady` only after the evidence and tests agree.

### P2 — Complete real-device local-match acceptance

After topology is approved, test on Android:
- [ ] Roll, highlight legal pawns, choose a pawn, and verify the animated pawn lands on the engine's destination.
- [ ] Test yard entry on six, ordinary movement, blocked/illegal moves, and exact-finish behavior.
- [ ] Test safe cells, single-pawn capture, stacked-pawn protection, and capture bonus turns.
- [ ] Test six bonus/three consecutive sixes, no-legal-move turn changes, home-lane entry, finish and winner.
- [ ] Test AI-turn input lockout, completed-match lockout, Play Again/rematch, and accessibility announcements.
- [ ] Capture screenshots at supported Android sizes and check overflow, safe areas, text scaling, touch targets, TalkBack and reduced-motion behavior.

### P3 — Bring the UI closer to the approved reference

- [ ] Compare a real rendered screen side-by-side with the approved screen-9/reference image.
- [ ] Verify the board remains the main visual element and has the expected proportions and quadrant arrangement.
- [ ] Match player panels, dice and controls to the reference while keeping the board connected to live game state.
- [ ] Verify the actual supplied logo asset is used; never redraw or replace it without permission.
- [ ] Check premium dark/gold treatment, exact four-color palette, typography, spacing, glow/shadow, token states and animation.
- [ ] Ensure placeholder destinations are clearly labelled and never imply a feature is functional when it is not.

### P4 — Product foundation, then online design

Only after the local alpha and UI baseline are stable:
- [ ] Design real home navigation/onboarding and implement only destinations that work.
- [ ] Specify account/guest identity, friends, invitations, private rooms, reconnect/rejoin and moderation.
- [ ] Design the server-authoritative match protocol, turn/move validation, dice-fairness proof and secure virtual-coin ledger before online play.
- [ ] Complete privacy, terms, community/reporting controls, telemetry, signed builds and store-readiness checks before public release.

## CI quality gate

Run from `apps/mobile/`:

```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions must also successfully upload the Android debug APK artifact. If the pipeline changes, update this document to reflect the actual workflow.

## Definition of done: “Board-verified local alpha”

Do not call this milestone complete until:
- [ ] Board topology and rules are approved against the user's original artwork.
- [ ] The release gate is deliberately enabled with corresponding tests updated.
- [ ] A complete local match passes on a real Android device with no engine/render mismatch.
- [ ] Accessibility and responsive checks pass on target device sizes.
- [ ] The exact final commit's full CI workflow, APK build and artifact upload are green.
- [ ] Known limitations are documented in the app and repository README.

**Remember:** a green pipeline is necessary, but it is not board approval, device QA, backend readiness, or commercial release approval.
