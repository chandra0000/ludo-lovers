import 'package:flutter/material.dart';

import 'board_coordinate_layout.dart';

/// Visual seat positions are independent from turn order and path offsets.
enum BoardQuadrant { topLeft, topRight, bottomLeft, bottomRight }

/// Immutable identity and presentation metadata for one board seat.
class ClassicLudoSeat {
  const ClassicLudoSeat({
    required this.id,
    required this.quadrant,
    required this.color,
    required this.homeLaneStartCellId,
    required this.yardColumn,
    required this.yardRow,
  });

  final String id;
  final BoardQuadrant quadrant;
  final Color color;
  final int homeLaneStartCellId;

  /// Top-left grid coordinate of the 6x6 yard zone on a 15x15 board.
  final int yardColumn;
  final int yardRow;

  List<int> get homeLaneCellIds => List<int>.unmodifiable(
        List<int>.generate(6, (i) => homeLaneStartCellId + i),
      );
}

/// The single source of truth for fixed board identity and visual seat placement.
///
/// This deliberately does not invent pixel coordinates or claim that the
/// provisional safe-cell rules have been visually approved.
class ClassicLudoBoardDefinition {
  const ClassicLudoBoardDefinition._();

  static const int gridSize = 15;
  static const int sharedTrackLength = 52;
  static const int homeLaneLength = 6;

  static const List<ClassicLudoSeat> seats = <ClassicLudoSeat>[
    ClassicLudoSeat(
      id: 'orange',
      quadrant: BoardQuadrant.topLeft,
      color: LudoBoardPalette.orange,
      homeLaneStartCellId: 200,
      yardColumn: 0,
      yardRow: 0,
    ),
    ClassicLudoSeat(
      id: 'green',
      quadrant: BoardQuadrant.topRight,
      color: LudoBoardPalette.green,
      homeLaneStartCellId: 220,
      yardColumn: 9,
      yardRow: 0,
    ),
    ClassicLudoSeat(
      id: 'blue',
      quadrant: BoardQuadrant.bottomLeft,
      color: LudoBoardPalette.blue,
      homeLaneStartCellId: 210,
      yardColumn: 0,
      yardRow: 9,
    ),
    ClassicLudoSeat(
      id: 'magenta',
      quadrant: BoardQuadrant.bottomRight,
      color: LudoBoardPalette.magenta,
      homeLaneStartCellId: 230,
      yardColumn: 9,
      yardRow: 9,
    ),
  ];

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
    for (final seat in seats) {
      if (seat.yardColumn < 0 ||
          seat.yardRow < 0 ||
          seat.yardColumn + 6 > gridSize ||
          seat.yardRow + 6 > gridSize) {
        throw StateError('Yard zone for ${seat.id} is outside the board grid.');
      }
      if (seat.homeLaneCellIds.length != homeLaneLength) {
        throw StateError('Home lane for ${seat.id} must contain six cells.');
      }
      for (final id in seat.homeLaneCellIds) {
        if (!laneIds.add(id)) {
          throw StateError('Home-lane cell ID $id is assigned more than once.');
        }
      }
    }
    if (!provisionalSafeTrackCellIds.every(
      (id) => id >= 0 && id < sharedTrackLength,
    )) {
      throw StateError('Safe-cell metadata must refer to shared-track IDs.');
    }
  }
}
