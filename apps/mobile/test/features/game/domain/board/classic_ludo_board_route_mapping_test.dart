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
          ('blue', BoardQuadrant.bottomRight, LudoBoardPalette.blue),
          ('magenta', BoardQuadrant.bottomLeft, LudoBoardPalette.magenta),
        ]),
      );
    });

    test('provisional shared-track coordinate snapshot stays stable pending visual approval', () {
      // This is a regression lock for the current provisional route, not proof
      // that the route matches the final brand artwork. Update only after a
      // reviewed, explicit topology decision.
      final coordinateSnapshot = ClassicLudoBoardCoordinateFactory.sharedTrack
          .map((cell) => '${cell.column},${cell.row}')
          .toList(growable: false);

      expect(coordinateSnapshot, <String>[
        '1,6', '2,6', '3,6', '4,6', '5,6', '6,5', '6,4', '6,3',
        '6,2', '6,1', '6,0', '7,0', '8,0', '8,1', '8,2', '8,3',
        '8,4', '8,5', '9,6', '10,6', '11,6', '12,6', '13,6', '14,6',
        '14,7', '14,8', '13,8', '12,8', '11,8', '10,8', '9,8', '8,9',
        '8,10', '8,11', '8,12', '8,13', '8,14', '7,14', '6,14', '6,13',
        '6,12', '6,11', '6,10', '6,9', '5,8', '4,8', '3,8', '2,8',
        '1,8', '0,8', '0,7', '0,6',
      ]);
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('blue and magenta yards and home lanes match their swapped quadrants', () {
      final blue = ClassicLudoBoardDefinition.seatFor('blue');
      expect(blue.quadrant, BoardQuadrant.bottomRight);
      expect((blue.yardColumn, blue.yardRow), (9, 9));
      expect(blue.startMarker, const BoardGridCell(column: 13, row: 8));
      expect(blue.provisionalTrackEntryIndex, 26);
      expect(
        blue.homeLaneCells,
        const <BoardGridCell>[
          BoardGridCell(column: 13, row: 7),
          BoardGridCell(column: 12, row: 7),
          BoardGridCell(column: 11, row: 7),
          BoardGridCell(column: 10, row: 7),
          BoardGridCell(column: 9, row: 7),
        ],
      );

      final magenta = ClassicLudoBoardDefinition.seatFor('magenta');
      expect(magenta.quadrant, BoardQuadrant.bottomLeft);
      expect((magenta.yardColumn, magenta.yardRow), (0, 9));
      expect(magenta.startMarker, const BoardGridCell(column: 6, row: 13));
      expect(magenta.provisionalTrackEntryIndex, 39);
      expect(
        magenta.homeLaneCells,
        const <BoardGridCell>[
          BoardGridCell(column: 7, row: 13),
          BoardGridCell(column: 7, row: 12),
          BoardGridCell(column: 7, row: 11),
          BoardGridCell(column: 7, row: 10),
          BoardGridCell(column: 7, row: 9),
        ],
      );
    });

    test('logical route entry offsets derive from the shared seat definition', () {
      final entries = ClassicLudoBoardFixture.provisionalEntryCellByPlayer;

      expect(entries, {
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.provisionalTrackEntryIndex,
      });
      expect(entries, {'orange': 0, 'green': 13, 'blue': 26, 'magenta': 39});
    });

    test('each seat route has 52 unique cells and a five-cell home lane', () {
      final paths = ClassicLudoBoardFixture.create();

      expect(paths.pathsByPlayer, hasLength(4));
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.mainTrackCells, hasLength(52), reason: seat.id);
        expect(path.mainTrackCells.toSet(), hasLength(52), reason: seat.id);
        expect(path.homeLaneCells, hasLength(5), reason: seat.id);
        expect(path.entryCell, seat.provisionalTrackEntryIndex, reason: seat.id);
        expect(path.cellAtProgress(0), seat.provisionalTrackEntryIndex);
        expect(
          path.cellAtProgress(51),
          (seat.provisionalTrackEntryIndex + 51) % 52,
        );
        expect(path.cellAtProgress(52), seat.homeLaneStartCellId);
        expect(path.cellAtProgress(56), seat.homeLaneStartCellId + 4);
        expect(path.cellAtProgress(57), isNull);
      }
    });


    test('provisional safe cells are four starts plus four eight-step stars', () {
      final safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds
          .toList()
        ..sort();

      // Explicitly records the current classic-rule hypothesis; it does not
      // mark the board route as visually approved.
      expect(safeCells, <int>[0, 8, 13, 21, 26, 34, 39, 47]);
      expect(safeCells, hasLength(8));
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(
          ClassicLudoBoardDefinition.provisionalSafeTrackCellIds
              .contains(seat.provisionalTrackEntryIndex),
          isTrue,
          reason: '${seat.id} start square must be protected in this profile',
        );
        expect(
          ClassicLudoBoardDefinition.provisionalSafeTrackCellIds
              .contains((seat.provisionalTrackEntryIndex + 8) % 52),
          isTrue,
          reason: '${seat.id} star square hypothesis must be protected',
        );
      }
    });

    test('coordinate route remains gated until non-orthogonal transitions are fixed', () {
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack, hasLength(52));
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        isNotEmpty,
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
