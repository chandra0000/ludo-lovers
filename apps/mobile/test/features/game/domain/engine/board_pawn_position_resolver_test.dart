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
      homeLaneCells: const <int>[200, 201, 202, 203, 204],
      trackLength: 51,
    );
    final greenPath = LudoPlayerPath(
      playerId: 'green',
      mainTrackCells: List<int>.generate(52, (index) => (index + 13) % 52),
      homeLaneCells: const <int>[220, 221, 222, 223, 224],
      trackLength: 51,
    );
    final bluePath = LudoPlayerPath(
      playerId: 'blue',
      mainTrackCells: List<int>.generate(52, (index) => (index + 39) % 52),
      homeLaneCells: const <int>[210, 211, 212, 213, 214],
      trackLength: 51,
    );
    final magentaPath = LudoPlayerPath(
      playerId: 'magenta',
      mainTrackCells: List<int>.generate(52, (index) => (index + 26) % 52),
      homeLaneCells: const <int>[230, 231, 232, 233, 234],
      trackLength: 51,
    );
    resolver = BoardPawnPositionResolver(
      paths: LudoBoardPaths(<LudoPlayerPath>[
        orangePath,
        greenPath,
        bluePath,
        magentaPath,
      ]),
      layout: ClassicLudoBoardCoordinateFactory.create(),
    );
  });

  test('uses five physical lane cells and a separate finish state', () {
    for (final playerId in <String>['orange', 'green', 'blue', 'magenta']) {
      final path = resolver.paths.forPlayer(playerId);
      expect(path.homeLaneLength, 5, reason: playerId);
      expect(path.finishProgress, 56, reason: playerId);
      expect(path.cellAtProgress(55), path.homeLaneCells.last, reason: playerId);
      expect(path.cellAtProgress(56), isNull, reason: playerId);
    }
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

  test('maps entry progress for all four player routes', () {
    const entryPosition = PawnRoutePosition(
      section: PawnRouteSection.mainTrack,
      progress: 0,
    );

    expect(
      resolver.cellIdFor(playerId: 'orange', position: entryPosition),
      0,
    );
    expect(
      resolver.cellIdFor(playerId: 'green', position: entryPosition),
      13,
    );
    expect(
      resolver.cellIdFor(playerId: 'blue', position: entryPosition),
      39,
    );
    expect(
      resolver.cellIdFor(playerId: 'magenta', position: entryPosition),
      26,
    );
  });

  test('projects home-lane progress through the player-specific route', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 51,
        ),
      ),
      200,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'green',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 52,
        ),
      ),
      221,
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
          progress: 56,
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
          progress: 51,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('maps the last traversed shared-track step before turning into the home lane', () {
    expect(
      resolver.cellIdFor(
        playerId: 'orange',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 50,
        ),
      ),
      50,
    );
    expect(
      resolver.cellIdFor(
        playerId: 'green',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 50,
        ),
      ),
      11,
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
