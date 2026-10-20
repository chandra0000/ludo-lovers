# Ludo Lovers — implementation and commercial-readiness checklist

**Audit date:** 2026-10-20  
**Repository:** `chandra0000/ludo-lovers`  
**App:** `apps/mobile/`  
**Assessment type:** repository/code review, tests and workflow metadata. This is **not** a visual QA sign-off from a physical Android device.

## Quick project memory

For the current decisions, next-step order, CI rules, board release gate, and definition of done, start with [Project memory and next implementation steps](architecture/next-steps-and-project-memory.md). Keep that document updated as work progresses.

## Honest product status

**Current classification: engineering prototype / local gameplay alpha, not commercially launch-ready.**

The repo has meaningful foundations: Flutter app shell, design tokens, board painter/preview, a board-backed local match screen, a canonical pure-Dart local engine, AI turn handling, accessibility semantics, and substantial unit/widget coverage.

However, the app currently exposes only a foundation/home screen, board preview, and local game screen in `lib/`. The reference's full consumer product experience (onboarding/authentication, social/friends, rooms/invites, profile, wallet, achievements, customization, Love Mode and production navigation) is not implemented as working end-to-end product flows. The board's logical route and safe cells are still provisional. No real-device visual sign-off, online backend, authoritative server, store-release readiness, or production safety/privacy review is evidenced by this repository review.

## 1. What is in good shape

