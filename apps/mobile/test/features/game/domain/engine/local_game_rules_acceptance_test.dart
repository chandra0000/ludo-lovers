import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_rule_profile.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';

void main() {
  late LudoBoardPaths paths;
  late PathBasedLocalGameEngine engine;

  setUp(() {
    paths = LudoBoardPaths(<LudoPlayerPath>[
      LudoPlayerPath(
        playerId: 'orange',
        mainTrackCells: List<int>.generate(8, (index) => index),
        homeLaneCells: <int>[100, 101, 102],
        trackLength: 8,
      ),
      LudoPlayerPath(
        playerId: 'blue',
        mainTrackCells: List<int>.generate(8, (index) => (index + 4) % 8),
        homeLaneCells: <int>[110, 111, 112],
        trackLength: 8,
      ),
    ]);
    engine = PathBasedLocalGameEngine(
      paths: paths,
      profile: LudoRuleProfile(
        safeCellIndexes: const <int>{0, 4},
        maxConsecutiveSixes: 3,
      ),
    );
  });

  LocalGameState stateWith(List<LocalPawn> pawns) => LocalGameState(
        players: const <String>['orange', 'blue'],
        pawns: pawns,
        currentPlayerIndex: 0,
      );

  test('legal movement captures on an unsafe cell and grants a bonus turn', () {
    final state = stateWith(<LocalPawn>[
      const LocalPawn(
        id: 'o1',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 1,
        ),
      ),
      const LocalPawn(
        id: 'o2',
        playerId: 'orange',
        position: PawnRoutePosition(section: PawnRouteSection.yard),
      ),
      const LocalPawn(
        id: 'b1',
        playerId: 'blue',
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 6,
        ),
      ),
    ]);

    final rolled = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 1,
    );
    expect(engine.legalPawnIds(rolled.state), contains('o1'));

    final moved = engine.move(
      rolled.state,
      playerId: 'orange',
      expectedVersion: rolled.state.version,
      pawnId: 'o1',
    );

    expect(moved.state.pawns.first.position.progress, 2,
        reason: 'A legal one-step move must land on the resolved route cell.');
    expect(moved.state.pawns[2].position.section, PawnRouteSection.yard,
        reason: 'The opponent on the unsafe destination must be captured.');
    expect(moved.state.currentPlayerId, 'orange',
        reason: 'A capture grants the configured bonus roll.');
    expect(
      moved.events.map((event) => event.type),
      containsAll(<String>['PawnMoved', 'PawnCaptured', 'ExtraRollGranted']),
    );
  });

  test('a safe destination protects the opponent and ends the normal turn', () {
    final state = stateWith(<LocalPawn>[
      const LocalPawn(
        id: 'o1',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 3,
        ),
      ),
      const LocalPawn(
        id: 'b1',
        playerId: 'blue',
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      ),
    ]);

    final rolled = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 1,
    );
    final moved = engine.move(
      rolled.state,
      playerId: 'orange',
      expectedVersion: rolled.state.version,
      pawnId: 'o1',
    );

    expect(moved.state.pawns.first.position.progress, 4);
    expect(moved.state.pawns[1].position.section, PawnRouteSection.mainTrack);
    expect(moved.events.map((event) => event.type),
        isNot(contains('PawnCaptured')));
    expect(moved.state.currentPlayerId, 'blue');
  });

  test('exact-finish overshoot is rejected without consuming the roll', () {
    final state = stateWith(<LocalPawn>[
      const LocalPawn(
        id: 'o1',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 10,
        ),
      ),
      const LocalPawn(
        id: 'o2',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 1,
        ),
      ),
      const LocalPawn(
        id: 'b1',
        playerId: 'blue',
        position: PawnRoutePosition(section: PawnRouteSection.yard),
      ),
    ]);

    final rolled = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 2,
    );
    expect(engine.legalPawnIds(rolled.state), contains('o2'));
    expect(
      () => engine.move(
        rolled.state,
        playerId: 'orange',
        expectedVersion: rolled.state.version,
        pawnId: 'o1',
      ),
      throwsA(isA<LocalGameException>()),
    );

    expect(rolled.state.pendingRoll, 2);
    expect(rolled.state.pawns.first.position.progress, 10);
    expect(rolled.state.version, state.version + 1,
        reason: 'Rejecting the move must not mutate the rolled snapshot.');
  });

  test('an exact finishing roll emits finish and match-completed events', () {
    final state = stateWith(<LocalPawn>[
      const LocalPawn(
        id: 'o1',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 10,
        ),
      ),
      const LocalPawn(
        id: 'o2',
        playerId: 'orange',
        position: PawnRoutePosition(
          section: PawnRouteSection.finished,
          progress: 11,
        ),
      ),
      const LocalPawn(
        id: 'b1',
        playerId: 'blue',
        position: PawnRoutePosition(section: PawnRouteSection.yard),
      ),
    ]);

    final rolled = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 1,
    );
    final moved = engine.move(
      rolled.state,
      playerId: 'orange',
      expectedVersion: rolled.state.version,
      pawnId: 'o1',
    );

    expect(moved.state.completed, isTrue);
    expect(moved.state.winnerPlayerId, 'orange');
    expect(moved.state.pawns.first.position.section, PawnRouteSection.finished);
    expect(moved.state.pendingRoll, isNull);
    expect(moved.events.map((event) => event.type),
        containsAll(<String>['PawnFinished', 'GameCompleted']));
  });
}
