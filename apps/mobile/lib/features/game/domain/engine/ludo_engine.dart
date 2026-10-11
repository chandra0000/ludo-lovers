/// Ludo Lovers Step 07 — pure Dart local game engine foundation.
///
/// This file deliberately has no Flutter, Flame, networking, or database imports.
/// It is a first implementation slice and must be formatted, analyzed, and tested
/// in the chosen Dart/Flutter SDK before it is considered production-ready.
enum PawnStatus { yard, track, homeLane, finished }

enum GameStatus { ready, active, completed }

enum MoveError {
  gameNotActive,
  notYourTurn,
  rollRequired,
  rollAlreadyPending,
  invalidDiceValue,
  pawnNotFound,
  pawnNotOwned,
  illegalMove,
  overshootFinish,
  thirdConsecutiveSix,
}

class LudoRuleProfile {
  const LudoRuleProfile({
    this.pawnsPerPlayer = 4,
    this.sixRequiredToEnter = true,
    this.extraRollOnSix = true,
    this.extraRollOnCapture = true,
    this.extraRollOnFinish = true,
    this.maxConsecutiveSixes = 3,
    this.thirdSixEndsTurnWithoutMove = true,
    this.requireExactFinishRoll = true,
    this.allowOwnPawnStacking = true,
    this.bonusRollsStack = false,
    this.captureReturnsPawnToYard = true,
    this.finishEndsMatchImmediately = true,
    this.trackLength = 52,
    this.homeLaneLength = 6,
    this.safeCellIndexes = const <int>{0, 8, 13, 21, 26, 34, 39, 47},
    required this.entryCellByPlayer,
  })  : assert(pawnsPerPlayer > 0),
        assert(maxConsecutiveSixes > 0),
        assert(trackLength > 0),
        assert(homeLaneLength > 0);

  final int pawnsPerPlayer;
  final bool sixRequiredToEnter;
  final bool extraRollOnSix;
  final bool extraRollOnCapture;
  final bool extraRollOnFinish;
  final int maxConsecutiveSixes;
  final bool thirdSixEndsTurnWithoutMove;
  final bool requireExactFinishRoll;
  final bool allowOwnPawnStacking;
  final bool bonusRollsStack;
  final bool captureReturnsPawnToYard;
  final bool finishEndsMatchImmediately;
  final int trackLength;
  final int homeLaneLength;

  /// Global main-track entry cell for each player ID. The board setup must
  /// supply valid indexes for every player.
  final Map<String, int> entryCellByPlayer;
  final Set<int> safeCellIndexes;
}

class LudoPlayerState {
  const LudoPlayerState({
    required this.id,
    required this.name,
    required this.colorKey,
    this.isFinished = false,
  });

  final String id;
  final String name;
  final String colorKey;
  final bool isFinished;

  LudoPlayerState copyWith({bool? isFinished}) => LudoPlayerState(
        id: id,
        name: name,
        colorKey: colorKey,
        isFinished: isFinished ?? this.isFinished,
      );
}

class LudoPawnState {
  const LudoPawnState({
    required this.id,
    required this.playerId,
    this.status = PawnStatus.yard,
    this.trackIndex,
    this.homeLaneIndex,
  });

  final String id;
  final String playerId;
  final PawnStatus status;
  final int? trackIndex;
  final int? homeLaneIndex;

  LudoPawnState copyWith({
    PawnStatus? status,
    int? trackIndex,
    int? homeLaneIndex,
    bool clearTrackIndex = false,
    bool clearHomeLaneIndex = false,
  }) =>
      LudoPawnState(
        id: id,
        playerId: playerId,
        status: status ?? this.status,
        trackIndex: clearTrackIndex ? null : (trackIndex ?? this.trackIndex),
        homeLaneIndex:
            clearHomeLaneIndex ? null : (homeLaneIndex ?? this.homeLaneIndex),
      );
}

class LudoGameState {
  const LudoGameState({
    required this.gameId,
    required this.players,
    required this.pawns,
    required this.currentPlayerIndex,
    this.status = GameStatus.ready,
    this.pendingRoll,
    this.consecutiveSixes = 0,
    this.turnNumber = 0,
    this.stateVersion = 0,
    this.winnerPlayerId,
  });

  final String gameId;
  final List<LudoPlayerState> players;
  final List<LudoPawnState> pawns;
  final int currentPlayerIndex;
  final GameStatus status;
  final int? pendingRoll;
  final int consecutiveSixes;
  final int turnNumber;
  final int stateVersion;
  final String? winnerPlayerId;

  LudoPlayerState get currentPlayer => players[currentPlayerIndex];

