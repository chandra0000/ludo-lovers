/// Canonical logical route fixture for a classic four-player Ludo board.
///
/// The physical shared-track IDs are 0..51. Each player traverses 51 cells
/// before branching into its private home lane, leaving the outer corner cell
/// beyond that lane entrance unused. Routes are rotated to match the markers:
/// Orange 0, Green 13, Blue 39, Magenta 26 (seat declaration order).
///
/// IMPORTANT: the display geometry remains provisional. These offsets align
/// the engine fixture with the current seat metadata, but do not approve the
/// route topology or enable production gameplay.
library;

import 'classic_ludo_board_definition.dart';
import 'ludo_board_paths.dart';

class ClassicLudoBoardFixture {
  const ClassicLudoBoardFixture._();

  static const int sharedTrackLength =
      ClassicLudoBoardDefinition.sharedTrackLength;
  static const int playerTrackLength =
      ClassicLudoBoardDefinition.playerTrackLength;
  static const int homeLaneLength = ClassicLudoBoardDefinition.homeLaneLength;

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
        _createPlayerPath(seat),
    ]);
  }

  static LudoPlayerPath _createPlayerPath(ClassicLudoSeat seat) {
    final entry = seat.provisionalTrackEntryIndex;
    return LudoPlayerPath(
      playerId: seat.id,
      mainTrackCells: List<int>.generate(
        sharedTrackLength,
        (index) => (index + entry) % sharedTrackLength,
      ),
      homeLaneCells: seat.homeLaneCellIds,
      trackLength: playerTrackLength,
    );
  }
}
