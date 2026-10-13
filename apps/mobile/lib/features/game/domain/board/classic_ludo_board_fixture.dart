/// Canonical board fixture for a classic four-player Ludo board.
///
/// This keeps the route model explicit and deterministic so the rules engine
/// can validate player movement against a shared 52-cell board plus six-cell
/// private home lanes without inventing geometry at runtime.
library;

import 'ludo_board_paths.dart';

class ClassicLudoBoardFixture {
  const ClassicLudoBoardFixture._();

  static const int sharedTrackLength = 52;
  static const int homeLaneLength = 6;

  static LudoBoardPaths create() {
    return LudoBoardPaths(<LudoPlayerPath>[
      LudoPlayerPath(
        playerId: 'orange',
        mainTrackCells: List<int>.generate(sharedTrackLength, (index) => index),
        homeLaneCells: List<int>.generate(homeLaneLength, (index) => 200 + index),
        trackLength: sharedTrackLength,
      ),
      LudoPlayerPath(
        playerId: 'blue',
        mainTrackCells: List<int>.generate(
          sharedTrackLength,
          (index) => (index + 13) % sharedTrackLength,
        ),
        homeLaneCells: List<int>.generate(homeLaneLength, (index) => 210 + index),
        trackLength: sharedTrackLength,
      ),
      LudoPlayerPath(
        playerId: 'green',
        mainTrackCells: List<int>.generate(
          sharedTrackLength,
          (index) => (index + 26) % sharedTrackLength,
        ),
        homeLaneCells: List<int>.generate(homeLaneLength, (index) => 220 + index),
        trackLength: sharedTrackLength,
      ),
      LudoPlayerPath(
        playerId: 'magenta',
        mainTrackCells: List<int>.generate(
          sharedTrackLength,
          (index) => (index + 39) % sharedTrackLength,
        ),
        homeLaneCells: List<int>.generate(homeLaneLength, (index) => 230 + index),
        trackLength: sharedTrackLength,
      ),
    ]);
  }
}
