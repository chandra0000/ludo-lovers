import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';
import 'package:ludo_lovers/features/game/domain/engine/board_pawn_position_resolver.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  late BoardPawnPositionResolver resolver;

  setUp(() {
    final orangePath = LudoPlayerPath(
      playerId: 'orange',
      mainTrackCells: List<int>.generate(52, (index) => index),
      homeLaneCells: const <int>[200, 201, 202, 203, 204, 205],
      trackLength: 52,
    );
    final greenPath = LudoPlayerPath(
      playerId: 'green',
      mainTrackCells: List<int>.generate(52, (index) => (index + 13) % 52),
      homeLaneCells: const <int>[220, 221, 222, 223, 224, 225],
      trackLength: 52,
    );
    resolver = BoardPawnPositionResolver(
      paths: LudoBoardPaths(<LudoPlayerPath>[orangePath, greenPath]),
      layout: ClassicLudoBoardCoordinateFactory.create(),
    );
  });

  test('projects player-relative track progress to physical logical cell', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      ),
      0,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'green',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      ),
      13,
    );
  });

  test('projects home-lane progress through the player-specific route', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 52,
        ),
      ),
      200,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'green',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 54,
        ),
      ),
      222,
    );
  });

  test('yard and finished pawns do not resolve to numbered cells', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(section: PawnRouteSection.yard),
      ),
      isNull,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.finished,
          progress: 58,
        ),
      ),
      isNull,
    );
  });

  test('rejects progress inconsistent with the declared route section', () {
    expect(
      () => resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 4,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 52,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('maps the final shared-track step before entering the home lane', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 51,
        ),
      ),
      51,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'green',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 51,
        ),
      ),
      12,
    );
  });

  test('rejects missing and negative progress for numbered route positions', () {
    expect(
      () => resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: -1,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects player IDs without a configured route', () {
    expect(
      () => resolver.cellIdFor(
        playerId: 'purple',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      ),
      throwsArgumentError,
    );
  });

}