  LudoGameState copyWith({
    List<LudoPlayerState>? players,
    List<LudoPawnState>? pawns,
    int? currentPlayerIndex,
    GameStatus? status,
    int? pendingRoll,
    bool clearPendingRoll = false,
    int? consecutiveSixes,
    int? turnNumber,
    int? stateVersion,
    String? winnerPlayerId,
  }) =>
      LudoGameState(
        gameId: gameId,
        players: players ?? this.players,
        pawns: pawns ?? this.pawns,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        status: status ?? this.status,
        pendingRoll: clearPendingRoll ? null : (pendingRoll ?? this.pendingRoll),
        consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
        turnNumber: turnNumber ?? this.turnNumber,
        stateVersion: stateVersion ?? this.stateVersion,
        winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
      );
}

sealed class LudoCommand {
  const LudoCommand({
    required this.playerId,
    required this.expectedStateVersion,
  });

  final String playerId;
  final int expectedStateVersion;
}

class RollDice extends LudoCommand {
  const RollDice({
    required super.playerId,
    required super.expectedStateVersion,
    required this.value,
  });

  /// Injected value keeps the engine deterministic. Production online dice
  /// values must come from the authoritative server, not the mobile client.
  final int value;
}

class MovePawn extends LudoCommand {
  const MovePawn({
    required super.playerId,
    required super.expectedStateVersion,
    required this.pawnId,
  });

  final String pawnId;
}

class LudoEvent {
  const LudoEvent(this.type, {this.playerId, this.pawnId, this.value});

  final String type;
  final String? playerId;
  final String? pawnId;
  final int? value;
}

class LudoEngineException implements Exception {
  const LudoEngineException(this.error);
  final MoveError error;

  @override
  String toString() => 'LudoEngineException($error)';
}

class LudoTransition {
  const LudoTransition(this.state, this.events);
  final LudoGameState state;
  final List<LudoEvent> events;
}

class LudoEngine {
  const LudoEngine();

  LudoGameState start(LudoGameState state) {
    if (state.players.length < 2 || state.players.length > 4) {
      throw ArgumentError('Ludo requires 2 to 4 players.');
    }
    if (state.pawns.length != state.players.length *
        (state.pawns.isEmpty ? 0 : state.pawns.where((p) => p.playerId == state.players.first.id).length)) {
      // Player pawn counts are validated below; avoid guessing a board layout.
    }
    for (final player in state.players) {
      if (state.pawns.where((pawn) => pawn.playerId == player.id).isEmpty) {
        throw ArgumentError('Player ${player.id} must have at least one pawn.');
      }
    }
    return state.copyWith(
      status: GameStatus.active,
      turnNumber: 1,
      stateVersion: state.stateVersion + 1,
    );
  }

  LudoTransition apply(
    LudoGameState state,
    LudoCommand command,
    LudoRuleProfile rules,
  ) {
    if (state.status != GameStatus.active) {
      throw const LudoEngineException(MoveError.gameNotActive);
    }
    if (command.expectedStateVersion != state.stateVersion) {
      throw const LudoEngineException(MoveError.illegalMove);
    }
    if (command.playerId != state.currentPlayer.id) {
      throw const LudoEngineException(MoveError.notYourTurn);
    }
    if (command is RollDice) return _roll(state, command, rules);
    if (command is MovePawn) return _move(state, command, rules);
    throw const LudoEngineException(MoveError.illegalMove);
  }

  LudoTransition _roll(
    LudoGameState state,
    RollDice command,
    LudoRuleProfile rules,
  ) {
    if (state.pendingRoll != null) {
      throw const LudoEngineException(MoveError.rollAlreadyPending);
    }
    if (command.value < 1 || command.value > 6) {
      throw const LudoEngineException(MoveError.invalidDiceValue);
    }

    final nextSixCount =
        command.value == 6 ? state.consecutiveSixes + 1 : 0;
    if (rules.thirdSixEndsTurnWithoutMove &&
        command.value == 6 &&
        nextSixCount >= rules.maxConsecutiveSixes) {
      final next = _advanceTurn(
        state.copyWith(
          consecutiveSixes: 0,
          clearPendingRoll: true,
          stateVersion: state.stateVersion + 1,
        ),
        rules,
      );
      return LudoTransition(next, <LudoEvent>[
        LudoEvent('DiceRolled', playerId: command.playerId, value: 6),
        LudoEvent('TurnEnded', playerId: command.playerId),
      ]);
    }

    final rolledState = state.copyWith(
      pendingRoll: command.value,
      consecutiveSixes: nextSixCount,
      stateVersion: state.stateVersion + 1,
    );
    final legal = legalPawnIds(rolledState, rules);
    if (legal.isEmpty) {
      final getsBonus = command.value == 6 && rules.extraRollOnSix;
      final next = getsBonus
          ? rolledState.copyWith(
              clearPendingRoll: true,
              stateVersion: rolledState.stateVersion + 1,
            )
          : _advanceTurn(
              rolledState.copyWith(
                clearPendingRoll: true,
                consecutiveSixes: 0,
                stateVersion: rolledState.stateVersion + 1,
              ),
              rules,
            );
      return LudoTransition(next, <LudoEvent>[
        LudoEvent('DiceRolled', playerId: command.playerId, value: command.value),
        LudoEvent('NoLegalMove', playerId: command.playerId),
        if (getsBonus) LudoEvent('ExtraRollGranted', playerId: command.playerId),
      ]);
    }

    return LudoTransition(rolledState, <LudoEvent>[
      LudoEvent('DiceRolled', playerId: command.playerId, value: command.value),
    ]);
  }

