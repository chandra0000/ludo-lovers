/// Canonical logical route fixture for a classic four-player Ludo board.
///
/// The physical shared-track IDs are 0..51. Player-relative routes are rotated
/// to match the current board-definition start markers:
/// Orange 0, Green 13, Magenta 26, Blue 39.
///
/// IMPORTANT: the display geometry remains provisional. These offsets align
/// the engine fixture with the current seat metadata, but do not approve the
/// route topology or enable production gameplay.
library;

import 'ludo_board_paths.dart';

class ClassicLudoBoardFixture {
  const ClassicLudoBoardFixture._();

  static const int sharedTrackLength = 52;
  static const int homeLaneLength = 6;

  static const Map<String, int> provisionalEntryCellByPlayer =
      <String, int>{
    'orange': 0,
    'green': 13,
    'magenta': 26,
    'blue': 39,
  };

  static LudoBoardPaths create() {
    return LudoBoardPaths(<LudoPlayerPath>[
      _createPlayerPath('orange', 200),
      _createPlayerPath('green', 220),
      _createPlayerPath('magenta', 230),
      _createPlayerPath('blue', 210),
    ]);
  }

  static LudoPlayerPath _createPlayerPath(String playerId, int homeLaneBase) {
    final entry = provisionalEntryCellByPlayer[playerId];
    if (entry == null) {
      throw ArgumentError.value(playerId, 'playerId', 'Unknown board seat');
    }
    return LudoPlayerPath(
      playerId: playerId,
      mainTrackCells: List<int>.generate(
        sharedTrackLength,
        (index) => (index + entry) % sharedTrackLength,
      ),
      homeLaneCells: List<int>.generate(
        homeLaneLength,
        (index) => homeLaneBase + index,
      ),
      trackLength: sharedTrackLength,
    );
  }
}
