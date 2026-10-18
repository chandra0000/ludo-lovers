import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/board_coordinate_layout.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry.dart';

void main() {
  group('ClassicLudoBoardGeometry', () {
    test('defines the classic grid and provisional safe cells', () {
      expect(ClassicLudoBoardGeometry.gridSize, 15);
      expect(ClassicLudoBoardGeometry.trackLength, 52);
      expect(ClassicLudoBoardGeometry.homeLaneLength, 5);
      expect(ClassicLudoBoardGeometry.safeTrackCellIds, hasLength(8));
      expect(
        ClassicLudoBoardGeometry.safeTrackCellIds,
        containsAll(<int>[0, 13, 26, 39]),
      );
    });

    test('uses the board definition as the single safe-cell source of truth', () {
      expect(
        ClassicLudoBoardGeometry.safeTrackCellIds,
        same(ClassicLudoBoardDefinition.provisionalSafeTrackCellIds),
      );
      expect(
        ClassicLudoBoardGeometry.safeTrackCellIds,
        <int>{0, 8, 13, 21, 26, 34, 39, 47},
      );
    });

    test('derives home-lane logical ID starts from canonical seat metadata', () {
      expect(
        ClassicLudoBoardGeometry.homeLaneStartByPlayer,
        <String, int>{
          for (final seat in ClassicLudoBoardDefinition.seats)
            seat.id: seat.homeLaneStartCellId,
        },
      );
    });

    test('validates a layout that covers track and all four home lanes', () {
      final points = <int, BoardPoint>{
        for (var cell = 0; cell < 52; cell++)
          cell: BoardPoint(x: (cell % 15) / 14, y: (cell ~/ 15) / 14),
        for (final start in ClassicLudoBoardGeometry.homeLaneStartByPlayer.values)
          for (var offset = 0; offset < 5; offset++)
            start + offset: BoardPoint(
              x: ((start + offset) % 15) / 14,
              y: (((start + offset) ~/ 15) % 15) / 14,
            ),
      };

      expect(
        () => ClassicLudoBoardGeometry.validateCompleteLayout(
          BoardCoordinateLayout(points),
        ),
        returnsNormally,
      );
    });

    test('rejects layouts missing a logical cell', () {
      final points = <int, BoardPoint>{
        for (var cell = 0; cell < 52; cell++)
          cell: const BoardPoint(x: 0.5, y: 0.5),
        for (final start in ClassicLudoBoardGeometry.homeLaneStartByPlayer.values)
          for (var offset = 0; offset < 6; offset++)
            if (start + offset != 234)
              start + offset: const BoardPoint(x: 0.5, y: 0.5),
      };

      expect(
        () => ClassicLudoBoardGeometry.validateCompleteLayout(
          BoardCoordinateLayout(points),
        ),
        throwsArgumentError,
      );
    });
  });
}
