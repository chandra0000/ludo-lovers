import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_rule_profile.dart';

void main() {
  group('Classic board single source of truth', () {
    test('renderer route is the canonical definition route', () {
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack,
          ClassicLudoBoardDefinition.sharedTrackCells);
      expect(ClassicLudoBoardDefinition.sharedTrackCells, hasLength(52));
    });

    test('fixture entry indexes and lanes derive from canonical seats', () {
      final paths = ClassicLudoBoardFixture.create();
      expect(ClassicLudoBoardFixture.sharedTrackLength,
          ClassicLudoBoardDefinition.sharedTrackLength);
      expect(ClassicLudoBoardFixture.homeLaneLength,
          ClassicLudoBoardDefinition.homeLaneLength);
      expect(ClassicLudoBoardFixture.provisionalEntryCellByPlayer, {
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.provisionalTrackEntryIndex,
      });
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.entryCell, seat.provisionalTrackEntryIndex);
        expect(path.homeLaneCells, seat.homeLaneCellIds);
        expect(path.mainTrackCells, List<int>.generate(
          ClassicLudoBoardDefinition.sharedTrackLength,
          (i) => (i + seat.provisionalTrackEntryIndex) %
              ClassicLudoBoardDefinition.sharedTrackLength,
        ));
      }
    });

    test('default rule profile uses canonical provisional safe-cell IDs', () {
      expect(LudoRuleProfile().safeCellIndexes,
          ClassicLudoBoardDefinition.provisionalSafeTrackCellIds);
      expect(LudoRuleProfile().safeCellIndexes, hasLength(8));
    });

    test('rule profile copies custom safe cells and rejects out-of-range IDs', () {
      final supplied = <int>{0, 13};
      final profile = LudoRuleProfile(safeCellIndexes: supplied);
      supplied.add(21);
      expect(profile.safeCellIndexes, <int>{0, 13});
      expect(() => profile.safeCellIndexes.add(26), throwsUnsupportedError);
      expect(() => LudoRuleProfile(safeCellIndexes: <int>{52}),
          throwsArgumentError);
      expect(() => LudoRuleProfile(safeCellIndexes: <int>{-1}),
          throwsArgumentError);
    });

    test('route remains provisional while diagonal jumps remain unresolved', () {
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
