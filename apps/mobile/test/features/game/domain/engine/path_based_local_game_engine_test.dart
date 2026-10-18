import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_rule_profile.dart';
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
      LudoPlayerPath(
        playerId: 'green',
        mainTrackCells: List<int>.generate(8, (i) => (i + 2) % 8),
        homeLaneCells: <int>[120, 121, 122],
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
    expect(initial.version, 0, reason: 'Accepted commands must not mutate the prior snapshot.');
    expect(initial.pendingRoll, isNull);
    expect(
      initial.pawns.every((pawn) => pawn.position.section == PawnRouteSection.yard),
      isTrue,
    );
    expect(rolled.state.version, initial.version + 1);
    expect(rolled.events.single, isA<DiceRolled>());
    expect(rolled.events.single.kind, LocalGameEventKind.diceRolled);
    expect(rolled.events.single.stateVersion, rolled.state.version);
    expect(rolled.events.single.sequence, 0);
    expect(engine.legalPawnIds(rolled.state), contains('o1'));

    final moved = engine.move(
      rolled.state,
      playerId: 'orange',
      expectedVersion: rolled.state.version,
      pawnId: 'o1',
    );
    expect(rolled.state.pendingRoll, 6, reason: 'A later move must not consume an older snapshot.');
    expect(rolled.state.pawns.first.position.section, PawnRouteSection.yard);
    expect(moved.state.pawns.first.position.section, PawnRouteSection.mainTrack);
    expect(moved.state.currentPlayerId, 'orange', reason: 'A six grants the same player another roll.');
    expect(moved.state.pawns.first.position.progress, 0);
    expect(moved.state.version, rolled.state.version + 1);
    expect(moved.events.map((event) => event.type), contains('PawnMoved'));
    expect(moved.events.every((event) => event.stateVersion == moved.state.version), isTrue);
    expect(
      moved.events.map((event) => event.sequence),
      List<int>.generate(moved.events.length, (index) => index),
    );
    expect(
      moved.events.singleWhere((event) => event.type == 'PawnMoved').kind,
      LocalGameEventKind.pawnMoved,
    );
  });

  test('state snapshots defensively copy and freeze player and pawn collections', () {
    final sourcePlayers = <String>['orange', 'blue'];
    final sourcePawns = <LocalPawn>[...initial.pawns];
    final snapshot = LocalGameState(
      players: sourcePlayers,
      pawns: sourcePawns,
      currentPlayerIndex: 0,
    );

    sourcePlayers[0] = 'green';
    sourcePawns.clear();

    expect(snapshot.players, <String>['orange', 'blue']);
    expect(snapshot.pawns, hasLength(3));
    expect(
      () => snapshot.players.add('green'),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.pawns.clear(),
      throwsUnsupportedError,
    );
  });

  test('transition events are copied, frozen, and stamped in deterministic order', () {
    final sourceEvents = <LocalGameEvent>[
      const DiceRolled(playerId: 'orange', value: 6),
      const TurnEnded(playerId: 'orange'),
    ];
    final transition = LocalGameTransition(initial, sourceEvents);

    sourceEvents.clear();

    expect(transition.events, hasLength(2));
    expect(
      transition.events.map((event) => event.stateVersion),
      <int?>[initial.version, initial.version],
    );
    expect(transition.events.map((event) => event.sequence), <int?>[0, 1]);
    expect(
      () => transition.events.add(const TurnEnded(playerId: 'orange')),
      throwsUnsupportedError,
    );
  });

  test('rejects pawn progress that does not match its route section', () {
    final malformed = LocalGameState(
      players: const <String>['orange', 'blue'],
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 8,
          ),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
      ],
    );

    expect(
      () => engine.roll(
        malformed,
        playerId: 'orange',
        expectedVersion: malformed.version,
        value: 1,
      ),
      throwsA(
        isA<LocalGameException>().having(
          (error) => error.error,
          'error',
          LocalActionError.invalidState,
        ),
      ),
    );
    expect(malformed.version, 0, reason: 'Rejected actions never mutate input.');
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

  test('rejects every action after match completion without mutating state', () {
    final completed = LocalGameState(
      players: initial.players,
      pawns: initial.pawns,
      currentPlayerIndex: 0,
      pendingRoll: 6,
      completed: true,
      winnerPlayerId: 'orange',
      version: 12,
    );

    for (final action in <void Function()>[
      () => engine.roll(
            completed,
            playerId: 'orange',
            expectedVersion: completed.version,
            value: 4,
          ),
      () => engine.move(
            completed,
            playerId: 'orange',
            expectedVersion: completed.version,
            pawnId: 'o1',
          ),
    ]) {
      expect(
        action,
        throwsA(
          isA<LocalGameException>().having(
            (error) => error.error,
            'error',
            LocalActionError.gameCompleted,
          ),
        ),
      );
    }

    expect(completed.completed, isTrue);
    expect(completed.winnerPlayerId, 'orange');
    expect(completed.pendingRoll, 6);
    expect(completed.version, 12);
    expect(
      completed.pawns.map((pawn) => (pawn.id, pawn.position.section, pawn.position.progress)),
      initial.pawns.map((pawn) => (pawn.id, pawn.position.section, pawn.position.progress)),
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
    expect(result.state.version, initial.version + 1,
        reason: 'A roll command advances the state version exactly once.');
    expect(result.events.map((event) => event.type), contains('NoLegalMove'));
    expect(
      result.events.map((event) => event.stateVersion),
      everyElement(result.state.version),
    );
    expect(
      result.events.map((event) => event.sequence),
      <int?>[0, 1, 2],
    );
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
    expect(result.state.version, state.version + 1,
        reason: 'Third-six turn handling is still one accepted command.');
    expect(result.events.every((event) => event.stateVersion == result.state.version), isTrue);
    expect(result.events.map((event) => event.type), contains('TurnEnded'));
  });

  test('captures a single opponent pawn on a non-safe destination', () {
    final state = LocalGameState(
      players: initial.players,
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
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
      ],
    );
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

    expect(moved.state.pawns.first.position.progress, 2);
    expect(moved.state.pawns[2].position.section, PawnRouteSection.yard);
    final captureEvents = moved.events
        .where((event) => event.type == 'PawnCaptured')
        .toList(growable: false);
    expect(captureEvents, hasLength(1));
    expect(captureEvents.single, isA<PawnCaptured>());
    expect((captureEvents.single as PawnCaptured).capturedPawnId, 'b1',
        reason: 'Capture payload must identify the captured opponent, not mover o1.');
    expect(captureEvents.single.playerId, 'orange');
    expect(moved.state.currentPlayerId, 'orange',
        reason: 'A capture grants the configured bonus roll.');
  });

  test('does not capture an opponent on a safe cell', () {
    final state = LocalGameState(
      players: initial.players,
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
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
      ],
    );
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

    expect(moved.state.pawns[1].position.section, PawnRouteSection.mainTrack);
    expect(moved.events.map((event) => event.type), isNot(contains('PawnCaptured')));
    expect(moved.state.currentPlayerId, 'blue');
  });

  test('protects a stacked pair of opponent pawns under the default rule', () {
    final state = LocalGameState(
      players: initial.players,
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 1,
          ),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 6,
          ),
        ),
        const LocalPawn(
          id: 'b2',
          playerId: 'blue',
          position: PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 6,
          ),
        ),
      ],
    );
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

    expect(moved.state.pawns[1].position.section, PawnRouteSection.mainTrack);
    expect(moved.state.pawns[2].position.section, PawnRouteSection.mainTrack);
    expect(moved.events.map((event) => event.type), isNot(contains('PawnCaptured')));
    expect(moved.state.currentPlayerId, 'blue');
  });

  test('declares the winner when the last pawn reaches finish', () {
    final state = LocalGameState(
      players: initial.players,
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: 11,
          ),
        ),
        const LocalPawn(
          id: 'o2',
          playerId: 'orange',
          position: PawnRoutePosition(
            section: PawnRouteSection.homeLane,
            progress: 10,
          ),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
      ],
    );
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
      pawnId: 'o2',
    );

    expect(moved.state.completed, isTrue);
    expect(moved.state.winnerPlayerId, 'orange');
    expect(moved.state.pendingRoll, isNull);
    expect(moved.events.map((event) => event.type), contains('PawnFinished'));
    expect(moved.events.map((event) => event.type), contains('GameCompleted'));
    expect(
      () => engine.roll(
        moved.state,
        playerId: 'orange',
        expectedVersion: moved.state.version,
        value: 1,
      ),
      throwsA(isA<LocalGameException>()),
    );
  });


  test('rejects a second roll while a move is pending', () {
    final rolled = engine.roll(
      initial,
      playerId: 'orange',
      expectedVersion: initial.version,
      value: 6,
    );
    expect(
      () => engine.roll(
        rolled.state,
        playerId: 'orange',
        expectedVersion: rolled.state.version,
        value: 2,
      ),
      throwsA(
        isA<LocalGameException>().having(
          (error) => error.error,
          'error',
          LocalActionError.rollAlreadyPending,
        ),
      ),
    );
  });

  test('rejects an invalid pawn move without consuming the roll', () {
    final state = LocalGameState(
      players: initial.players,
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
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
      ],
    );
    final rolled = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 2,
    );
    expect(rolled.state.pendingRoll, 2);
    expect(rolled.state.currentPlayerId, 'orange');
    expect(
      () => engine.move(
        rolled.state,
        playerId: 'orange',
        expectedVersion: rolled.state.version,
        pawnId: 'o1',
      ),
      throwsA(
        isA<LocalGameException>().having(
          (error) => error.error,
          'error',
          LocalActionError.illegalMove,
        ),
      ),
    );
    expect(rolled.state.pendingRoll, 2);
  });

  test('rejects malformed player and pawn identity state', () {
    expect(
      () => LocalGameState(
        players: const <String>['orange', 'orange'],
        pawns: initial.pawns,
        currentPlayerIndex: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => LocalGameState(
        players: const <String>['orange', 'blue'],
        pawns: <LocalPawn>[
          const LocalPawn(
            id: 'same',
            playerId: 'orange',
            position: PawnRoutePosition(section: PawnRouteSection.yard),
          ),
          const LocalPawn(
            id: 'same',
            playerId: 'blue',
            position: PawnRoutePosition(section: PawnRouteSection.yard),
          ),
        ],
        currentPlayerIndex: 0,
      ),
      throwsArgumentError,
    );
  });


  test('skips a player whose pawns are all finished', () {
    final state = LocalGameState(
      players: const <String>['orange', 'blue', 'green'],
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: 11,
          ),
        ),
        const LocalPawn(
          id: 'g1',
          playerId: 'green',
          position: PawnRoutePosition(section: PawnRouteSection.yard),
        ),
      ],
    );

    final result = engine.roll(
      state,
      playerId: 'orange',
      expectedVersion: state.version,
      value: 3,
    );

    expect(result.state.currentPlayerId, 'green');
    expect(result.state.pendingRoll, isNull);
  });

  test('fails loudly rather than selecting a player when nobody can continue', () {
    final state = LocalGameState(
      players: const <String>['orange', 'blue'],
      currentPlayerIndex: 0,
      pawns: <LocalPawn>[
        const LocalPawn(
          id: 'o1',
          playerId: 'orange',
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: 11,
          ),
        ),
        const LocalPawn(
          id: 'b1',
          playerId: 'blue',
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: 11,
          ),
        ),
      ],
    );

    expect(
      () => engine.roll(
        state,
        playerId: 'orange',
        expectedVersion: state.version,
        value: 3,
      ),
      throwsA(isA<StateError>()),
    );
  });


  test('replays the same command sequence deterministically', () {
    LocalGameTransition playSequence() {
      final rolled = engine.roll(
        initial,
        playerId: 'orange',
        expectedVersion: initial.version,
        value: 6,
      );
      return engine.move(
        rolled.state,
        playerId: 'orange',
        expectedVersion: rolled.state.version,
        pawnId: 'o1',
      );
    }

    final first = playSequence();
    final replay = playSequence();

    expect(replay.state.version, first.state.version);
    expect(replay.state.currentPlayerId, first.state.currentPlayerId);
    expect(replay.state.pendingRoll, first.state.pendingRoll);
    expect(replay.state.consecutiveSixes, first.state.consecutiveSixes);
    expect(replay.state.completed, first.state.completed);
    expect(replay.state.winnerPlayerId, first.state.winnerPlayerId);
    expect(
      replay.state.pawns.map((pawn) => (
        pawn.id,
        pawn.playerId,
        pawn.position.section,
        pawn.position.progress,
      )).toList(),
      first.state.pawns.map((pawn) => (
        pawn.id,
        pawn.playerId,
        pawn.position.section,
        pawn.position.progress,
      )).toList(),
    );
    expect(
      replay.events.map((event) => (
        event.type,
        event.playerId,
        event.pawnId,
        event.value,
        event.stateVersion,
        event.sequence,
      )).toList(),
      first.events.map((event) => (
        event.type,
        event.playerId,
        event.pawnId,
        event.value,
        event.stateVersion,
        event.sequence,
      )).toList(),
    );
  });

}
