import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('ClassicLudoBoardDefinition', () {
    test('preserves the approved quadrant order and exact brand colors', () {
      ClassicLudoBoardDefinition.validate();
      const seats = ClassicLudoBoardDefinition.seats;
      expect(seats.map((seat) => seat.id).toList(),
          <String>['orange', 'green', 'blue', 'magenta']);
      expect(seats.map((seat) => seat.quadrant).toList(), <BoardQuadrant>[
        BoardQuadrant.topLeft,
        BoardQuadrant.topRight,
        BoardQuadrant.bottomLeft,
        BoardQuadrant.bottomRight,
      ]);
      expect(seats.map((seat) => seat.color).toList(), <Color>[
        const Color(0xFFFF8928),
        const Color(0xFF33FF28),
        const Color(0xFF289EFF),
        const Color(0xFFF428FF),
      ]);
    });

    test('keeps blue bottom-left and magenta bottom-right after seat correction', () {
      final blue = ClassicLudoBoardDefinition.seatFor('blue');
      final magenta = ClassicLudoBoardDefinition.seatFor('magenta');

      expect(blue.quadrant, BoardQuadrant.bottomLeft);
      expect(blue.yardColumn, 0);
      expect(blue.yardRow, 9);
      expect(blue.provisionalTrackEntryIndex, 39);
      expect(blue.startMarker, const BoardGridCell(column: 6, row: 13));
      expect(
        blue.homeLaneCells,
        const <BoardGridCell>[
          BoardGridCell(column: 7, row: 13),
          BoardGridCell(column: 7, row: 12),
          BoardGridCell(column: 7, row: 11),
          BoardGridCell(column: 7, row: 10),
          BoardGridCell(column: 7, row: 9),
        ],
      );

      expect(magenta.quadrant, BoardQuadrant.bottomRight);
      expect(magenta.yardColumn, 9);
      expect(magenta.yardRow, 9);
      expect(magenta.provisionalTrackEntryIndex, 26);
      expect(magenta.startMarker, const BoardGridCell(column: 13, row: 8));
      expect(
        magenta.homeLaneCells,
        const <BoardGridCell>[
          BoardGridCell(column: 13, row: 7),
          BoardGridCell(column: 12, row: 7),
          BoardGridCell(column: 11, row: 7),
          BoardGridCell(column: 10, row: 7),
          BoardGridCell(column: 9, row: 7),
        ],
      );
    });

    test('defines separate, unique five-cell home lanes', () {
      final allLaneIds = ClassicLudoBoardDefinition.seats
          .expand((seat) => seat.homeLaneCellIds)
          .toList();
      expect(allLaneIds, hasLength(20));
      expect(allLaneIds.toSet(), hasLength(20));
      expect(ClassicLudoBoardDefinition.seatFor('orange').homeLaneCellIds,
          <int>[200, 201, 202, 203, 204]);
    });

    test('defines a separate center finish outside the home lanes', () {
      expect(ClassicLudoBoardDefinition.centerFinishCell, const BoardGridCell(column: 7, row: 7));
      expect(ClassicLudoBoardDefinition.seats.every((seat) => !seat.homeLaneCells.contains(ClassicLudoBoardDefinition.centerFinishCell)), isTrue);
    });

    test('defines four unique in-bounds visual anchors', () {
      const seats = ClassicLudoBoardDefinition.seats;
      expect(
        seats.map((seat) => seat.provisionalTrackEntryIndex).toSet(),
        hasLength(4),
      );
      for (final seat in seats) {
        expect(seat.laneStart.isInsideBoard, isTrue, reason: seat.id);
        expect(seat.laneEnd.isInsideBoard, isTrue, reason: seat.id);
        expect(seat.startMarker.isInsideBoard, isTrue, reason: seat.id);
      }
      expect(seats.map((seat) => seat.startMarker).toSet(), hasLength(4));
    });

    test('keeps safe cells explicitly provisional', () {
      expect(ClassicLudoBoardDefinition.provisionalSafeTrackCellIds, hasLength(8));
      expect(
        ClassicLudoBoardDefinition.provisionalSafeTrackCellIds.every(
          (id) => id >= 0 && id < ClassicLudoBoardDefinition.sharedTrackLength,
        ),
        isTrue,
      );
    });

    test('rejects unknown seat identifiers', () {
      expect(
        () => ClassicLudoBoardDefinition.seatFor('purple'),
        throwsArgumentError,
      );
    });
  });
}
