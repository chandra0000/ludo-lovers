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
        const Color(0xFFF15206),
        const Color(0xFF2DF732),
        const Color(0xFF35930F),
        const Color(0xFFF42227),
      ]);
    });

    test('defines separate, unique six-cell home lanes', () {
      final allLaneIds = ClassicLudoBoardDefinition.seats
          .expand((seat) => seat.homeLaneCellIds)
          .toList();
      expect(allLaneIds, hasLength(24));
      expect(allLaneIds.toSet(), hasLength(24));
      expect(ClassicLudoBoardDefinition.seatFor('orange').homeLaneCellIds,
          <int>[200, 201, 202, 203, 204, 205]);
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
