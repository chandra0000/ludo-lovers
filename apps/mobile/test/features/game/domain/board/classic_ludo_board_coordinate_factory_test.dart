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

    test('reports the provisional diagonal transitions as a gameplay blocker', () {
      // This is an explicit guard, not approval of the route. The four diagonal
      // transitions must be corrected before movement/hit-testing uses it.
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('only known provisional blockers are non-orthogonal transitions', () {
      const route = ClassicLudoBoardCoordinateFactory.sharedTrack;
      final knownBlockers =
          ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes;
      for (var index = 0; index < route.length; index++) {
        final current = route[index];
        final next = route[(index + 1) % route.length];
        final dx = (current.column - next.column).abs();
        final dy = (current.row - next.row).abs();
        if (knownBlockers.contains(index)) {
          expect(dx + dy, 2, reason: 'Known provisional blocker $index');
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
      expect(layout.pointsByCell, hasLength(52 + 4 * 6));
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

    test('home lanes use six distinct in-bounds physical cells per seat', () {
      final track = ClassicLudoBoardCoordinateFactory.sharedTrack.toSet();
      final allLaneCells = <BoardGridCell>{};
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(seat.homeLaneCells, hasLength(6));
        expect(seat.homeLaneCells.toSet(), hasLength(6));
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
  });
}
