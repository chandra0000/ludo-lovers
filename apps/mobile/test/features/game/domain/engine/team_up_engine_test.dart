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
      expect(setup.engine.profile.id, 'team-up-v1-provisional');
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
          if (pawn.id == 'magenta_pawn_1') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: magentaProgress,
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
      final magentaProgress =
          setup.paths.forPlayer('magenta').mainTrackCells.indexOf(targetCell);
      final blueProgress =
          setup.paths.forPlayer('blue').mainTrackCells.indexOf(targetCell);
      expect(greenProgress, greaterThanOrEqualTo(0));
      expect(magentaProgress, greaterThanOrEqualTo(0));
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
          if (pawn.id == 'magenta_pawn_1') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: magentaProgress,
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
      final magenta = transition.state.pawns.firstWhere(
        (pawn) => pawn.id == 'magenta_pawn_1',
      );

      expect(green.position.section, PawnRouteSection.mainTrack);
      expect(blue.position.section, PawnRouteSection.yard);
      expect(magenta.position.section, PawnRouteSection.mainTrack);
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

    test('bonus six remains with the teammate receiving a transferred turn', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 2,
        scheduledPlayerIndex: 0,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.playerId == 'orange') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer('orange').finishProgress,
            ));
          }
          if (pawn.id == 'magenta_pawn_1') {
            return pawn.copyWith(position: const PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: 0,
            ));
          }
          return pawn;
        }).toList(growable: false),
      );

      final six = setup.engine.roll(
        state,
        playerId: 'magenta',
        expectedVersion: state.version,
        value: 6,
      );
      expect(six.state.currentPlayerId, 'magenta');
      expect(six.state.scheduledPlayerIndex, 0);
      expect(six.state.pendingRoll, 6);

      final moved = setup.engine.move(
        six.state,
        playerId: 'magenta',
        expectedVersion: six.state.version,
        pawnId: 'magenta_pawn_1',
      );
      expect(moved.state.currentPlayerId, 'magenta');
      expect(moved.state.scheduledPlayerIndex, 0);
      expect(moved.events.map((event) => event.type), contains('ExtraRollGranted'));

      final nextRoll = setup.engine.roll(
        moved.state,
        playerId: 'magenta',
        expectedVersion: moved.state.version,
        value: 2,
      );
      final nextMove = setup.engine.move(
        nextRoll.state,
        playerId: 'magenta',
        expectedVersion: nextRoll.state.version,
        pawnId: 'magenta_pawn_1',
      );
      expect(nextMove.state.currentPlayerId, 'green');
      expect(nextMove.state.scheduledPlayerIndex, 1);
    });

    test('one unfinished teammate prevents premature team victory', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 2,
        scheduledPlayerIndex: 2,
        pendingRoll: 1,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.playerId == 'orange' && pawn.id != 'orange_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer('orange').finishProgress,
            ));
          }
          if (pawn.id == 'orange_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: setup.paths.forPlayer('orange').finishProgress - 1,
            ));
          }
          if (pawn.playerId == 'magenta' && pawn.id != 'magenta_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer('magenta').finishProgress,
            ));
          }
          if (pawn.id == 'magenta_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: setup.paths.forPlayer('magenta').finishProgress - 1,
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

      expect(transition.state.completed, isFalse);
      expect(transition.state.winnerTeamId, isNull);
      expect(transition.state.currentPlayerId, 'orange');
      expect(transition.state.scheduledPlayerIndex, 2);
      expect(transition.events.map((event) => event.type), contains('ExtraRollGranted'));
    });

    test('Team B wins only after Green and Blue finish all eight pawns', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      final state = setup.initialState.copyWith(
        currentPlayerIndex: 3,
        scheduledPlayerIndex: 3,
        pendingRoll: 1,
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.playerId == 'green' ||
              (pawn.playerId == 'blue' && pawn.id != 'blue_pawn_4')) {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.finished,
              progress: setup.paths.forPlayer(pawn.playerId).finishProgress,
            ));
          }
          if (pawn.id == 'blue_pawn_4') {
            return pawn.copyWith(position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: setup.paths.forPlayer('blue').finishProgress - 1,
            ));
          }
          return pawn;
        }).toList(growable: false),
      );

      final transition = setup.engine.move(
        state,
        playerId: 'blue',
        expectedVersion: state.version,
        pawnId: 'blue_pawn_4',
      );

      expect(transition.state.completed, isTrue);
      expect(transition.state.winnerTeamId, 'b');
      expect(transition.state.winnerPlayerId, 'blue');
    });

    test('keeps the fixed alternating Orange, Green, Magenta, Blue schedule', () {
      final setup = LocalGameFactory.create(
        allowProvisionalRoutes: true,
        mode: LocalGameMode.teamUp,
      );
      var state = setup.initialState;
      for (final expectedNext in <String>['green', 'magenta', 'blue', 'orange']) {
        final actor = state.currentPlayerId;
        final transition = setup.engine.roll(
          state,
          playerId: actor,
          expectedVersion: state.version,
          value: 2,
        );
        expect(transition.state.currentPlayerId, expectedNext);
        expect(transition.state.scheduledPlayerId, expectedNext);
        state = transition.state;
      }
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
      expect(setup.engine.profile.id, 'classic-v1-provisional');
      expect(setup.initialState.players, LocalGameFactory.playerIds);
      expect(setup.initialState.pawns, hasLength(16));
    });
  });
}