- [x] Flutter/Dart Android app scaffold exists at `apps/mobile/`.
- [x] Brand palette is centralized in `AppTheme`: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`; dark/gold/cream tokens are also present.
- [x] README and visual baseline explicitly say the supplied logo is a fixed asset and mockups are targets, not proof of implementation.
- [x] Canonical board definition and a 52-cell shared-track fixture exist.
- [x] Board geometry, route mapping, safe-cell contracts, and release-gate tests exist.
- [x] Pure-Dart path-based local engine exists with typed events, immutable/versioned state, roll/move validation, captures, turn advancement, finishing, and completed-match protection.
- [x] Local match UI is wired to engine/controller state rather than being a static board image.
- [x] Unit/widget tests cover many critical rules and interactions: legal pawn selection, captures, safe cells, stacked pawns, home-lane overshoot, finish/winner, rematch, AI turn/input lock, and accessibility guidance.
- [x] Basic dark/premium theme foundation and board/player/dice controls are implemented.
- [x] GitHub Actions checks formatting, dependency resolution, Flutter analysis, automated tests, Android debug APK build, and artifact upload.

## 2. Must-fix blockers before calling the local game gameplay-ready

### P0 — board and rules correctness

- [ ] Compare the actual rendered 15×15 board against the user's original straight-on reference. The design sheet is a style reference, not a sufficiently legible cell map.
- [ ] Approve the exact movement direction, all 52 shared cells, all four start/entry cells, home-lane transitions, five home-lane cells plus separate center finish, and safe/star squares.
- [ ] Explicitly inspect the provisional diagonal transitions: 4→5, 17→18, 30→31, 43→44.
- [ ] Confirm safe-cell IDs `{0, 8, 13, 21, 26, 34, 39, 47}` against the approved artwork and selected rules variant.
- [ ] Keep `isVisualTopologyApproved` / `isGameplayReady` false until approval; do not infer coordinates from a generic Ludo board.
- [ ] After approval, reconcile the canonical definition, seat-relative paths, painter, hit-testing and tests together.
- [ ] Play through a complete match on a real Android device and verify every pawn's rendered position, hit target, animation, capture and finish state against the logical engine state.

### P0 — verify CI before continuing

- [x] At the 2026-10-20 audit, workflow [#397](https://github.com/chandra0000/ludo-lovers/actions/runs/39369167976) succeeded for commit `9877971ac95523b5a309b1406d1c035b84a506fd`, including the workflow's complete quality gate.
- [ ] For each new commit, verify the run attached to that exact commit reaches `completed / success`, including Android debug APK build and artifact upload.
- [ ] If CI is red, inspect the failing step/log and fix it before continuing feature work. A previous green run does not certify a newer commit.

## 3. Commercial UI — honest assessment

### Implemented foundation

- [x] Dark near-black / gold theme tokens and four player colors.
- [x] A branded foundation screen with product title/tagline and prototype navigation.
- [x] Board preview and local match screen.
- [x] Board painter, pawn markers, dice/result feedback, turn/player indicators and local gameplay controls.
- [x] Some responsive sizing, accessible labels/hints, and animation/widget tests.

### Not yet at commercial quality / not yet evidenced

- [ ] **Reference fidelity:** side-by-side comparison with the approved screen-9 reference at real Android sizes. Code inspection alone cannot certify visual fidelity.
- [ ] **Board composition:** board scale/proportions, quadrants, center finish, seat panels, dice and control placement must match the reference and remain legible on small devices.
- [ ] **Logo:** verify the actual supplied logo asset is used wherever branding appears; the current foundation-screen snippet shows a heart icon beside the wordmark, which is not evidence that the fixed logo asset is being used there.
- [ ] **Visual polish:** verify typography, spacing, gold borders/glows, shadows, token depth, selected/legal-move states, and transitions in rendered screenshots—not only through code.
- [ ] **Accessibility:** test text contrast (especially neon green on dark surfaces), text scaling, semantics order, TalkBack, minimum touch targets, and reduced-motion behavior on device.
- [ ] **Device/layout QA:** test small and large Android screens, system font scaling, safe areas, landscape behavior if supported, and overflow.
- [ ] **Interaction completeness:** remove or clearly label placeholder/“coming soon” routes so the app does not imply non-existent features work.
- [ ] **Product navigation:** implement a complete home/dashboard flow and consistent bottom navigation only when destinations are real.
- [ ] **Commercial polish pass:** create and review screenshots for launch, loading, error, empty, disconnected, completed, and rematch states.
- [ ] **Product content:** finalise privacy policy, terms, community rules, support/contact, age/consent handling, reporting/blocking and moderation expectations before public launch.

**Commercial UI verdict:** the visual direction is present and the local game screen is a useful prototype. The repository does not yet justify describing the overall UI as a finished commercial app. A device screenshot review and reference-by-reference design QA are still required.

## 4. Product capabilities not implemented as production features

- [ ] Authentication/guest identity and account lifecycle.
- [ ] Friends, requests, profiles, presence, invitations, private rooms and match rejoin.
- [ ] Online multiplayer and authoritative game server.
- [ ] Server-side dice generation with a documented, client-verifiable fairness protocol.
- [ ] Server validation of moves, turn order, winners and match state.
- [ ] Secure virtual coin ledger; no real-money value or withdrawal should be implied.
- [ ] Wallet, achievements, leaderboard, customization inventory and Love Mode as functional flows.
- [ ] Disconnect/reconnect, timeout, abuse handling, report/block/mute, moderation and operational monitoring.
- [ ] Release pipeline, signed production builds, store listing assets, crash/error telemetry, privacy/security review and release test matrix.

These are planned product capabilities, not claims about the current build. Do not start monetization or competitive online play before the rules and server authority are validated.

## 5. Recommended implementation order

1. [ ] **Close the CI loop:** verify the latest run is fully green; keep each commit small.
2. [ ] **Board topology sign-off:** obtain/confirm a clear board reference with the 15×15 grid and trace every route/start/safe/home cell. Do not guess.
3. [ ] **Real-device local-match acceptance:** verify a full game and capture screenshots/videos of key states on Android.
4. [ ] **Commercial gameplay screen pass:** compare board proportions, player panels, dice and controls to the approved reference; preserve the fixed logo and exact palette.
5. [ ] **Accessibility and responsive QA:** contrast, TalkBack, text scaling, touch targets, reduced motion and device sizes.
6. [ ] **Finish local alpha:** add any missing tests discovered during device play, then mark the local game alpha only after the acceptance criteria pass.
7. [ ] **Product foundation design/implementation:** implement real navigation and onboarding before accounts/social systems.
8. [ ] **Backend/security design:** define authentication, RLS/data model, server-authoritative game protocol, fairness proof, reconnection and abuse controls before online multiplayer.
9. [ ] **Beta/release readiness:** privacy/legal review, signed builds, monitoring, store assets, accessibility and device test matrix.

## 6. Definition of done for the next milestone

The next milestone is **“Board-verified local alpha”**, not “commercial launch”.

- [ ] Board route and rules explicitly approved against the original reference.
- [ ] Gameplay readiness gate is only enabled after that approval and updated regression fixtures.
- [ ] A full local match completes on a real Android device without a visual/logical state mismatch.
- [ ] CI is green for the exact final commit, including APK build and artifact upload.
- [ ] Screenshots at target Android sizes are compared against the reference and reviewed.
- [ ] Known limitations are documented in the app and README.

## Quality gate

Run from `apps/mobile/`:

```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Keep all changes on `main` as requested, but do not equate a green CI pipeline with board-rule approval, commercial visual QA, backend readiness, or release approval.
