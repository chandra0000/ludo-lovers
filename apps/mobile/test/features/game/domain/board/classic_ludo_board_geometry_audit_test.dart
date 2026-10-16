import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry_audit.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('ClassicLudoBoardGeometryAudit', () {
    test('reports every non-orthogonal shared-track transition', () {
      final issues = ClassicLudoBoardGeometryAudit.inspect();

      expect(
        issues.where((issue) => issue.contains('not orthogonally adjacent')),
        <String>[
          'Track transition 4 to 5 is not orthogonally adjacent.',
          'Track transition 17 to 18 is not orthogonally adjacent.',
          'Track transition 30 to 31 is not orthogonally adjacent.',
          'Track transition 43 to 44 is not orthogonally adjacent.',
        ],
      );
      expect(issues, hasLength(4));
      expect(ClassicLudoBoardGeometryAudit.isStructurallyConsistent, isFalse);
    });

    test('every provisional player start is included in the safe-cell set', () {
      final safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
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

    test('keeps gameplay readiness disabled until route geometry is approved', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
