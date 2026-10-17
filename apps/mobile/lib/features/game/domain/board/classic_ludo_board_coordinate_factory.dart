import 'board_coordinate_layout.dart';
import 'classic_ludo_board_definition.dart';

/// Provisional 15x15 grid route used to unify rendering and hit-testing.
///
/// Coordinates use (column, row) with the origin at the top-left. The route
/// follows a conventional 52-cell loop; it is not yet approved against the
/// supplied visual reference and must not be treated as a final rules profile.
class ClassicLudoBoardCoordinateFactory {
  const ClassicLudoBoardCoordinateFactory._();

  static const List<BoardGridCell> sharedTrack = <BoardGridCell>[
    BoardGridCell(column: 1, row: 6),
    BoardGridCell(column: 2, row: 6),
    BoardGridCell(column: 3, row: 6),
    BoardGridCell(column: 4, row: 6),
    BoardGridCell(column: 5, row: 6),
    BoardGridCell(column: 6, row: 5),
    BoardGridCell(column: 6, row: 4),
    BoardGridCell(column: 6, row: 3),
    BoardGridCell(column: 6, row: 2),
    BoardGridCell(column: 6, row: 1),
    BoardGridCell(column: 6, row: 0),
    BoardGridCell(column: 7, row: 0),
    BoardGridCell(column: 8, row: 0),
    BoardGridCell(column: 8, row: 1),
    BoardGridCell(column: 8, row: 2),
    BoardGridCell(column: 8, row: 3),
    BoardGridCell(column: 8, row: 4),
    BoardGridCell(column: 8, row: 5),
    BoardGridCell(column: 9, row: 6),
    BoardGridCell(column: 10, row: 6),
    BoardGridCell(column: 11, row: 6),
    BoardGridCell(column: 12, row: 6),
    BoardGridCell(column: 13, row: 6),
    BoardGridCell(column: 14, row: 6),
    BoardGridCell(column: 14, row: 7),
    BoardGridCell(column: 14, row: 8),
    BoardGridCell(column: 13, row: 8),
    BoardGridCell(column: 12, row: 8),
    BoardGridCell(column: 11, row: 8),
    BoardGridCell(column: 10, row: 8),
    BoardGridCell(column: 9, row: 8),
    BoardGridCell(column: 8, row: 9),
    BoardGridCell(column: 8, row: 10),
    BoardGridCell(column: 8, row: 11),
    BoardGridCell(column: 8, row: 12),
    BoardGridCell(column: 8, row: 13),
    BoardGridCell(column: 8, row: 14),
    BoardGridCell(column: 7, row: 14),
    BoardGridCell(column: 6, row: 14),
    BoardGridCell(column: 6, row: 13),
    BoardGridCell(column: 6, row: 12),
    BoardGridCell(column: 6, row: 11),
    BoardGridCell(column: 6, row: 10),
    BoardGridCell(column: 6, row: 9),
    BoardGridCell(column: 5, row: 8),
    BoardGridCell(column: 4, row: 8),
    BoardGridCell(column: 3, row: 8),
    BoardGridCell(column: 2, row: 8),
    BoardGridCell(column: 1, row: 8),
    BoardGridCell(column: 0, row: 8),
    BoardGridCell(column: 0, row: 7),
    BoardGridCell(column: 0, row: 6),
  ];

  /// Indexes whose next route cell is diagonal rather than orthogonally adjacent.
  ///
  /// A non-empty result means this provisional route must not drive movement,
  /// hit-testing, or capture rules yet.
  static List<int> get nonOrthogonalTransitionIndexes {
    final indexes = <int>[];
    for (var index = 0; index < sharedTrack.length; index++) {
      final current = sharedTrack[index];
      final next = sharedTrack[(index + 1) % sharedTrack.length];
      final dx = (current.column - next.column).abs();
      final dy = (current.row - next.row).abs();
      if (dx + dy != 1) indexes.add(index);
    }
    return List<int>.unmodifiable(indexes);
  }

