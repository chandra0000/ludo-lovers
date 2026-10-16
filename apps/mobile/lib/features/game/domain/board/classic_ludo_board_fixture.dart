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

import 'classic_ludo_board_definition.dart';
import 'ludo_board_paths.dart';

class ClassicLudoBoardFixture {
  const ClassicLudoBoardFixture._();

  static const int sharedTrackLength = 52;
  static const int homeLaneLength = 6;

  /// Derived from the shared seat definition to avoid duplicate entry offsets.
  static Map<String, int> get provisionalEntryCellByPlayer =>
      Map<String, int>.unmodifiable({
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.provisionalTrackEntryIndex,
      });

  static LudoBoardPaths create() {
    ClassicLudoBoardDefinition.validate();
    return LudoBoardPaths(<LudoPlayerPath>[
      for (final seat in ClassicLudoBoardDefinition.seats)
        _createPlayerPath(
          seat.id,
          seat.homeLaneStartCellId,
          seat.provisionalTrackEntryIndex,
        ),
    ]);
  }

  static LudoPlayerPath _createPlayerPath(
    String playerId,
    int homeLaneBase,
    int entry,
  ) {
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
