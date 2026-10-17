import 'package:flutter/material.dart';

import 'board_coordinate_layout.dart';

/// Display quadrant is deliberately independent from turn order.
enum BoardQuadrant { topLeft, topRight, bottomLeft, bottomRight }

/// Grid coordinate for a visual board marker, using column then row.
class BoardGridCell {
  const BoardGridCell({required this.column, required this.row});

  final int column;
  final int row;

  bool get isInsideBoard =>
      column >= 0 && column < ClassicLudoBoardDefinition.gridSize &&
      row >= 0 && row < ClassicLudoBoardDefinition.gridSize;

  @override
  bool operator ==(Object other) =>
      other is BoardGridCell &&
      other.column == column &&
      other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}

/// Immutable identity and presentation metadata for one board seat.
class ClassicLudoSeat {
  const ClassicLudoSeat({
    required this.id,
    required this.quadrant,
    required this.color,
    required this.homeLaneStartCellId,
    required this.yardColumn,
    required this.yardRow,
    required this.laneStart,
    required this.laneEnd,
    required this.homeLaneCells,
    required this.startMarker,
    required this.provisionalTrackEntryIndex,
  });

  final String id;
  final BoardQuadrant quadrant;
  final Color color;
  final int homeLaneStartCellId;

  /// Top-left grid coordinate of the 6x6 yard zone on a 15x15 board.
  final int yardColumn;
  final int yardRow;

  /// Visual lane endpoints and start marker on the 15x15 display grid.
  /// These are presentation anchors, not yet a validated movement route.
  final BoardGridCell laneStart;
  final BoardGridCell laneEnd;
  /// Six physical grid cells ordered from the track edge toward the center.
  final List<BoardGridCell> homeLaneCells;
  final BoardGridCell startMarker;

  /// Provisional player-relative entry offset; do not use for online rules.
  final int provisionalTrackEntryIndex;

  List<int> get homeLaneCellIds => List<int>.unmodifiable(
        List<int>.generate(
          ClassicLudoBoardDefinition.homeLaneLength,
          (i) => homeLaneStartCellId + i,
        ),
      );
}

/// Shared source for seat colors, visual anchors and logical lane identifiers.
///
/// The marker/entry metadata is provisional until it is reconciled with a
/// clean, approved board-cell diagram. Online rules must not consume it.
class ClassicLudoBoardDefinition {
  const ClassicLudoBoardDefinition._();

  static const int gridSize = 15;
  static const int sharedTrackLength = 52;
  static const int homeLaneLength = 6;

