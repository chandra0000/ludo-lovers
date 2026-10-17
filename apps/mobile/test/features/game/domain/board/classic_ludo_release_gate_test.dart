import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry_audit.dart';

void main() {
  group('Classic Ludo release gate', () {
    test('keeps release gameplay disabled while route has diagonal jumps', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
      expect(ClassicLudoBoardGeometryAudit.isStructurallyConsistent, isFalse);
    });

    test('provisional safe-cell IDs are unique and within the 52-cell track', () {
      const safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      expect(safeCells, hasLength(8));
      expect(
        safeCells.every(
          (cellId) =>
              cellId >= 0 &&
              cellId < ClassicLudoBoardDefinition.sharedTrackLength,
        ),
        isTrue,
      );
    });

    test('each seat entry is marked safe but remains provisional', () {
      const safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(
          safeCells.contains(seat.provisionalTrackEntryIndex),
          isTrue,
          reason: '${seat.id} entry should be protected in the current test profile',
        );
      }

      // Entry protection is only a consistency check. It must not accidentally
      // approve the route or turn provisional safe-cell metadata into release rules.
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('geometry audit reports every non-orthogonal transition', () {
      final issues = ClassicLudoBoardGeometryAudit.inspect();
      final routeIssues = issues
          .where((issue) => issue.contains('not orthogonally adjacent'))
          .toList(growable: false);

      expect(routeIssues, hasLength(4));
      expect(routeIssues.join('\n'), contains('Track transition 4 to 5'));
      expect(routeIssues.join('\n'), contains('Track transition 17 to 18'));
      expect(routeIssues.join('\n'), contains('Track transition 30 to 31'));
      expect(routeIssues.join('\n'), contains('Track transition 43 to 44'));
    });
  });
}
