import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';

void main() {
  test('deterministic local match starts from yards and completes through legal moves', () {
    final setup = LocalGameFactory.create(
      allowProvisionalRoutes: true,
      selectedPlayerIds: const <String>['orange', 'green'],
    );
    var state = setup.initialState;
    expect(
      state.pawns.every((pawn) => pawn.position.section == PawnRouteSection.yard),
      isTrue,
      reason: 'The match must start from the real initial yard state.',
    );

    var acceptedMoves = 0;
    var diceRolls = 0;
    const maxActions = 20000;

    while (!state.completed && diceRolls < maxActions) {
      final playerId = state.currentPlayerId;
      var chosenRoll = 1;
      String? chosenPawnId;

      if (playerId == 'orange') {
        var bestScore = -1;
        // Deterministic policy: examine each possible die result against the
        // current immutable state, then commit exactly one real roll and move.
        for (var die = 1; die <= 6; die++) {
          if (die == 6 && state.consecutiveSixes >= 2) continue;
          final preview = state.copyWith(pendingRoll: die);
          final legalIds = setup.engine.legalPawnIds(preview);
          for (final pawnId in legalIds) {
            final pawn = state.pawns.firstWhere((item) => item.id == pawnId);
            final resolution = const LudoPathMovement().resolve(
              path: setup.paths.forPlayer(playerId),
              current: pawn.position,
              diceValue: die,
              sixRequiredToEnter: setup.engine.sixRequiredToEnter,
              requireExactFinishRoll: setup.engine.requireExactFinishRoll,
            );
            if (!resolution.isSuccess) continue;
            final destination = resolution.resolution!;
            final score = destination.finishes
                ? 100000
                : switch (destination.position.section) {
                    PawnRouteSection.homeLane => 1000 + (destination.position.progress ?? 0),
                    PawnRouteSection.mainTrack => 100 + (destination.position.progress ?? 0),
                    PawnRouteSection.finished => 100000,
                    PawnRouteSection.yard => 0,
                  };
            if (score > bestScore) {
              bestScore = score;
              chosenRoll = die;
              chosenPawnId = pawnId;
            }
          }
        }
      }

      final rolled = setup.engine.roll(
        state,
        playerId: playerId,
        expectedVersion: state.version,
        value: chosenRoll,
      );
      state = rolled.state;
      diceRolls++;

      if (chosenPawnId != null && state.pendingRoll != null) {
        // The selected pawn must remain legal after the real roll transition.
        expect(setup.engine.legalPawnIds(state), contains(chosenPawnId));
        final moved = setup.engine.move(
          state,
          playerId: playerId,
          expectedVersion: state.version,
          pawnId: chosenPawnId,
        );
        expect(moved.events.whereType<PawnMoved>(), isNotEmpty);
        state = moved.state;
        acceptedMoves++;
      }
    }

    expect(diceRolls, lessThan(maxActions), reason: 'The deterministic match must terminate.');
    expect(state.completed, isTrue);
    expect(state.winnerPlayerId, 'orange');
    expect(acceptedMoves, greaterThan(0));
    expect(
      state.pawns
          .where((pawn) => pawn.playerId == 'orange')
          .every((pawn) => pawn.position.section == PawnRouteSection.finished),
      isTrue,
      reason: 'All winning-seat pawns must finish through legal transitions.',
    );
    expect(state.pawns.where((pawn) => pawn.playerId == 'orange'), hasLength(4));
  });
}
