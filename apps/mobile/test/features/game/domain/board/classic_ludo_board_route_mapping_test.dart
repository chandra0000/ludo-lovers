import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';

void main() {
  group('Classic Ludo route mapping', () {
    test('logical route entry offsets derive from the shared seat definition', () {
      final entries = ClassicLudoBoardFixture.provisionalEntryCellByPlayer;

      expect(entries, {
        for (final seat in ClassicLudoBoardDefinition.seats)
          seat.id: seat.provisionalTrackEntryIndex,
      });
      expect(entries, {'orange': 0, 'green': 13, 'blue': 39, 'magenta': 26});
    });

    test('each seat route has 52 unique cells and a six-cell home lane', () {
      final paths = ClassicLudoBoardFixture.create();

      expect(paths.pathsByPlayer, hasLength(4));
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.mainTrackCells, hasLength(52), reason: seat.id);
        expect(path.mainTrackCells.toSet(), hasLength(52), reason: seat.id);
        expect(path.homeLaneCells, hasLength(6), reason: seat.id);
        expect(path.entryCell, seat.provisionalTrackEntryIndex, reason: seat.id);
        expect(path.cellAtProgress(0), seat.provisionalTrackEntryIndex);
        expect(path.cellAtProgress(51), (seat.provisionalTrackEntryIndex + 51) % 52);
        expect(path.cellAtProgress(52), seat.homeLaneStartCellId);
        expect(path.cellAtProgress(57), seat.homeLaneStartCellId + 5);
        expect(path.cellAtProgress(58), isNull);
      }
    });

    test('coordinate route remains gated until non-orthogonal transitions are fixed', () {
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack, hasLength(52));
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        isNotEmpty,
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