  /// Human-readable coordinates for reviewing a route transition in the audit UI.
  ///
  /// IDs are physical shared-track indexes. This reports geometry only; it
  /// does not decide whether a transition is valid under the approved rules.
  static String describeTransition(int index) {
    if (index < 0 || index >= sharedTrack.length) {
      throw RangeError.index(index, sharedTrack, 'index');
    }
    final nextIndex = (index + 1) % sharedTrack.length;
    final from = sharedTrack[index];
    final to = sharedTrack[nextIndex];
    return '$index (${from.column},${from.row}) → '
        '$nextIndex (${to.column},${to.row})';
  }

  /// Human-readable coordinate for a physical shared-track cell.
  static String describeTrackCell(int index) {
    if (index < 0 || index >= sharedTrack.length) {
      throw RangeError.index(index, sharedTrack, 'index');
    }
    final cell = sharedTrack[index];
    return '$index (${cell.column},${cell.row})';
  }

  /// Conservative release gate for consuming this geometry in game rules.
  ///
  /// This deliberately remains false while the route contains diagonal jumps.
  /// The final route must be reconciled with a reviewed board-cell diagram.
  static bool get isGameplayReady {
    if (sharedTrack.length != ClassicLudoBoardDefinition.sharedTrackLength ||
        sharedTrack.toSet().length != sharedTrack.length ||
        !sharedTrack.every((cell) => cell.isInsideBoard) ||
        nonOrthogonalTransitionIndexes.isNotEmpty) {
      return false;
    }

    final safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
    if (!safeCells.every((id) => id >= 0 && id < sharedTrack.length)) {
      return false;
    }

    // A player's entry cell must be the same physical cell as their marker,
    // and must be protected under the selected rules profile.
    for (final seat in ClassicLudoBoardDefinition.seats) {
      final entry = seat.provisionalTrackEntryIndex;
      if (entry < 0 ||
          entry >= sharedTrack.length ||
          seat.startMarker != sharedTrack[entry] ||
          !safeCells.contains(entry)) {
        return false;
      }
    }

    // A track must not reuse a physical cell as part of a private home lane.
    final trackCells = sharedTrack.toSet();
    for (final seat in ClassicLudoBoardDefinition.seats) {
      if (seat.homeLaneCells.length !=
              ClassicLudoBoardDefinition.homeLaneLength ||
          seat.homeLaneCells.toSet().length != seat.homeLaneCells.length ||
          seat.homeLaneCells.any(
            (cell) => !cell.isInsideBoard || trackCells.contains(cell),
          )) {
        return false;
      }
    }

    return true;
  }

  static BoardCoordinateLayout create() {
    if (sharedTrack.length != ClassicLudoBoardDefinition.sharedTrackLength) {
      throw StateError('The shared route must contain exactly 52 cells.');
    }

    final points = <int, BoardPoint>{};
    for (var index = 0; index < sharedTrack.length; index++) {
      final cell = sharedTrack[index];
      if (!cell.isInsideBoard) {
        throw StateError('Track cell $index is outside the 15x15 board.');
      }
      points[index] = BoardPoint(
        x: (cell.column + 0.5) / ClassicLudoBoardDefinition.gridSize,
        y: (cell.row + 0.5) / ClassicLudoBoardDefinition.gridSize,
      );
    }

    for (final seat in ClassicLudoBoardDefinition.seats) {
      for (var index = 0; index < seat.homeLaneCells.length; index++) {
        final cell = seat.homeLaneCells[index];
        final cellId = seat.homeLaneStartCellId + index;
        points[cellId] = BoardPoint(
          x: (cell.column + 0.5) / ClassicLudoBoardDefinition.gridSize,
          y: (cell.row + 0.5) / ClassicLudoBoardDefinition.gridSize,
        );
      }
    }

    return BoardCoordinateLayout(points);
  }
}
