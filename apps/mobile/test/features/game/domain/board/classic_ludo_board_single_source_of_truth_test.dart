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

    test('canonical definition validates entries, lanes, safe cells and finish', () {
      expect(ClassicLudoBoardDefinition.validate, returnsNormally);
      expect(ClassicLudoBoardDefinition.centerFinishCell,
          const BoardGridCell(column: 7, row: 7));
      expect(
        ClassicLudoBoardDefinition.sharedTrackCells
            .contains(ClassicLudoBoardDefinition.centerFinishCell),
        isFalse,
        reason: 'The centre finish is separate from the 52-cell track.',
      );

      final paths = ClassicLudoBoardFixture.create();
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final entry = seat.provisionalTrackEntryIndex;
        expect(
          seat.startMarker,
          ClassicLudoBoardCoordinateFactory.sharedTrack[entry],
          reason: '${seat.id} entry marker and route index must match.',
        );
        expect(LudoRuleProfile().safeCellIndexes.contains(entry), isTrue);
        expect(paths.forPlayer(seat.id).entryCell, entry);
        expect(seat.homeLaneCells, hasLength(5));
        expect(seat.homeLaneCells.toSet().length, 5);
        expect(seat.homeLaneCells.first, seat.laneStart, reason: seat.id);
        expect(seat.homeLaneCells.last, seat.laneEnd, reason: seat.id);
        for (var i = 1; i < seat.homeLaneCells.length; i++) {
          final previous = seat.homeLaneCells[i - 1];
          final current = seat.homeLaneCells[i];
          expect(
            (previous.column - current.column).abs() +
                (previous.row - current.row).abs(),
            1,
            reason: '${seat.id} home-lane cells must be consecutive',
          );
        }
        expect(
          seat.homeLaneCells.contains(ClassicLudoBoardDefinition.centerFinishCell),
          isFalse,
        );
      }
      expect(
        ClassicLudoBoardFixture.provisionalEntryCellByPlayer,
        <String, int>{'orange': 0, 'green': 13, 'blue': 39, 'magenta': 26},
      );
      expect(
        LudoRuleProfile().safeCellIndexes,
        <int>{0, 8, 13, 21, 26, 34, 39, 47},
      );
    });

    test('four diagonal corner links remain explicit release blockers', () {
      const track = ClassicLudoBoardCoordinateFactory.sharedTrack;
      const expected = <int, (BoardGridCell, BoardGridCell)>{
        4: (BoardGridCell(column: 5, row: 6), BoardGridCell(column: 6, row: 5)),
        17: (BoardGridCell(column: 8, row: 5), BoardGridCell(column: 9, row: 6)),
        30: (BoardGridCell(column: 9, row: 8), BoardGridCell(column: 8, row: 9)),
        43: (BoardGridCell(column: 6, row: 9), BoardGridCell(column: 5, row: 8)),
      };

      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      for (final entry in expected.entries) {
        expect(track[entry.key], entry.value.$1, reason: 'transition ${entry.key}');
        expect(track[(entry.key + 1) % track.length], entry.value.$2,
            reason: 'transition ${entry.key}');
      }
      expect(
        ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      // Accepted for the provisional trace only. Artwork approval remains a
      // separate release gate; this test must not enable gameplay by itself.
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
