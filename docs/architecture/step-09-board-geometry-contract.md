# Step 09 — Board Geometry Contract

**Status:** Geometry validation contract added; final normalized cell coordinates remain pending visual verification against the approved Ludo Lovers board reference.

## Implemented

- A shared 15×15 grid contract.
- Explicit 52-cell shared-track and six-cell-per-player home-lane dimensions.
- Provisional safe-cell IDs (four start cells plus four star cells).
- A validation helper that rejects a renderer layout missing any logical track or home-lane cell.
- Unit tests for the contract and missing-cell detection.

## Important limitation

The tests use synthetic coordinates to test completeness only. They do **not** certify that those coordinates visually match the board, that adjacent track cells are connected correctly, or that safe/start/home-entry cells align with the rendered artwork. The safe-cell indexes are provisional. Do not connect the engine to this geometry until the coordinate map has been reviewed against the approved board image.

## Next

1. Encode the approved board's 52 track-cell centers and 24 home-lane centers as normalized coordinates.
2. Add adjacency, start-cell, safe-cell, lane direction, and center-finish tests.
3. Render pawns at those coordinates in a geometry debug view.
4. Consolidate the path engine and connect only after the geometry checks pass.

