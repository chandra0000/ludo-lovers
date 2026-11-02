# Ludo Lovers image assets

The approved source artwork is kept in this directory. Runtime game artwork is
generated from the source during the Flutter validation/build workflow.

## Gameplay board

- `ludo_board_glass.png` — committed gameplay artwork and runtime asset. Do not
  delete or replace it without approving the visual result.
- `ludo_board_glass.webp` — optional generated optimization output. It is not
  referenced by the Flutter app because generated files are not guaranteed to
  exist in a clean checkout.

The optimizer preserves the source aspect ratio, caps the longest edge at
1440 pixels, retains transparency when present, and tries WebP quality levels
from 90 down to 74 to target a file size below 300 KB. If the result remains
above the target, the build reports a warning rather than silently reducing
quality further.

To generate the runtime asset locally from `apps/mobile`:

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

## Other assets

- `ludo_lovers_logo.jpg` — official Ludo Lovers logo used by the app.
- Unused board reference images are kept in source control but are not bundled
  into the Flutter app.