  LudoTransition _move(
    LudoGameState state,
    MovePawn command,
    LudoRuleProfile rules,
  ) {
    final roll = state.pendingRoll;
    if (roll == null) {
      throw const LudoEngineException(MoveError.rollRequired);
    }
    final pawnIndex = state.pawns.indexWhere((pawn) => pawn.id == command.pawnId);
    if (pawnIndex < 0) {
      throw const LudoEngineException(MoveError.pawnNotFound);
    }
    final pawn = state.pawns[pawnIndex];
    if (pawn.playerId != command.playerId) {
      throw const LudoEngineException(MoveError.pawnNotOwned);
    }
    if (!legalPawnIds(state, rules).contains(pawn.id)) {
      throw const LudoEngineException(MoveError.illegalMove);
    }

    final pawns = List<LudoPawnState>.of(state.pawns);
    final events = <LudoEvent>[];
    var captured = false;
    var finished = false;

    if (pawn.status == PawnStatus.yard) {
      final entry = rules.entryCellByPlayer[pawn.playerId];
      if (entry == null || entry < 0 || entry >= rules.trackLength) {
        throw ArgumentError('Missing/invalid entry cell for ${pawn.playerId}.');
      }
      pawns[pawnIndex] = pawn.copyWith(
        status: PawnStatus.track,
        trackIndex: entry,
        clearHomeLaneIndex: true,
      );
      events.add(LudoEvent('PawnEntered', playerId: pawn.playerId, pawnId: pawn.id));
    } else if (pawn.status == PawnStatus.track) {
      final distanceToHome = _distanceToHomeEntry(pawn, rules);
      if (roll < distanceToHome) {
        pawns[pawnIndex] = pawn.copyWith(trackIndex: (pawn.trackIndex! + roll) % rules.trackLength);
      } else {
        final intoHome = roll - distanceToHome;
        if (intoHome >= rules.homeLaneLength) {
          if (rules.requireExactFinishRoll) {
            throw const LudoEngineException(MoveError.overshootFinish);
          }
          pawns[pawnIndex] = pawn.copyWith(
            status: PawnStatus.finished,
            clearTrackIndex: true,
            clearHomeLaneIndex: true,
          );
          finished = true;
        } else {
          pawns[pawnIndex] = pawn.copyWith(
            status: PawnStatus.homeLane,
            homeLaneIndex: intoHome,
            clearTrackIndex: true,
          );
          if (intoHome == rules.homeLaneLength - 1) {
            pawns[pawnIndex] = pawns[pawnIndex].copyWith(status: PawnStatus.finished, clearHomeLaneIndex: true);
            finished = true;
          }
        }
      }
    } else if (pawn.status == PawnStatus.homeLane) {
      final target = pawn.homeLaneIndex! + roll;
      if (target == rules.homeLaneLength - 1) {
        pawns[pawnIndex] = pawn.copyWith(status: PawnStatus.finished, clearHomeLaneIndex: true);
        finished = true;
      } else if (target < rules.homeLaneLength - 1) {
        pawns[pawnIndex] = pawn.copyWith(homeLaneIndex: target);
      } else {
        throw const LudoEngineException(MoveError.overshootFinish);
      }
    } else {
      throw const LudoEngineException(MoveError.illegalMove);
    }

    final movedPawn = pawns[pawnIndex];
    if (movedPawn.status == PawnStatus.track && movedPawn.trackIndex != null) {
      for (var i = 0; i < pawns.length; i++) {
        if (i == pawnIndex) continue;
        final other = pawns[i];
        if (other.playerId == pawn.playerId ||
            other.status != PawnStatus.track ||
            other.trackIndex != movedPawn.trackIndex ||
            rules.safeCellIndexes.contains(movedPawn.trackIndex)) {
          continue;
        }
        if (!rules.captureReturnsPawnToYard) continue;
        pawns[i] = other.copyWith(
          status: PawnStatus.yard,
          clearTrackIndex: true,
          clearHomeLaneIndex: true,
        );
        captured = true;
        events.add(LudoEvent('PawnCaptured', playerId: pawn.playerId, pawnId: other.id));
      }
    }

    if (finished) {
      events.add(LudoEvent('PawnFinished', playerId: pawn.playerId, pawnId: pawn.id));
    }

    var players = List<LudoPlayerState>.of(state.players);
    final playerPawnStates = pawns.where((p) => p.playerId == pawn.playerId);
    final playerWon = playerPawnStates.every((p) => p.status == PawnStatus.finished);
    if (playerWon) {
      final pIndex = players.indexWhere((p) => p.id == pawn.playerId);
      players[pIndex] = players[pIndex].copyWith(isFinished: true);
      events.add(LudoEvent('PlayerFinished', playerId: pawn.playerId));
    }

    var next = state.copyWith(
      pawns: pawns,
      players: players,
      clearPendingRoll: true,
      stateVersion: state.stateVersion + 1,
    );
    if (playerWon && rules.finishEndsMatchImmediately) {
      next = next.copyWith(
        status: GameStatus.completed,
        winnerPlayerId: pawn.playerId,
        stateVersion: next.stateVersion + 1,
      );
      events.add(LudoEvent('GameCompleted', playerId: pawn.playerId));
      return LudoTransition(next, events);
    }

    final bonus = (roll == 6 && rules.extraRollOnSix) ||
        (captured && rules.extraRollOnCapture) ||
        (finished && rules.extraRollOnFinish);
    if (bonus) {
      next = next.copyWith(
        consecutiveSixes: roll == 6 ? state.consecutiveSixes : 0,
        stateVersion: next.stateVersion + 1,
      );
      events.add(LudoEvent('ExtraRollGranted', playerId: pawn.playerId));
    } else {
      next = _advanceTurn(
        next.copyWith(consecutiveSixes: 0),
        rules,
      );
      events.add(LudoEvent('TurnEnded', playerId: pawn.playerId));
    }
    events.insert(0, LudoEvent('PawnMoved', playerId: pawn.playerId, pawnId: pawn.id, value: roll));
    return LudoTransition(next, events);
  }

