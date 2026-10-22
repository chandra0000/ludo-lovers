import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';

void main() {
  test('safe-cell profile remains explicitly provisional', () {
    expect(
      ClassicLudoBoardDefinition.provisionalSafeTrackCellIds,
      <int>{0, 8, 13, 21, 26, 34, 39, 47},
    );
    // The supplied artwork is not sufficiently cell-annotated to sign off the
    // star squares. This test locks the provisional profile, not visual approval.
    expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
  });

  test('opponent on a safe cell cannot be captured', () {
    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final orangePath = setup.paths.forPlayer('orange');
    final bluePath = setup.paths.forPlayer('blue');
    final safeCells = setup.engine.safeCellIndexes;
    final orangeProgress = List<int>.generate(orangePath.trackLength - 1, (i) => i)
        .firstWhere((progress) {
          final destination = orangePath.mainTrackCells[progress + 1];
          final blueProgress = bluePath.mainTrackCells.indexOf(destination);
          return safeCells.contains(destination) &&
              blueProgress >= 0 && blueProgress < bluePath.trackLength;
        });
    final destination = orangePath.mainTrackCells[orangeProgress + 1];
    final blueProgress = bluePath.mainTrackCells.indexOf(destination);
    expect(blueProgress, inInclusiveRange(0, bluePath.trackLength - 1));

    final state = setup.initialState.copyWith(
      pendingRoll: 1,
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.id == 'orange_pawn_1') {
          return pawn.copyWith(position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: orangeProgress,
          ));
        }
        if (pawn.id == 'blue_pawn_1') {
          return pawn.copyWith(position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: blueProgress,
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
    final bluePawn = transition.state.pawns.firstWhere(
      (pawn) => pawn.id == 'blue_pawn_1',
    );
    expect(bluePawn.position.section, PawnRouteSection.mainTrack);
    expect(bluePawn.position.progress, blueProgress);
    expect(transition.events.whereType<PawnCaptured>(), isEmpty);
  });

  test('ordinary shared-track cell captures one opponent and returns it to yard', () {
    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final orangePath = setup.paths.forPlayer('orange');
    final bluePath = setup.paths.forPlayer('blue');
    final safeCells = setup.engine.safeCellIndexes;
    final orangeProgress = List<int>.generate(orangePath.trackLength - 1, (i) => i)
        .firstWhere((progress) {
          final destination = orangePath.mainTrackCells[progress + 1];
          final blueProgress = bluePath.mainTrackCells.indexOf(destination);
          return !safeCells.contains(destination) &&
              blueProgress >= 0 && blueProgress < bluePath.trackLength;
        });
    final destination = orangePath.mainTrackCells[orangeProgress + 1];
    final blueProgress = bluePath.mainTrackCells.indexOf(destination);
    expect(blueProgress, inInclusiveRange(0, bluePath.trackLength - 1));

    final state = setup.initialState.copyWith(
      pendingRoll: 1,
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.id == 'orange_pawn_1') {
          return pawn.copyWith(position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: orangeProgress,
          ));
        }
        if (pawn.id == 'blue_pawn_1') {
          return pawn.copyWith(position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: blueProgress,
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
    final bluePawn = transition.state.pawns.firstWhere(
      (pawn) => pawn.id == 'blue_pawn_1',
    );
    expect(bluePawn.position.section, PawnRouteSection.yard);
    expect(bluePawn.position.progress, isNull);
    expect(
      transition.events.whereType<PawnCaptured>().map((event) => event.capturedPawnId),
      contains('blue_pawn_1'),
    );
    // The presentation sequence is independently asserted in
    // ludo_path_movement_test.dart: capture cell -> prior cells in reverse -> yard.
  });

  test('each player has a private home lane that does not overlap another lane', () {
    final paths = ClassicLudoBoardFixture.create();
    for (final playerId in LocalGameFactory.playerIds) {
      final ownLane = paths.forPlayer(playerId).homeLaneCells.toSet();
      expect(ownLane, hasLength(5));
      for (final otherId in LocalGameFactory.playerIds.where((id) => id != playerId)) {
        expect(
          ownLane.intersection(paths.forPlayer(otherId).homeLaneCells.toSet()),
          isEmpty,
          reason: '$playerId must not enter $otherId home lane.',
        );
      }
    }
  });

  test('all four players transition from their final shared cell into their own lane', () {
    final paths = ClassicLudoBoardFixture.create();
    const movement = LudoPathMovement();
    for (final playerId in LocalGameFactory.playerIds) {
      final path = paths.forPlayer(playerId);
      final result = movement.resolve(
        path: path,
        current: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: path.trackLength - 1,
        ),
        diceValue: 1,
        sixRequiredToEnter: true,
        requireExactFinishRoll: true,
      );
      expect(result.isSuccess, isTrue, reason: playerId);
      expect(result.resolution!.position.section, PawnRouteSection.homeLane);
      expect(result.resolution!.destinationCell, path.homeLaneCells.first);
    }
  });

  test('exact finishing is accepted and dice overshoot is rejected', () {
    final path = ClassicLudoBoardFixture.create().forPlayer('orange');
    const movement = LudoPathMovement();
    final exact = movement.resolve(
      path: path,
      current: PawnRoutePosition(
        section: PawnRouteSection.homeLane,
        progress: path.finishProgress - 1,
      ),
      diceValue: 1,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(exact.isSuccess, isTrue);
    expect(exact.resolution!.finishes, isTrue);

    final overshoot = movement.resolve(
      path: path,
      current: PawnRoutePosition(
        section: PawnRouteSection.homeLane,
        progress: path.finishProgress - 2,
      ),
      diceValue: 3,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(overshoot.failure, PawnMoveFailure.overshoot);
  });
}
