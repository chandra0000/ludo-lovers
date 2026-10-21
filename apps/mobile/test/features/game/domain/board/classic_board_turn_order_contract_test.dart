import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';

void main() {
  group('classic board turn order and route contract', () {
    test('dice turns rotate Orange, Green, Magenta, Blue', () {
      expect(
        LocalGameFactory.playerIds,
        <String>['orange', 'green', 'magenta', 'blue'],
      );
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      expect(setup.initialState.currentPlayerId, 'orange');

      var state = setup.initialState;
      for (final expectedPlayer in <String>['green', 'magenta', 'blue', 'orange']) {
        // A roll of one with all pawns in the yard creates no legal move and
        // advances the turn without introducing randomness into this contract.
        final roll = setup.engine.roll(
          state,
          playerId: state.currentPlayerId,
          expectedVersion: state.version,
          value: 1,
        );
        final afterRoll = roll.state;
        final transition = setup.engine.move(
          afterRoll,
          playerId: afterRoll.currentPlayerId,
          expectedVersion: afterRoll.version,
          pawnId: setup.engine.legalPawnIds(afterRoll).isEmpty
              ? afterRoll.pawns.firstWhere((p) => p.playerId == afterRoll.currentPlayerId).id
              : setup.engine.legalPawnIds(afterRoll).first,
        );
        state = transition.state;
        expect(state.currentPlayerId, expectedPlayer);
      }
    });

    test('all four player routes start at their canonical entry markers', () {
      final paths = ClassicLudoBoardFixture.create();
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final path = paths.forPlayer(seat.id);
        expect(path.mainTrackCells, hasLength(52), reason: seat.id);
        expect(
          path.mainTrackCells.first,
          seat.provisionalTrackEntryIndex,
          reason: '${seat.id} must enter at its own marker',
        );
        expect(path.mainTrackCells.toSet(), hasLength(52), reason: seat.id);
        expect(path.homeLaneCells, hasLength(5), reason: seat.id);
      }
    });

    test('canonical visual entries and turn order stay independent but aligned', () {
      expect(
        ClassicLudoBoardDefinition.seats.map((seat) => seat.id).toSet(),
        <String>{'orange', 'green', 'magenta', 'blue'},
      );
      expect(
        ClassicLudoBoardFixture.provisionalEntryCellByPlayer,
        <String, int>{
          'orange': 0,
          'green': 13,
          'magenta': 26,
          'blue': 39,
        },
      );
    });
  });
}
