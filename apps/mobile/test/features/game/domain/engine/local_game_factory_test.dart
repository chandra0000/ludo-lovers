import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  group('LocalGameFactory', () {
    test('requires explicit opt-in while board route is provisional', () {
      expect(() => LocalGameFactory.create(), throwsA(isA<StateError>()));
    });

    test('creates four players and sixteen unique pawns for development', () {
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final state = setup.initialState;

      expect(state.players, LocalGameFactory.playerIds);
      expect(state.pawns, hasLength(16));
      expect(state.pawns.map((pawn) => pawn.id).toSet(), hasLength(16));
      for (final playerId in state.players) {
        expect(state.pawns.where((pawn) => pawn.playerId == playerId), hasLength(4));
        expect(
          state.pawns
              .where((pawn) => pawn.playerId == playerId)
              .every((pawn) => pawn.position.section == PawnRouteSection.yard),
          isTrue,
        );
      }
      expect(state.currentPlayerId, 'orange');
      expect(state.pendingRoll, isNull);
      expect(state.version, 0);
    });

    test('can execute a deterministic first turn using a fixed dice value', () {
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final rolled = setup.engine.roll(
        setup.initialState,
        playerId: 'orange',
        expectedVersion: setup.initialState.version,
        value: 6,
      );

      expect(rolled.state.pendingRoll, 6);
      expect(setup.engine.legalPawnIds(rolled.state), hasLength(4));

      final moved = setup.engine.move(
        rolled.state,
        playerId: 'orange',
        expectedVersion: rolled.state.version,
        pawnId: 'orange_pawn_1',
      );

      final pawn = moved.state.pawns.firstWhere((item) => item.id == 'orange_pawn_1');
      expect(pawn.position.section, PawnRouteSection.mainTrack);
      expect(pawn.position.progress, 0);
      expect(moved.state.currentPlayerId, 'orange');
      expect(moved.state.pendingRoll, isNull);
    });
  });
}
