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
      final dx = seat.laneEnd.column - seat.laneStart.column;
      final dy = seat.laneEnd.row - seat.laneStart.row;
      for (var index = 0; index < ClassicLudoBoardDefinition.homeLaneLength; index++) {
        final fraction = (index + 1) / ClassicLudoBoardDefinition.homeLaneLength;
        final cellId = seat.homeLaneStartCellId + index;
        points[cellId] = BoardPoint(
          x: (seat.laneStart.column + dx * fraction + 0.5) /
              ClassicLudoBoardDefinition.gridSize,
          y: (seat.laneStart.row + dy * fraction + 0.5) /
              ClassicLudoBoardDefinition.gridSize,
        );
      }
    }

    return BoardCoordinateLayout(points);
  }
}
