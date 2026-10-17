import 'board_coordinate_layout.dart';
import 'classic_ludo_board_definition.dart';

/// Shared geometry contract for the classic Ludo Lovers board.
///
/// Coordinates remain a separate renderer concern; this class validates that
/// a supplied layout covers every logical track and private-lane cell. Safe
/// cell IDs are read from the board definition so renderer audits and local
/// rules cannot silently drift apart. They remain provisional until approved
/// against a clear, straight-on reference board.
class ClassicLudoBoardGeometry {
  const ClassicLudoBoardGeometry._();

  static const int gridSize = ClassicLudoBoardDefinition.gridSize;
  static const int trackLength = ClassicLudoBoardDefinition.sharedTrackLength;
  static const int homeLaneLength = ClassicLudoBoardDefinition.homeLaneLength;

  /// Canonical provisional safe cells, expressed as physical shared-track IDs.
  static Set<int> get safeTrackCellIds =>
      ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;

  /// Logical home-lane ID ranges are derived from canonical seat metadata.
  /// Keep one source of truth when a seat's lane IDs change.
  static Map<String, int> get homeLaneStartByPlayer =>
      Map<String, int>.unmodifiable(<String, int>{
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.homeLaneStartCellId,
      });

  /// Ensures the renderer layout contains every cell used by the route model.
  ///
  /// This deliberately does not generate coordinates: callers must provide
  /// coordinates checked against the approved board diagram.
  static void validateCompleteLayout(BoardCoordinateLayout layout) {
    final requiredIds = <int>{
      ...List<int>.generate(trackLength, (index) => index),
      for (final start in homeLaneStartByPlayer.values)
        ...List<int>.generate(homeLaneLength, (index) => start + index),
    };
    final missing = requiredIds.difference(layout.pointsByCell.keys.toSet());
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'Board layout is missing logical cell IDs: ${missing.toList()..sort()}',
      );
    }

    if (!safeTrackCellIds.every(
      (cellId) => cellId >= 0 && cellId < trackLength,
    )) {
      throw StateError('Safe cells must refer to shared-track cell IDs.');
    }
  }
}
