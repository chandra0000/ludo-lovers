import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  group('Classic Ludo route acceptance (provisional fixture)', () {
    final paths = ClassicLudoBoardFixture.create();
    const movement = LudoPathMovement();

    test('each seat turns into its lane after 51 cells without visiting the outer corner', () {
      for (final playerId in paths.pathsByPlayer.keys) {
        final path = paths.forPlayer(playerId);

        final lastTrackMove = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 49,
          ),
          diceValue: 1,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(lastTrackMove.isSuccess, isTrue, reason: playerId);
        expect(lastTrackMove.resolution!.position.progress, 50, reason: playerId);
        expect(lastTrackMove.resolution!.position.section, PawnRouteSection.mainTrack,
            reason: '$playerId should still be on the shared track');
        expect(
          lastTrackMove.resolution!.destinationCell,
          path.cellAtProgress(50),
          reason: '$playerId must land on the final shared cell before the lane branch',
        );

        final laneEntryMove = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 50,
          ),
          diceValue: 1,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(laneEntryMove.isSuccess, isTrue, reason: playerId);
        expect(laneEntryMove.resolution!.position.progress, 51, reason: playerId);
        expect(laneEntryMove.resolution!.position.section, PawnRouteSection.homeLane,
            reason: '$playerId should turn into its private lane at the branch');
        expect(
          laneEntryMove.resolution!.destinationCell,
          path.homeLaneCells.first,
          reason: '$playerId must enter its own first home-lane cell',
        );
      }
    });

    test('each seat requires an exact finish and rejects overshoot', () {
      for (final playerId in paths.pathsByPlayer.keys) {
        final path = paths.forPlayer(playerId);
        final exactFinish = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.homeLane,
            progress: 55,
          ),
          diceValue: 1,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(exactFinish.isSuccess, isTrue, reason: playerId);
        expect(exactFinish.resolution!.finishes, isTrue, reason: playerId);

        final overshoot = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.homeLane,
            progress: 54,
          ),
          diceValue: 3,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(overshoot.failure, PawnMoveFailure.overshoot, reason: playerId);
      }
    });
  });
}
