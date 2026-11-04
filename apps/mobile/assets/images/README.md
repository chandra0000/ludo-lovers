# Ludo Lovers image assets

The approved gameplay artwork is maintained as a full-screen interface composition.
It is intentionally **not** a board-only texture: it preserves the complete approved
portrait presentation (player/header regions, board, dice area, and lower controls)
as the visual reference for both local play and the planned online multiplayer UI.

## Gameplay interface artwork

- `ludo_board_glass.png` — lossless approved source artwork. Keep this as the
  visual master; do not crop, replace, or redesign it without visual approval.
- `ludo_board_glass.webp` — generated, phone-sized runtime derivative used by
  Flutter. It must preserve the full source composition and portrait aspect ratio.
  Do not regenerate it from a different source or crop it to the board alone.

The Flutter screen loads the WebP through a bounded `ResizeImage` provider at
576 × 1024. Dynamic Flutter widgets are layered over the artwork for live gameplay
state (pawns, legal-move feedback, dice interaction, turn state, and other controls).
Keep interactive behavior in Flutter rather than baking changing player/game data
into the image.

## Online multiplayer compatibility

The complete artwork is the shared visual foundation, not the multiplayer data
model. When online play is added:

- Keep the same screen composition and responsive coordinate system.
- Populate player names, avatars, presence, team identity, scores, and turn status
  from the active match/session rather than hard-coded artwork text.
- Keep pawn positions, legal moves, dice results, timers, and match outcomes driven
  by authoritative match state.
- Keep rendering/presentation separate from transport and backend code. The local
  controller must remain usable for offline play; online play should connect through
  a match/session adapter rather than introducing network calls into board widgets.
- Do not display duplicate controls on top of controls already present in the
  approved artwork. Review the overlay hit regions against the full portrait
  reference on a real Android device.

See [GAME_INTERFACE_ARCHITECTURE.md](../../GAME_INTERFACE_ARCHITECTURE.md) for the
screen contract and staged online integration plan.

## Optimization and validation

The optimizer preserves the complete source aspect ratio, caps the longest edge
at 1440 pixels, retains transparency when present, and tries WebP quality levels
from 90 down to 74 to target a file size below 300 KB. It fails the build if the
runtime output remains above that budget; it must not silently discard parts of
the design or switch to a board-only image.

Run from `apps/mobile`:

```bash
python3 -m venv .asset-venv
.asset-venv/bin/python -m pip install Pillow==11.3.0
.asset-venv/bin/python tool/optimize_game_artwork.py
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

CI runs the optimizer before Flutter asset bundling and APK creation.

## Other assets

- `ludo_lovers_logo.jpg` — official Ludo Lovers logo used by the app.
- Unused board reference images are kept in source control but are not bundled
  into the Flutter app.