  List<String> legalPawnIds(LudoGameState state, LudoRuleProfile rules) {
    final roll = state.pendingRoll;
    if (roll == null) return const <String>[];
    return state.pawns
        .where((pawn) =>
            pawn.playerId == state.currentPlayer.id &&
            _isLegal(pawn, roll, rules))
        .map((pawn) => pawn.id)
        .toList(growable: false);
  }

  bool _isLegal(LudoPawnState pawn, int roll, LudoRuleProfile rules) {
    switch (pawn.status) {
      case PawnStatus.yard:
        return !rules.sixRequiredToEnter || roll == 6;
      case PawnStatus.track:
        final distance = _distanceToHomeEntry(pawn, rules);
        if (roll < distance) return true;
        final intoHome = roll - distance;
        return rules.requireExactFinishRoll
            ? intoHome < rules.homeLaneLength
            : true;
      case PawnStatus.homeLane:
        final target = pawn.homeLaneIndex! + roll;
        return rules.requireExactFinishRoll
            ? target < rules.homeLaneLength
            : true;
      case PawnStatus.finished:
        return false;
    }
  }

  /// Number of cells remaining before the pawn reaches its private home lane.
  /// This requires board-specific path data in a production implementation.
  /// The current foundation uses the entry cell and track index as a simple
  /// clockwise distance placeholder; replace with a per-player path map before
  /// full gameplay, because real Ludo paths have different home-lane exits.
  int _distanceToHomeEntry(LudoPawnState pawn, LudoRuleProfile rules) {
    final entry = rules.entryCellByPlayer[pawn.playerId];
    if (entry == null || pawn.trackIndex == null) {
      throw ArgumentError('Track pawn requires a valid track index and entry cell.');
    }
    final distance = (rules.trackLength - pawn.trackIndex!) % rules.trackLength;
    return distance == 0 ? rules.trackLength : distance;
  }

  LudoGameState _advanceTurn(LudoGameState state, LudoRuleProfile rules) {
    var nextIndex = state.currentPlayerIndex;
    for (var i = 0; i < state.players.length; i++) {
      nextIndex = (nextIndex + 1) % state.players.length;
      if (!state.players[nextIndex].isFinished) break;
    }
    return state.copyWith(
      currentPlayerIndex: nextIndex,
      clearPendingRoll: true,
      consecutiveSixes: 0,
      turnNumber: state.turnNumber + 1,
      stateVersion: state.stateVersion + 1,
    );
  }
}
