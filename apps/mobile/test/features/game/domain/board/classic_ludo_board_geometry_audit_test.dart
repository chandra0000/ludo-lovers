import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry_audit.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';

void main() {
  group('ClassicLudoBoardGeometryAudit', () {
    test('recognizes four documented diagonal corners without geometry errors', () {
      final issues = ClassicLudoBoardGeometryAudit.inspect();

      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
      expect(issues, isEmpty);
      expect(ClassicLudoBoardGeometryAudit.isStructurallyConsistent, isTrue);
    });

    test('center finish is in bounds and separate from track and lanes', () {
      const finish = ClassicLudoBoardDefinition.centerFinishCell;
      expect(finish.isInsideBoard, isTrue);
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack, isNot(contains(finish)));
      expect(
        ClassicLudoBoardDefinition.seats.every((seat) => !seat.homeLaneCells.contains(finish)),
        isTrue,
      );
      expect(
        ClassicLudoBoardGeometryAudit.inspect().where((issue) => issue.contains('center finish')),
        isEmpty,
      );
    });

    test('every provisional player start is included in the safe-cell set', () {
      const safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      expect(safeCells, hasLength(8));
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(
          safeCells.contains(seat.provisionalTrackEntryIndex),
          isTrue,
          reason: '${seat.id} start cell must be protected from capture',
        );
      }
      expect(safeCells.every((cell) => cell >= 0 && cell < 52), isTrue);
    });

    test('all four home-lane branches connect to the reference route', () {
      const track = ClassicLudoBoardCoordinateFactory.sharedTrack;
      final paths = ClassicLudoBoardFixture.create();
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.trackLength, 51, reason: seat.id);
        final approach = track[(seat.provisionalTrackEntryIndex + 50) % 52];
        final lane = seat.homeLaneCells.first;
        final dx = (approach.column - lane.column).abs();
        final dy = (approach.row - lane.row).abs();
        expect(
          dx + dy == 1 || (dx == 1 && dy == 1),
          isTrue,
          reason: '${seat.id} must enter its lane through a one-cell '
              'orthogonal or reference-approved diagonal connection',
        );
        expect(path.cellAtProgress(50), (seat.provisionalTrackEntryIndex + 50) % 52, reason: '${seat.id} final shared cell');
        expect(path.cellAtProgress(51), seat.homeLaneStartCellId, reason: '${seat.id} first lane cell');
      }
    });

    test('keeps gameplay readiness disabled until route geometry is approved', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
