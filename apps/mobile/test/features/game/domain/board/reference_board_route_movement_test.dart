import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';

void main() {
  group('Reference board route movement', () {
    const track = ClassicLudoBoardCoordinateFactory.sharedTrack;

    test('shared loop has 52 unique in-bounds cells and closes correctly', () {
      expect(track, hasLength(52));
      expect(track.toSet(), hasLength(52));
      expect(track.every((cell) => cell.isInsideBoard), isTrue);
      for (var index = 0; index < track.length; index++) {
        final from = track[index];
        final to = track[(index + 1) % track.length];
        final dx = (from.column - to.column).abs();
        final dy = (from.row - to.row).abs();
        final orthogonal = dx + dy == 1;
        final referenceCorner = const <int>{4, 17, 30, 43}.contains(index) && dx == 1 && dy == 1;
        expect(orthogonal || referenceCorner, isTrue, reason: 'invalid transition $index -> ${(index + 1) % track.length}');
      }
    });

    test('entry markers match Orange 0, Green 13, Magenta 26, Blue 39', () {
      const expected = <String, int>{'orange': 0, 'green': 13, 'magenta': 26, 'blue': 39};
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final index = expected[seat.id];
        expect(index, isNotNull, reason: 'unexpected seat ${seat.id}');
        expect(seat.provisionalTrackEntryIndex, index, reason: seat.id);
        expect(track[index!], seat.startMarker, reason: seat.id);
      }
    });

    test('every player route exposes each intermediate cell, including wraparound', () {
      final paths = ClassicLudoBoardFixture.create();
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.mainTrackCells, hasLength(52), reason: seat.id);
        for (var progress = 0; progress < 50; progress++) {
          expect(path.cellAtProgress(progress), (seat.provisionalTrackEntryIndex + progress) % 52, reason: '${seat.id} progress $progress');
          expect(path.cellAtProgress(progress + 1), (seat.provisionalTrackEntryIndex + progress + 1) % 52, reason: '${seat.id} intermediate step ${progress + 1}');
        }
        expect(path.cellAtProgress(50), (seat.provisionalTrackEntryIndex + 50) % 52, reason: '${seat.id} shared-track step 50');
        expect(path.cellAtProgress(51), seat.homeLaneStartCellId, reason: '${seat.id} must turn into its lane before the outer corner');
        for (var laneIndex = 0; laneIndex < seat.homeLaneCellIds.length; laneIndex++) {
          expect(path.cellAtProgress(51 + laneIndex), seat.homeLaneCellIds[laneIndex], reason: '${seat.id} home-lane intermediate step $laneIndex');
        }
        expect(path.cellAtProgress(path.finishProgress), isNull, reason: 'center finish remains separate from track/lane cells');
      }
    });

    test('Blue pawn follows its route through wraparound into its own lane', () {
      final bluePath = ClassicLudoBoardFixture.create().forPlayer('blue');

      // Blue enters at physical cell 39, follows the shared loop in order,
      // wraps from cell 51 to cell 0, then branches into Blue's private lane.
      expect(bluePath.entryCell, 39);
      expect(bluePath.cellAtProgress(0), 39);
      expect(bluePath.cellAtProgress(1), 40);
      expect(bluePath.cellAtProgress(11), 50);
      expect(bluePath.cellAtProgress(12), 51);
      expect(bluePath.cellAtProgress(13), 0);

      // Blue turns directly from cell 37 (7,14) into its lane; cell 38
      // (6,14), the outer corner beside the lane entrance, is skipped.
      expect(bluePath.cellAtProgress(50), 37);
      expect(track[37], const BoardGridCell(column: 7, row: 14));
      expect(bluePath.cellAtProgress(51), 210);
      expect(
        ClassicLudoBoardDefinition.seatFor('blue').homeLaneCells.first,
        const BoardGridCell(column: 7, row: 13),
      );
      expect(bluePath.cellAtProgress(55), 214);
      expect(bluePath.cellAtProgress(bluePath.finishProgress), isNull);
    });

    test('all home lanes have five unique, in-bounds, connected cells', () {
      final allLaneCells = <BoardGridCell>{};
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final lane = seat.homeLaneCells;
        expect(lane, hasLength(5), reason: seat.id);
        expect(lane.toSet(), hasLength(5), reason: seat.id);
        expect(lane.every((cell) => cell.isInsideBoard), isTrue, reason: seat.id);
        expect(lane.first, seat.laneStart, reason: seat.id);
        expect(lane.last, seat.laneEnd, reason: seat.id);
        for (var index = 0; index + 1 < lane.length; index++) {
          final dx = (lane[index].column - lane[index + 1].column).abs();
          final dy = (lane[index].row - lane[index + 1].row).abs();
          expect(dx + dy, 1, reason: '${seat.id} lane cells $index and ${index + 1}');
        }
        for (final cell in lane) {
          expect(allLaneCells.add(cell), isTrue, reason: 'home lanes overlap at $cell');
          expect(track.contains(cell), isFalse, reason: '${seat.id} lane overlaps shared track');
        }
        final approachIndex = (seat.provisionalTrackEntryIndex + 50) % 52;
        final approach = track[approachIndex];
        final firstLane = lane.first;
        final dx = (approach.column - firstLane.column).abs();
        final dy = (approach.row - firstLane.row).abs();
        expect(dx + dy == 1 || (dx == 1 && dy == 1), isTrue, reason: '${seat.id} lane entry must be a direct reference-board connection');
      }
      expect(allLaneCells, hasLength(20));
    });

    test('safe cells, board bounds and center finish remain consistent', () {
      const safe = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      expect(safe, <int>{0, 8, 13, 21, 26, 34, 39, 47});
      expect(safe.every((id) => id >= 0 && id < track.length), isTrue);
      expect(track.contains(ClassicLudoBoardDefinition.centerFinishCell), isFalse);
      expect(ClassicLudoBoardDefinition.seats.every((seat) => !seat.homeLaneCells.contains(ClassicLudoBoardDefinition.centerFinishCell)), isTrue);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
