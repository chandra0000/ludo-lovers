import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
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
      final sharedCell = orangePath.cellAtProgress(2)!;
      final magentaProgress = magentaPath.mainTrackCells.indexOf(sharedCell);
      expect(magentaProgress, greaterThanOrEqualTo(0));

      final state = setup.initialState.copyWith(
        currentPlayerIndex: 0,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(
              position: const PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: 1,
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
    test('safe cells protect opposing Team Up pawns from capture', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final orangePath = setup.paths.forPlayer('orange');
      final greenPath = setup.paths.forPlayer('green');
      final safeCell = setup.engine.safeCellIndexes.firstWhere(
        (cell) =>
            orangePath.mainTrackCells.indexOf(cell) > 0 &&
            greenPath.mainTrackCells.contains(cell),
      );
      final orangeTargetProgress = orangePath.mainTrackCells.indexOf(safeCell);
      final greenTargetProgress = greenPath.mainTrackCells.indexOf(safeCell);
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 0,
        scheduledPlayerIndex: 0,
        pendingRoll: 1,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: orangeTargetProgress - 1,
            ));
          }
          if (pawn.id == 'green_pawn_1') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: greenTargetProgress,
            ));
          }
          return pawn;
        }).toList(growable: false),
      );

      final transition = setup.engine.move(
        state,
        playerId: 'orange',
        expectedVersion: state.version,
        pawnId: 'orange_pawn_1',
      );

      expect(
        transition.state.pawns
            .firstWhere((pawn) => pawn.id == 'green_pawn_1')
            .position
            .section,
        PawnRouteSection.mainTrack,
      );
      expect(
        transition.events.where((event) => event.type == 'PawnCaptured'),
        isEmpty,
      );
    });

    test('captures only the last-arrived pawn from an opposing stack', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final orangePath = setup.paths.forPlayer('orange');
      final targetCell = orangePath.cellAtProgress(2)!;
      final greenProgress =
          setup.paths.forPlayer('green').mainTrackCells.indexOf(targetCell);
      final blueProgress =
          setup.paths.forPlayer('blue').mainTrackCells.indexOf(targetCell);
      expect(greenProgress, greaterThanOrEqualTo(0));
      expect(blueProgress, greaterThanOrEqualTo(0));

      final state = setup.initialState.copyWith(
        currentPlayerIndex: 0,
        scheduledPlayerIndex: 0,
        pendingRoll: 1,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(position: const PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: 1,
            ));
          }
          if (pawn.id == 'green_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: greenProgress,
              ),
              lastMovedAtVersion: 4,
            );
          }
          if (pawn.id == 'blue_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: blueProgress,
              ),
              lastMovedAtVersion: 9,
            );
          }
          return pawn;
        }).toList(growable: false),
      );

      final transition = setup.engine.move(
        state,
        playerId: 'orange',
        expectedVersion: state.version,
        pawnId: 'orange_pawn_1',
      );
      final green = transition.state.pawns.firstWhere(
        (pawn) => pawn.id == 'green_pawn_1',
      );
      final blue = transition.state.pawns.firstWhere(
        (pawn) => pawn.id == 'blue_pawn_1',
      );

      expect(green.position.section, PawnRouteSection.mainTrack);
      expect(blue.position.section, PawnRouteSection.yard);
      expect(
        transition.events.where((event) => event.type == 'PawnCaptured')
            .map((event) => event.pawnId),
        <String?>['blue_pawn_1'],
      );
    });

    test('Team A wins only after Orange and Magenta finish all eight pawns', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final finishProgress = setup.paths.forPlayer('magenta').finishProgress;
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 2,
        scheduledPlayerIndex: 2,
        pendingRoll: 1,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.playerId == 'orange' ||
              (pawn.playerId == 'magenta' && pawn.id != 'magenta_pawn_4')) {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer(pawn.playerId).finishProgress,
            ));
          }
          if (pawn.id == 'magenta_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: finishProgress - 1,
            ));
          }
          return pawn;
        }).toList(growable: false),
      );

      final transition = setup.engine.move(
        state,
        playerId: 'magenta',
        expectedVersion: state.version,
        pawnId: 'magenta_pawn_4',
      );

      expect(transition.state.completed, isTrue);
      expect(transition.state.winnerTeamId, 'a');
      expect(transition.state.winnerPlayerId, 'magenta');
      expect(transition.events.map((event) => event.type), contains('GameCompleted'));
    });

    test('Classic turn advancement follows current player, not Team Up schedule', () {
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 1,
        scheduledPlayerIndex: 0,
      );

      final transition = setup.engine.roll(
        state,
        playerId: 'green',
        expectedVersion: state.version,
        value: 2,
      );

      expect(transition.state.currentPlayerId, 'magenta');
      expect(transition.state.scheduledPlayerIndex, 2);
    });

    test('Classic factory remains in Classic mode with its original rules flag', () {
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      expect(setup.mode, LocalGameMode.classic);
      expect(setup.engine.isTeamUp, isFalse);
      expect(setup.initialState.players, LocalGameFactory.playerIds);
      expect(setup.initialState.pawns, hasLength(16));
    });
  });
}
