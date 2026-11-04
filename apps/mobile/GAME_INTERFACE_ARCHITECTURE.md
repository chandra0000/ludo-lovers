# Ludo Lovers gameplay interface contract

## Goal

Preserve the approved full-screen portrait gameplay composition as the common
visual foundation for Classic, Team Up, local AI, and future online multiplayer.
The artwork is a complete interface composition, not a board-only background.
Do not crop it, replace it with a simplified board, or redesign its approved
visual regions without explicit visual review.

## Visual source and runtime

| Concern | Contract |
|---|---|
| Approved master | `apps/mobile/assets/images/ludo_board_glass.png` |
| Runtime derivative | `apps/mobile/assets/images/ludo_board_glass.webp` |
| Flutter declaration | `apps/mobile/pubspec.yaml` |
| Runtime screen | `apps/mobile/lib/features/game/presentation/screens/local_game_screen.dart` |
| Reference canvas | 576 × 1024 logical design coordinates |
| Aspect ratio | 9:16 portrait; preserve the full image bounds |
| Runtime decode | Bounded `ResizeImage` at 576 × 1024 |
| Runtime budget | 300 KB maximum; validated by the gameplay asset test |

The WebP is generated from the approved PNG by
`apps/mobile/tool/optimize_game_artwork.py`. The optimizer must preserve the
entire composition and aspect ratio. Never change the source image or crop policy
as a workaround for a rendering issue.

## Layer responsibilities

1. **Artwork layer:** supplies the approved static visual treatment and layout.
   It must not become the source of truth for a changing match.
2. **Gameplay state layer:** owns the current match state, active seat, dice
   result, pawn positions, legal moves, captures, finished pawns, and result.
3. **Interaction/overlay layer:** renders tappable dice and controls, pawn hit
   targets, legal-move highlights, animation, and accessibility semantics.
   Overlay positions must be measured against the full 576 × 1024 reference,
   not against a cropped board rectangle.
4. **Player presentation layer:** renders dynamic names, avatars, team labels,
   scores, connection/presence indicators, and turn status. If a field is baked
   into the artwork, the runtime layer must not paint a duplicate over it.
5. **Match transport layer (future):** exchanges validated commands and
   authoritative state snapshots/events with an online match service. It must
   not own widgets or image rendering.

## Local and online compatibility

Keep the local game engine/controller independent from Supabase, sockets, or
other network transport. Offline play must continue to work without a network
connection.

When online multiplayer is implemented, introduce a match-session boundary
(e.g. a repository/adapter interface) that can provide match state and submit
player commands. Local mode can use the existing local controller; online mode
can use a remote session implementation. Both should feed the same presentation
contract so the artwork, board geometry, pawn widgets, dice, and controls are
not duplicated into separate local/online screens.

The server must validate turn ownership, dice outcomes, legal pawn movement,
captures, team rules, and match completion. The client may animate and predict
presentation, but must reconcile to authoritative server state. Do not treat a
client-side timer, AI decision, local version counter, or visual animation as
proof of an online move being accepted.

Dynamic online fields should include, as applicable:

- match/session identifier and lifecycle state;
- seat/player identity, display name, avatar, team, and connection presence;
- active player, turn deadline, dice result, and legal actions;
- pawn positions and capture/finish events;
- authoritative match result and reconnect/resynchronization state.

## Required validation before release

- Verify the WebP exists in the clean checkout and is present in the built APK.
- Decode it at the bounded runtime dimensions and assert its full 9:16 aspect
  ratio and 300 KB budget.
- Test that the full-screen artwork is rendered and the interactive overlays
  remain available above it.
- Verify each game mode opens the same complete screen without a blank frame,
  unhandled initialization error, or duplicate/inert controls.
- Test portrait Android layouts at supported phone sizes, including system-bar
  insets and device back navigation.
- Exercise repeated enter/back/re-enter cycles and confirm timers/listeners are
  disposed.
- Before approving online play, test reconnect, stale commands, duplicate
  commands, turn timeout, and server/client state reconciliation.

A green CI pipeline proves the automated checks and APK build completed; it does
not prove that the installed APK renders correctly on a physical phone. Keep
real-device smoke testing as a separate release gate.

## Current scope

The present screen is a local gameplay prototype. This document defines the
visual and architectural compatibility contract; it does not claim that online
multiplayer, server authority, matchmaking, or reconnect handling is implemented.