  static const List<BoardGridCell> sharedTrackCells = <BoardGridCell>[
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

  static const List<ClassicLudoSeat> seats = <ClassicLudoSeat>[
    ClassicLudoSeat(
      id: 'orange',
      quadrant: BoardQuadrant.topLeft,
      color: LudoBoardPalette.orange,
      homeLaneStartCellId: 200,
      yardColumn: 0,
      yardRow: 0,
      laneStart: BoardGridCell(column: 1, row: 7),
      laneEnd: BoardGridCell(column: 6, row: 7),
      homeLaneCells: <BoardGridCell>[
        BoardGridCell(column: 1, row: 7),
        BoardGridCell(column: 2, row: 7),
        BoardGridCell(column: 3, row: 7),
        BoardGridCell(column: 4, row: 7),
        BoardGridCell(column: 5, row: 7),
        BoardGridCell(column: 6, row: 7),
      ],
      startMarker: BoardGridCell(column: 1, row: 6),
      provisionalTrackEntryIndex: 0,
    ),
    ClassicLudoSeat(
      id: 'green',
      quadrant: BoardQuadrant.topRight,
      color: LudoBoardPalette.green,
      homeLaneStartCellId: 220,
      yardColumn: 9,
      yardRow: 0,
      laneStart: BoardGridCell(column: 7, row: 1),
      laneEnd: BoardGridCell(column: 7, row: 6),
      homeLaneCells: <BoardGridCell>[
        BoardGridCell(column: 7, row: 1),
        BoardGridCell(column: 7, row: 2),
        BoardGridCell(column: 7, row: 3),
        BoardGridCell(column: 7, row: 4),
        BoardGridCell(column: 7, row: 5),
        BoardGridCell(column: 7, row: 6),
      ],
      startMarker: BoardGridCell(column: 8, row: 1),
      provisionalTrackEntryIndex: 13,
    ),
    ClassicLudoSeat(
      id: 'blue',
      quadrant: BoardQuadrant.bottomLeft,
      color: LudoBoardPalette.blue,
      homeLaneStartCellId: 210,
      yardColumn: 0,
      yardRow: 9,
      laneStart: BoardGridCell(column: 7, row: 13),
      laneEnd: BoardGridCell(column: 7, row: 8),
      homeLaneCells: <BoardGridCell>[
        BoardGridCell(column: 7, row: 13),
        BoardGridCell(column: 7, row: 12),
        BoardGridCell(column: 7, row: 11),
        BoardGridCell(column: 7, row: 10),
        BoardGridCell(column: 7, row: 9),
        BoardGridCell(column: 7, row: 8),
      ],
      startMarker: BoardGridCell(column: 6, row: 13),
      provisionalTrackEntryIndex: 39,
    ),
    ClassicLudoSeat(
      id: 'magenta',
      quadrant: BoardQuadrant.bottomRight,
      color: LudoBoardPalette.magenta,
      homeLaneStartCellId: 230,
      yardColumn: 9,
      yardRow: 9,
      laneStart: BoardGridCell(column: 13, row: 7),
      laneEnd: BoardGridCell(column: 8, row: 7),
      homeLaneCells: <BoardGridCell>[
        BoardGridCell(column: 13, row: 7),
        BoardGridCell(column: 12, row: 7),
        BoardGridCell(column: 11, row: 7),
        BoardGridCell(column: 10, row: 7),
        BoardGridCell(column: 9, row: 7),
        BoardGridCell(column: 8, row: 7),
      ],
      startMarker: BoardGridCell(column: 13, row: 8),
      provisionalTrackEntryIndex: 26,
    ),
  ];

  /// These are provisional rules metadata, not yet visually approved.
  static const Set<int> provisionalSafeTrackCellIds = <int>{
    0, 8, 13, 21, 26, 34, 39, 47,
  };

  static ClassicLudoSeat seatFor(String playerId) {
    return seats.firstWhere(
      (seat) => seat.id == playerId,
      orElse: () =>
          throw ArgumentError.value(playerId, 'playerId', 'Unknown board seat'),
    );
  }

  static void validate() {
    if (seats.length != 4 || seats.map((seat) => seat.id).toSet().length != 4) {
      throw StateError('The classic board must define four unique player seats.');
    }
    final laneIds = <int>{};
    final starts = <int>{};
    for (final seat in seats) {
      if (seat.yardColumn < 0 ||
          seat.yardRow < 0 ||
          seat.yardColumn + 6 > gridSize ||
          seat.yardRow + 6 > gridSize) {
        throw StateError('Yard zone for ${seat.id} is outside the board grid.');
      }
      if (!seat.laneStart.isInsideBoard ||
          !seat.laneEnd.isInsideBoard ||
          !seat.startMarker.isInsideBoard) {
        throw StateError('Visual anchors for ${seat.id} are outside the board.');
      }
      if (seat.homeLaneCellIds.length != homeLaneLength ||
          seat.homeLaneCells.length != homeLaneLength ||
          seat.homeLaneCells.any((cell) => !cell.isInsideBoard)) {
        throw StateError('Home lane for ${seat.id} must contain six cells.');
      }
      if (seat.provisionalTrackEntryIndex < 0 ||
          seat.provisionalTrackEntryIndex >= sharedTrackLength ||
          !starts.add(seat.provisionalTrackEntryIndex)) {
        throw StateError('Track entry offsets must be unique valid indexes.');
      }
      for (final id in seat.homeLaneCellIds) {
        if (!laneIds.add(id)) {
          throw StateError('Home-lane cell ID $id is assigned more than once.');
        }
      }
      if (seat.homeLaneCells.toSet().length != homeLaneLength) {
        throw StateError('Home-lane coordinates for ${seat.id} must be unique.');
      }
    }
    if (!provisionalSafeTrackCellIds.every(
      (id) => id >= 0 && id < sharedTrackLength,
    )) {
      throw StateError('Safe-cell metadata must refer to shared-track IDs.');
    }
  }
}
