import 'board_coordinate_layout.dart';

/// Shared geometry contract for the classic Ludo Lovers board.
///
/// Coordinates remain a separate renderer concern; this class validates that
/// a supplied layout covers every logical track and private-lane cell. The
/// safe-cell indexes follow the current provisional 52-cell rules profile and
/// must be checked against the approved board reference before gameplay ships.
class ClassicLudoBoardGeometry {
  const ClassicLudoBoardGeometry._();

  static const int gridSize = 15;
  static const int trackLength = 52;
  static const int homeLaneLength = 6;

  /// Four start cells plus four star/safe cells in global track coordinates.
  static const Set<int> safeTrackCellIds = <int>{
    0, 8, 13, 21, 26, 34, 39, 47,
  };

  static const Map<String, int> homeLaneStartByPlayer = <String, int>{
    'orange': 200,
    'blue': 210,
    'green': 220,
    'magenta': 230,
  };

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

    if (!safeTrackCellIds.every((cellId) => cellId >= 0 && cellId < trackLength)) {
      throw StateError('Safe cells must refer to shared-track cell IDs.');
    }
  }
}
