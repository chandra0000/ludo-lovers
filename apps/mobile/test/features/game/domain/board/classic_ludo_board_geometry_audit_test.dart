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

    test('all four home-lane branches are orthogonally connected', () {
      const track = ClassicLudoBoardCoordinateFactory.sharedTrack;
      final paths = ClassicLudoBoardFixture.create();
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.trackLength, 51, reason: seat.id);
        final approach = track[(seat.provisionalTrackEntryIndex + 50) % 52];
        final lane = seat.homeLaneCells.first;
        expect(
          (approach.column - lane.column).abs() + (approach.row - lane.row).abs(),
          1,
          reason: '${seat.id} must turn into its lane without a gap or diagonal jump',
        );
        expect(path.cellAtProgress(51), seat.homeLaneStartCellId, reason: seat.id);
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
