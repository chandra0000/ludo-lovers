import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_rule_profile.dart';

void main() {
  group('Canonical board source-of-truth contract', () {
    test('factory uses the canonical 52 physical track cells', () {
      expect(ClassicLudoBoardDefinition.sharedTrackCells, hasLength(52));
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack,
          same(ClassicLudoBoardDefinition.sharedTrackCells));
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack.toSet(), hasLength(52));
    });

    test('fixture entry indexes and home lanes derive from canonical seats', () {
      final paths = ClassicLudoBoardFixture.create();
      expect(ClassicLudoBoardFixture.sharedTrackLength,
          ClassicLudoBoardDefinition.sharedTrackLength);
      expect(ClassicLudoBoardFixture.homeLaneLength,
          ClassicLudoBoardDefinition.homeLaneLength);

      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.entryCell, seat.provisionalTrackEntryIndex,
            reason: '${seat.id} route entry drifted from its seat definition');
        expect(path.homeLaneCells, seat.homeLaneCellIds,
            reason: '${seat.id} logical home lane drifted from its seat definition');
        expect(path.mainTrackCells,
            List<int>.generate(52, (index) =>
                (index + seat.provisionalTrackEntryIndex) % 52));
      }
      expect(
        ClassicLudoBoardFixture.provisionalEntryCellByPlayer,
        <String, int>{
          for (final seat in ClassicLudoBoardDefinition.seats)
            seat.id: seat.provisionalTrackEntryIndex,
        },
      );
    });

    test('geometry and rules profile use the same provisional safe-cell IDs', () {
      final profile = LudoRuleProfile();
      expect(ClassicLudoBoardGeometry.safeTrackCellIds,
          same(ClassicLudoBoardDefinition.provisionalSafeTrackCellIds));
      expect(profile.safeCellIndexes,
          ClassicLudoBoardDefinition.provisionalSafeTrackCellIds);
      expect(
        profile.safeCellIndexes,
        <int>{0, 8, 13, 21, 26, 34, 39, 47},
      );
    });

    test('route remains blocked while the four diagonal transitions remain', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
