import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('ClassicLudoBoardCoordinateFactory', () {
    test('provides 52 unique in-bounds shared-track cells', () {
      const route = ClassicLudoBoardCoordinateFactory.sharedTrack;
      expect(route, hasLength(52));
      expect(route.toSet(), hasLength(52));
      for (final cell in route) {
        expect(cell.isInsideBoard, isTrue);
      }
    });

    test('reports the four documented diagonal corner links for visual review', () {
      // These four diagonal links are valid neighbouring cells in the independent
      // reference, but do not constitute visual approval of the complete board.
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(
        ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes,
        <int>[4, 17, 30, 43],
        reason: 'Diagonal transitions must block release until the route is corrected.',
      );
      expect(ClassicLudoBoardCoordinateFactory.isOrthogonallyContinuous, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('audits every transition and identifies each orthogonal-continuity blocker', () {
      const route = ClassicLudoBoardCoordinateFactory.sharedTrack;
      final knownBlockers =
          ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes;
      for (var index = 0; index < route.length; index++) {
        final current = route[index];
        final next = route[(index + 1) % route.length];
        final dx = (current.column - next.column).abs();
        final dy = (current.row - next.row).abs();
        if (knownBlockers.contains(index)) {
          expect(dx, 1, reason: 'Diagonal blocker $index must change one column');
          expect(dy, 1, reason: 'Diagonal blocker $index must change one row');
        } else {
          expect(
            dx + dy,
            1,
            reason: 'Transition $index must be orthogonally adjacent',
          );
        }
      }
    });

    test('seat start markers align with their physical shared-track indexes', () {
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final routeCell =
            ClassicLudoBoardCoordinateFactory.sharedTrack[seat.provisionalTrackEntryIndex];
        expect(
          seat.startMarker.column,
          routeCell.column,
          reason: '${seat.id} start column',
        );
        expect(
          seat.startMarker.row,
          routeCell.row,
          reason: '${seat.id} start row',
        );
      }
    });

    test('provisional safe cells include each start and the four offset star cells', () {
      const safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      final entries = ClassicLudoBoardDefinition.seats
          .map((seat) => seat.provisionalTrackEntryIndex)
          .toSet();

      // Classic boards commonly protect each colored start plus a star eight
      // physical cells later. This checks internal consistency only; the IDs
      // remain provisional until visually reconciled with the approved board.
      expect(safeCells, hasLength(8));
      expect(safeCells.containsAll(entries), isTrue);
      expect(
        safeCells,
        entries.expand((entry) => <int>{entry, (entry + 8) % 52}).toSet(),
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('describes route transitions and safe cells with physical coordinates', () {
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(4),
        '4 (5,6) → 5 (6,5)',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(51),
        '51 (0,6) → 0 (1,6)',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTrackCell(13),
        '13 (8,1)',
      );
      expect(
        () => ClassicLudoBoardCoordinateFactory.describeTrackCell(52),
        throwsRangeError,
      );
    });

    test('builds normalized coordinates for track and all private lanes', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      expect(layout.pointsByCell, hasLength(52 + 4 * 5));
      for (var cellId = 0; cellId < 52; cellId++) {
        expect(layout.pointsByCell.containsKey(cellId), isTrue);
      }
      for (final seat in ClassicLudoBoardDefinition.seats) {
        for (final cellId in seat.homeLaneCellIds) {
          expect(layout.pointsByCell.containsKey(cellId), isTrue);
          expect(layout.forCell(cellId).isValid, isTrue);
        }
      }
    });

    test('normalized coordinates match every physical grid-cell center', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      const gridSize = ClassicLudoBoardDefinition.gridSize;

      for (var index = 0;
          index < ClassicLudoBoardCoordinateFactory.sharedTrack.length;
          index++) {
        final cell = ClassicLudoBoardCoordinateFactory.sharedTrack[index];
        final point = layout.forCell(index);
        expect(
          point.x,
          closeTo((cell.column + 0.5) / gridSize, 0.000001),
          reason: 'Track cell $index x-coordinate',
        );
        expect(
          point.y,
          closeTo((cell.row + 0.5) / gridSize, 0.000001),
          reason: 'Track cell $index y-coordinate',
        );
      }

      for (final seat in ClassicLudoBoardDefinition.seats) {
        for (var laneIndex = 0;
            laneIndex < seat.homeLaneCells.length;
            laneIndex++) {
          final cell = seat.homeLaneCells[laneIndex];
          final point = layout.forCell(seat.homeLaneStartCellId + laneIndex);
          expect(
            point.x,
            closeTo((cell.column + 0.5) / gridSize, 0.000001),
            reason: '${seat.id} home lane $laneIndex x-coordinate',
          );
          expect(
            point.y,
            closeTo((cell.row + 0.5) / gridSize, 0.000001),
            reason: '${seat.id} home lane $laneIndex y-coordinate',
          );
        }
      }
    });

    test('home lanes use five distinct in-bounds physical cells per seat', () {
      final track = ClassicLudoBoardCoordinateFactory.sharedTrack.toSet();
      final allLaneCells = <BoardGridCell>{};
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(seat.homeLaneCells, hasLength(5));
        expect(seat.homeLaneCells.toSet(), hasLength(5));
        for (final cell in seat.homeLaneCells) {
          expect(cell.isInsideBoard, isTrue, reason: seat.id);
          expect(
            track.contains(cell),
            isFalse,
            reason: '${seat.id} home lane must not overlap the shared track',
          );
          expect(
            allLaneCells.add(cell),
            isTrue,
            reason: 'Home-lane cells must not overlap between seats',
          );
        }
      }
    });

    test('maps track cell centers consistently across pixel sizes', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      final small = layout.pixelForCell(cellId: 0, width: 300, height: 300);
      final large = layout.pixelForCell(cellId: 0, width: 600, height: 600);
      expect(large.x, closeTo(small.x * 2, 0.000001));
      expect(large.y, closeTo(small.y * 2, 0.000001));
    });

    test('locks the four known diagonal connectors to exact grid coordinates', () {
      const expected = <int, (BoardGridCell, BoardGridCell)>{
        4: (BoardGridCell(column: 5, row: 6), BoardGridCell(column: 6, row: 5)),
        17: (BoardGridCell(column: 8, row: 5), BoardGridCell(column: 9, row: 6)),
        30: (BoardGridCell(column: 9, row: 8), BoardGridCell(column: 8, row: 9)),
        43: (BoardGridCell(column: 6, row: 9), BoardGridCell(column: 5, row: 8)),
      };
      expect(ClassicLudoBoardCoordinateFactory.referenceCornerConnectorIndexes,
          expected.keys.toSet());
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        expected.keys.toList()..sort(),
        reason: 'Any additional or shifted diagonal is a topology regression.',
      );
      for (final connector in expected.entries) {
        expect(ClassicLudoBoardCoordinateFactory.sharedTrack[connector.key],
            connector.value.$1);
        expect(
          ClassicLudoBoardCoordinateFactory.sharedTrack[(connector.key + 1) % 52],
          connector.value.$2,
        );
      }
    });

    test('locks all eight safe-cell IDs to their defined grid coordinates', () {
      const expected = <int, BoardGridCell>{
        0: BoardGridCell(column: 1, row: 6),
        8: BoardGridCell(column: 6, row: 2),
        13: BoardGridCell(column: 8, row: 1),
        21: BoardGridCell(column: 12, row: 6),
        26: BoardGridCell(column: 13, row: 8),
        34: BoardGridCell(column: 8, row: 12),
        39: BoardGridCell(column: 6, row: 13),
        47: BoardGridCell(column: 2, row: 8),
      };
      expect(ClassicLudoBoardDefinition.approvedSafeTrackCellIds,
          expected.keys.toSet());
      for (final safe in expected.entries) {
        expect(ClassicLudoBoardCoordinateFactory.sharedTrack[safe.key], safe.value);
      }
    });

    test('checks every home-lane step and every track-to-lane branch is orthogonal', () {
      const track = ClassicLudoBoardCoordinateFactory.sharedTrack;
      final laneCells = <BoardGridCell>{};
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(seat.homeLaneCells, hasLength(5), reason: seat.id);
        for (var i = 0; i < seat.homeLaneCells.length; i++) {
          final cell = seat.homeLaneCells[i];
          expect(cell.isInsideBoard, isTrue, reason: seat.id);
          expect(track.contains(cell), isFalse, reason: seat.id);
          expect(laneCells.add(cell), isTrue, reason: 'Lanes must not overlap');
          if (i > 0) {
            final previous = seat.homeLaneCells[i - 1];
            expect(
              (cell.column - previous.column).abs() +
                  (cell.row - previous.row).abs(),
              1,
              reason: 'Every lane cell must touch its predecessor orthogonally',
            );
          }
        }
        final approachIndex =
            (seat.provisionalTrackEntryIndex +
                ClassicLudoBoardDefinition.playerTrackLength - 1) %
            ClassicLudoBoardDefinition.sharedTrackLength;
        final approach = track[approachIndex];
        final firstLane = seat.homeLaneCells.first;
        expect(
          (approach.column - firstLane.column).abs() +
              (approach.row - firstLane.row).abs(),
          1,
          reason: 'The route must enter its home lane orthogonally',
        );
      }
    });
  });
}
