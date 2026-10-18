import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry_audit.dart';

void main() {
  group('Classic Ludo release gate', () {
    test('keeps release gameplay disabled until visual approval', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
      expect(ClassicLudoBoardGeometryAudit.isStructurallyConsistent, isTrue);
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

    test('geometry audit recognizes the four documented diagonal corners', () {
      final issues = ClassicLudoBoardGeometryAudit.inspect();

      expect(issues, isEmpty);
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
    });
  });
}
