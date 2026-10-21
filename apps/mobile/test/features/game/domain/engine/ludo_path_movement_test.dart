import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  late LudoPlayerPath path;
  const movement = LudoPathMovement();

  setUp(() {
    path = LudoPlayerPath(
      playerId: 'orange',
      mainTrackCells: List<int>.generate(8, (i) => (i + 5) % 8),
      homeLaneCells: <int>[100, 101, 102],
      trackLength: 8,
    );
  });

  test('yard pawn enters at its entry cell only when allowed', () {
    final denied = movement.resolve(
      path: path,
      current: const PawnRoutePosition(section: PawnRouteSection.yard),
      diceValue: 4,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(denied.failure, PawnMoveFailure.pawnInYardNeedsSix);

    final entered = movement.resolve(
      path: path,
      current: const PawnRoutePosition(section: PawnRouteSection.yard),
      diceValue: 6,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(entered.isSuccess, isTrue);
    expect(entered.resolution!.destinationCell, path.entryCell);
    expect(entered.resolution!.position.progress, 0);
  });

  test('movement advances by logical progress and wraps by player route', () {
    final result = movement.resolve(
      path: path,
      current: const PawnRoutePosition(
        section: PawnRouteSection.mainTrack,
        progress: 6,
      ),
      diceValue: 1,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(result.isSuccess, isTrue);
    expect(result.resolution!.position.progress, 7);
    expect(result.resolution!.destinationCell, path.cellAtProgress(7));
  });

  test('movement transitions from main track into private home lane', () {
    final result = movement.resolve(
      path: path,
      current: const PawnRoutePosition(
        section: PawnRouteSection.mainTrack,
        progress: 7,
      ),
      diceValue: 1,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(result.isSuccess, isTrue);
    expect(result.resolution!.position.section, PawnRouteSection.homeLane);
    expect(result.resolution!.destinationCell, 100);
  });

  test('animation positions visit the track and every home-lane cell in order', () {
    final positions = movement.positionsBetween(
      path: path,
      fromProgress: 6,
      toProgress: 10,
    );

    expect(
      positions.map((position) => (position.section, position.progress)),
      <(PawnRouteSection, int?)>[
        (PawnRouteSection.mainTrack, 7),
        (PawnRouteSection.homeLane, 8),
        (PawnRouteSection.homeLane, 9),
        (PawnRouteSection.homeLane, 10),
      ],
      reason: 'A pawn must not skip the branch cell or jump to a later lane cell.',
    );
    expect(
      positions.map((position) => path.cellAtProgress(position.progress!)),
      <int?>[path.mainTrackCells[7], 100, 101, 102],
    );
  });

  test('route animation marks the center only after the final lane cell', () {
    final positions = movement.positionsBetween(
      path: path,
      fromProgress: 10,
      toProgress: path.finishProgress,
    );

    expect(positions, hasLength(1));
    expect(positions.single.section, PawnRouteSection.finished);
    expect(positions.single.progress, path.finishProgress);
  });

  test('exact finish reaches center and marks pawn finished', () {
    final result = movement.resolve(
      path: path,
      current: const PawnRoutePosition(
        section: PawnRouteSection.homeLane,
        progress: 10,
      ),
      diceValue: 1,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(result.isSuccess, isTrue);
    expect(result.resolution!.finishes, isTrue);
    expect(result.resolution!.destinationCell, isNull);
    expect(result.resolution!.position.section, PawnRouteSection.finished);
  });

  test('exact-finish mode rejects an overshoot', () {
    final result = movement.resolve(
      path: path,
      current: const PawnRoutePosition(
        section: PawnRouteSection.homeLane,
        progress: 9,
      ),
      diceValue: 3,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(result.failure, PawnMoveFailure.overshoot);
  });

  test('rejects invalid dice and already-finished pawn', () {
    final invalidDice = movement.resolve(
      path: path,
      current: const PawnRoutePosition(
        section: PawnRouteSection.mainTrack,
        progress: 1,
      ),
      diceValue: 0,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(invalidDice.failure, PawnMoveFailure.invalidDice);

    final finished = movement.resolve(
      path: path,
      current: const PawnRoutePosition(section: PawnRouteSection.finished, progress: 11),
      diceValue: 2,
      sixRequiredToEnter: true,
      requireExactFinishRoll: true,
    );
    expect(finished.failure, PawnMoveFailure.alreadyFinished);
  });
}
