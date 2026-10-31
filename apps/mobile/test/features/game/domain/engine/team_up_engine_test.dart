import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';
import 'package:ludo_lovers/features/game/domain/engine/team_up_rules.dart';

void main() {
  group('Team Up local engine', () {
    test('creates the four scheduled seats and eight pawns per team', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );

      expect(setup.mode, LocalGameMode.teamUp);
      expect(setup.initialState.players, TeamUpRules.turnOrder);
      expect(setup.initialState.pawns, hasLength(16));
      expect(setup.initialState.scheduledPlayerIndex, 0);
      expect(setup.engine.isTeamUp, isTrue);
    });

    test('rejects Team Up when seats are missing or out of scheduled order', () {
      expect(
        () => LocalGameFactory.create(
          allowProvisionalRoutes: true,
          mode: LocalGameMode.teamUp,
          selectedPlayerIds: const <String>['orange', 'green'],
        ),
        throwsArgumentError,
      );
      expect(
        () => LocalGameFactory.create(
          allowProvisionalRoutes: true,
          mode: LocalGameMode.teamUp,
          selectedPlayerIds: const <String>['green', 'orange', 'magenta', 'blue'],
        ),
        throwsArgumentError,
      );
    });

    test('transfers a finished Orange scheduled turn to Magenta', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 3,
        scheduledPlayerIndex: 3,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.playerId != 'orange') return pawn;
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer('orange').finishProgress,
            ),
          );
        }).toList(growable: false),
      );

      final transition = setup.engine.roll(
        state,
        playerId: 'blue',
        expectedVersion: state.version,
        value: 2,
      );

      expect(transition.state.scheduledPlayerIndex, 0);
      expect(transition.state.currentPlayerId, 'magenta');
      expect(transition.state.pendingRoll, isNull);
      expect(transition.events.map((event) => event.type), contains('NoLegalMove'));
    });

    test('keeps teammate pawns on the board when a pawn lands on their cell', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final orangePath = setup.paths.forPlayer('orange');
      final magentaPath = setup.paths.forPlayer('magenta');
      final sharedCell = orangePath.cellAtProgress(1)!;
      final magentaProgress = magentaPath.mainTrackCells.indexOf(sharedCell);
      expect(magentaProgress, greaterThanOrEqualTo(0));

      final state = setup.initialState.copyWith(
        currentPlayerIndex: 0,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(
              position: const PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: 0,
              ),
            );
          }
          if (pawn.id == 'magenta_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: magentaProgress,
              ),
            );
          }
          return pawn;
        }).toList(growable: false),
        pendingRoll: 1,
      );

      // Move Orange onto the same physical cell as its teammate. The friendly
      // pawn must remain in place; the move itself follows the canonical path.
      final transition = setup.engine.move(
        state,
        playerId: 'orange',
        expectedVersion: state.version,
        pawnId: 'orange_pawn_1',
      );

      expect(
        transition.state.pawns
            .firstWhere((pawn) => pawn.id == 'magenta_pawn_1')
            .position
            .section,
        PawnRouteSection.mainTrack,
      );
      expect(
        transition.events.where((event) => event.type == 'PawnCaptured'),
        isEmpty,
      );
    });
  });
}
