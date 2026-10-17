import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('Provisional safe-square contract', () {
    test('all four entry squares are included in the safe-cell set', () {
      final entries = ClassicLudoBoardDefinition.seats
          .map((seat) => seat.provisionalTrackEntryIndex)
          .toSet();

      expect(entries, <int>{0, 13, 26, 39});
      expect(
        ClassicLudoBoardDefinition.provisionalSafeTrackCellIds
            .intersection(entries),
        entries,
      );
    });

    test('the additional four star cells are unique and in range', () {
      const starts = <int>{0, 13, 26, 39};
      final safe = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
      final stars = safe.difference(starts);

      expect(safe, hasLength(8));
      expect(stars, <int>{8, 21, 34, 47});
      expect(stars.every((id) => id >= 0 && id < 52), isTrue);
    });

    test('safe-cell coordinates resolve through the shared board layout', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      for (final safeId
          in ClassicLudoBoardDefinition.provisionalSafeTrackCellIds) {
        expect(layout.pointsByCell.containsKey(safeId), isTrue);
        expect(layout.forCell(safeId).isValid, isTrue);
      }
    });

    test('the geometry release gate stays closed while diagonal jumps remain', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
