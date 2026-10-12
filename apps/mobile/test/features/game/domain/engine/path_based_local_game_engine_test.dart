import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';

void main() {
  late LudoBoardPaths paths;
  late PathBasedLocalGameEngine engine;
  late LocalGameState initial;

  setUp(() {
    paths = LudoBoardPaths(<LudoPlayerPath>[
      LudoPlayerPath(
        playerId: 'orange',
        mainTrackCells: List<int>.generate(8, (i) => i),
        homeLaneCells: <int>[100, 101, 102],
        trackLength: 8,
      ),
      LudoPlayerPath(
        playerId: 'blue',
        mainTrackCells: List<int>.generate(8, (i) => (i + 4) % 8),
        homeLaneCells: <int>[110, 111, 112],
        trackLength: 8,
      ),
    ]);
    engine = PathBasedLocalGameEngine(
      paths: paths,
      safeCellIndexes: const <int>{0, 4},
      maxConsecutiveSixes: 3,
    );
    initial = LocalGameState(
      players: const <String>['orange', 'blue'],
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
        const LocalPawn(
          id: 'o2',
          playerId: 'orange',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
      ],
      currentPlayerIndex: 0,
    );
  });

  test('roll plus move enters pawn and emits move event', () {
    final rolled = engine.roll(
      initial,
      playerId: 'orange',
      expectedVersion: 0,
      value: 6,
    );
    expect(rolled.state.pendingRoll, 6);
    expect(engine.legalPawnIds(rolled.state), contains('o1'));

    final moved = engine.move(
      rolled.state,
      playerId: 'orange',
      expectedVersion: rolled.state.version,
      pawnId: 'o1',
    );
    expect(moved.state.pawns.first.position.section, PawnRouteSection.mainTrack);
    expect(moved.state.pawns.first.position.progress, 0);
    expect(moved.events.map((event) => event.type), contains('PawnMoved'));
  });

  test('rejects stale action version without mutating input state', () {
    expect(
      () => engine.roll(
        initial,
        playerId: 'orange',
        expectedVersion: 5,
        value: 6,
      ),
      throwsA(isA<LocalGameException>()),
    );
    expect(initial.version, 0);
    expect(initial.pendingRoll, isNull);
  });

  test('rejects a player acting out of turn', () {
    expect(
      () => engine.roll(
        initial,
        playerId: 'blue',
        expectedVersion: 0,
        value: 6,
      ),
      throwsA(isA<LocalGameException>()),
    );
  });

  test('roll with no legal move advances turn for a non-six', () {
    final result = engine.roll(
      initial,
      playerId: 'orange',
      expectedVersion: 0,
      value: 3,
    );
    expect(result.state.currentPlayerId, 'blue');
    expect(result.state.pendingRoll, isNull);
    expect(result.events.map((event) => event.type), contains('NoLegalMove'));
  });

  test('third consecutive six ends the turn without a move', () {
    final state = LocalGameState(
      players: initial.players,
      pawns: initial.pawns,
      currentPlayerIndex: 0,
      consecutiveSixes: 2,
      version: 7,
    );
    final result = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: 7,
      value: 6,
    );
    expect(result.state.currentPlayerId, 'blue');
    expect(result.state.pendingRoll, isNull);
    expect(result.events.map((event) => event.type), contains('TurnEnded'));
  });
}
