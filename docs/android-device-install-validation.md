# Android Device Installation and Board Validation

**Build:** Ludo Lovers debug APK  
**Source commit:** `dc87b7a6e02e2100c54ea054c0b0342a1945afb0`  
**Workflow run:** #803 — successful  
**Artifact:** `ludo-lovers-debug-apk`  
**Build status:** Android debug APK build and artifact upload both passed.

## Download the APK

1. Open the GitHub Actions run: https://github.com/chandra0000/ludo-lovers/actions/runs/41158369544
2. Scroll to **Artifacts**.
3. Download `ludo-lovers-debug-apk`.
4. Extract the downloaded ZIP archive.
5. Locate the APK file inside the extracted folder.

The artifact is a debug build and may expire according to GitHub's artifact-retention policy. The recorded artifact expiry for run #803 is 7 November 2026.

## Install on Android

1. Transfer the extracted APK to your Android phone, or download it directly on the phone.
2. Open the APK using the phone's file manager.
3. If Android asks, allow installation from that file manager/browser for this installation.
4. Review the Android installation prompt and install Ludo Lovers.
5. Open the app and test the local gameplay prototype.

Only install the APK produced by the linked repository workflow. Android may display a warning because this is a manually installed debug build.

## What to validate on the phone

- App launches and home navigation works.
- Gameplay screen stays in portrait orientation.
- Full board artwork is visible without clipping or stretching.
- Orange, Green, Blue, and Magenta starting areas and pawn positions align with the supplied reference.
- Dice and turn banner remain visible and touchable.
- Pawn movement follows each route one cell at a time.
- Inspect all four diagonal corner connectors and the Blue wraparound.
- Confirm each pawn enters the correct five-cell home lane.
- Check safe cells, captures, and finish behaviour as a local prototype.

## Evidence to send back

Please capture one screenshot showing the complete gameplay screen and board. If possible, also capture a screenshot after moving a Blue pawn and one screenshot showing a pawn entering its home lane. These will let us compare the actual phone rendering and movement against the approved board reference.

## Important status

This build is **ready for development installation and device validation**, not production release. The route has structural automated coverage, but final physical-device visual acceptance remains open. The app still intentionally reports the board as provisional; do not treat a successful install or green CI run as final board approval.
