import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  group('Classic Ludo route acceptance (provisional fixture)', () {
    final paths = ClassicLudoBoardFixture.create();
    const movement = LudoPathMovement();

    test('each seat advances and wraps on its own 52-cell route', () {
      for (final playerId in paths.pathsByPlayer.keys) {
        final path = paths.forPlayer(playerId);

        final normalMove = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 50,
          ),
          diceValue: 1,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(normalMove.isSuccess, isTrue, reason: playerId);
        expect(normalMove.resolution!.position.progress, 51, reason: playerId);
        expect(
          normalMove.resolution!.destinationCell,
          path.cellAtProgress(51),
          reason: '$playerId must resolve progress through its own route',
        );

        final wrapMove = movement.resolve(
          path: path,
          current: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 51,
          ),
          diceValue: 1,
          sixRequiredToEnter: true,
          requireExactFinishRoll: true,
        );
        expect(wrapMove.isSuccess, isTrue, reason: playerId);
        expect(wrapMove.resolution!.position.progress, 52, reason: playerId);
        expect(wrapMove.resolution!.position.section, PawnRouteSection.homeLane,
            reason: '$playerId should leave the shared track for its private lane');
        expect(
          wrapMove.resolution!.destinationCell,
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
            progress: 56,
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
            progress: 56,
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
