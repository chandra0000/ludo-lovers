import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/board_coordinate_layout.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';

void main() {
  group('Classic Ludo route mapping', () {
    test('Ludo Lovers brand palette stays exact', () {
      expect(LudoBoardPalette.orange, const Color(0xFFFF8928));
      expect(LudoBoardPalette.green, const Color(0xFF33FF28));
      expect(LudoBoardPalette.blue, const Color(0xFF289EFF));
      expect(LudoBoardPalette.magenta, const Color(0xFFF428FF));
      expect(LudoBoardPalette.gold, const Color(0xFFFFD700));
      expect(LudoBoardPalette.red, const Color(0xFFFF3830));
      expect(LudoBoardPalette.black, const Color(0xFF080B0B));
      expect(LudoBoardPalette.cream, const Color(0xFFFFF8E1));
    });

    test('brand colors stay assigned to the intended board quadrants', () {
      final seatColors = ClassicLudoBoardDefinition.seats.map(
        (seat) => (seat.id, seat.quadrant, seat.color),
      );
      expect(
        seatColors,
        containsAll(<(String, BoardQuadrant, Color)>[
          ('orange', BoardQuadrant.topLeft, LudoBoardPalette.orange),
          ('green', BoardQuadrant.topRight, LudoBoardPalette.green),
          ('blue', BoardQuadrant.bottomLeft, LudoBoardPalette.blue),
          ('magenta', BoardQuadrant.bottomRight, LudoBoardPalette.magenta),
        ]),
      );
    });

    test('logical route entry offsets derive from the shared seat definition', () {
      final entries = ClassicLudoBoardFixture.provisionalEntryCellByPlayer;

      expect(entries, {
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.provisionalTrackEntryIndex,
      });
      expect(entries, {'orange': 0, 'green': 13, 'blue': 39, 'magenta': 26});
    });

    test('each seat route has 52 unique cells and a six-cell home lane', () {
      final paths = ClassicLudoBoardFixture.create();

      expect(paths.pathsByPlayer, hasLength(4));
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.mainTrackCells, hasLength(52), reason: seat.id);
        expect(path.mainTrackCells.toSet(), hasLength(52), reason: seat.id);
        expect(path.homeLaneCells, hasLength(6), reason: seat.id);
        expect(path.entryCell, seat.provisionalTrackEntryIndex, reason: seat.id);
        expect(path.cellAtProgress(0), seat.provisionalTrackEntryIndex);
        expect(
          path.cellAtProgress(51),
          (seat.provisionalTrackEntryIndex + 51) % 52,
        );
        expect(path.cellAtProgress(52), seat.homeLaneStartCellId);
        expect(path.cellAtProgress(57), seat.homeLaneStartCellId + 5);
        expect(path.cellAtProgress(58), isNull);
      }
    });

    test('coordinate route remains gated until non-orthogonal transitions are fixed', () {
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack, hasLength(52));
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
