/// Path-based local gameplay transition service for Ludo Lovers.
///
/// This is an integration layer for the path model and movement resolver. It is
/// deliberately separate from the original LudoEngine until the project is
/// configured and both APIs can be migrated with executable tests.
import '../board/ludo_board_paths.dart';
import 'ludo_path_movement.dart';

class LocalPawn {
  const LocalPawn({
    required this.id,
    required this.playerId,
    required this.position,
  });

  final String id;
  final String playerId;
  final PawnRoutePosition position;

  LocalPawn copyWith({PawnRoutePosition? position}) => LocalPawn(
        id: id,
        playerId: playerId,
        position: position ?? this.position,
      );
}

class LocalGameState {
  LocalGameState({
    required this.players,
    required List<LocalPawn> pawns,
    required this.currentPlayerIndex,
    this.pendingRoll,
    this.consecutiveSixes = 0,
    this.completed = false,
    this.winnerPlayerId,
    this.version = 0,
  }) : pawns = List<LocalPawn>.unmodifiable(pawns),
       players = List<String>.unmodifiable(players);

  final List<String> players;
  final List<LocalPawn> pawns;
  final int currentPlayerIndex;
  final int? pendingRoll;
  final int consecutiveSixes;
  final bool completed;
  final String? winnerPlayerId;
  final int version;

  String get currentPlayerId => players[currentPlayerIndex];

  LocalGameState copyWith({
    List<LocalPawn>? pawns,
    int? currentPlayerIndex,
    int? pendingRoll,
    bool clearPendingRoll = false,
    int? consecutiveSixes,
    bool? completed,
    String? winnerPlayerId,
    int? version,
  }) => LocalGameState(
        players: players,
        pawns: pawns ?? this.pawns,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        pendingRoll: clearPendingRoll ? null : (pendingRoll ?? this.pendingRoll),
        consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
        completed: completed ?? this.completed,
        winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
        version: version ?? this.version,
      );
}

enum LocalActionError {
  gameCompleted,
  wrongPlayer,
  staleVersion,
  rollAlreadyPending,
  rollRequired,
  invalidRoll,
  pawnNotFound,
  pawnNotOwned,
  illegalMove,
}

class LocalGameException implements Exception {
  const LocalGameException(this.error);
  final LocalActionError error;

  @override
  String toString() => 'LocalGameException($error)';
}

class LocalGameEvent {
  const LocalGameEvent(this.type, {this.playerId, this.pawnId, this.value});
  final String type;
  final String? playerId;
  final String? pawnId;
  final int? value;
}

class LocalGameTransition {
  const LocalGameTransition(this.state, this.events);
  final LocalGameState state;
  final List<LocalGameEvent> events;
}

/// Small, deterministic engine service. Board-specific paths must be reviewed
/// against the final board diagram before shipping.
class PathBasedLocalGameEngine {
  const PathBasedLocalGameEngine({
    required this.paths,
    this.movement = const LudoPathMovement(),
    this.safeCellIndexes = const <int>{},
    this.sixRequiredToEnter = true,
    this.extraRollOnSix = true,
    this.extraRollOnCapture = true,
    this.extraRollOnFinish = true,
    this.requireExactFinishRoll = true,
    this.maxConsecutiveSixes = 3,
    this.thirdSixEndsTurnWithoutMove = true,
    this.finishEndsMatchImmediately = true,
    this.captureOnlySingleOpponentPawn = true,
  });

  final LudoBoardPaths paths;
  final LudoPathMovement movement;
  final Set<int> safeCellIndexes;
  final bool sixRequiredToEnter;
  final bool extraRollOnSix;
  final bool extraRollOnCapture;
  final bool extraRollOnFinish;
  final bool requireExactFinishRoll;
  final int maxConsecutiveSixes;
  final bool thirdSixEndsTurnWithoutMove;
  final bool finishEndsMatchImmediately;

  /// When true, a destination occupied by two or more opponent pawns is treated
  /// as a stack and none of them are captured. This is a configurable local-MVP
  /// rule; confirm it against the final published rules before release.
  final bool captureOnlySingleOpponentPawn;

  LocalGameTransition roll(
    LocalGameState state, {
    required String playerId,
    required int expectedVersion,
    required int value,
  }) {
    _validateAction(state, playerId, expectedVersion);
    if (state.pendingRoll != null) {
      throw const LocalGameException(LocalActionError.rollAlreadyPending);
    }
    if (value < 1 || value > 6) {
      throw const LocalGameException(LocalActionError.invalidRoll);
    }
    final sixCount = value == 6 ? state.consecutiveSixes + 1 : 0;
    if (thirdSixEndsTurnWithoutMove &&
        value == 6 &&
        sixCount >= maxConsecutiveSixes) {
      final next = _advance(state.copyWith(
        consecutiveSixes: 0,
        version: state.version + 1,
      ));
      return LocalGameTransition(next, <LocalGameEvent>[
        LocalGameEvent('DiceRolled', playerId: playerId, value: value),
        LocalGameEvent('TurnEnded', playerId: playerId),
      ]);
    }

    final rolled = state.copyWith(
      pendingRoll: value,
      consecutiveSixes: sixCount,
      version: state.version + 1,
    );
    final legal = legalPawnIds(rolled);
    if (legal.isEmpty) {
      if (value == 6 && extraRollOnSix) {
        return LocalGameTransition(
          rolled.copyWith(clearPendingRoll: true, version: rolled.version + 1),
          <LocalGameEvent>[
            LocalGameEvent('DiceRolled', playerId: playerId, value: value),
            LocalGameEvent('NoLegalMove', playerId: playerId),
            LocalGameEvent('ExtraRollGranted', playerId: playerId),
          ],
        );
      }
      return LocalGameTransition(
        _advance(rolled.copyWith(
          clearPendingRoll: true,
          consecutiveSixes: 0,
          version: rolled.version + 1,
        )),
        <LocalGameEvent>[
          LocalGameEvent('DiceRolled', playerId: playerId, value: value),
          LocalGameEvent('NoLegalMove', playerId: playerId),
          LocalGameEvent('TurnEnded', playerId: playerId),
        ],
      );
    }
    return LocalGameTransition(rolled, <LocalGameEvent>[
      LocalGameEvent('DiceRolled', playerId: playerId, value: value),
    ]);
  }

  List<String> legalPawnIds(LocalGameState state) {
    final rollValue = state.pendingRoll;
    if (rollValue == null || state.completed) return const <String>[];
    return state.pawns.where((pawn) {
      if (pawn.playerId != state.currentPlayerId) return false;
      return movement.resolve(
        path: paths.forPlayer(pawn.playerId),
        current: pawn.position,
        diceValue: rollValue,
        sixRequiredToEnter: sixRequiredToEnter,
        requireExactFinishRoll: requireExactFinishRoll,
      ).isSuccess;
    }).map((pawn) => pawn.id).toList(growable: false);
  }

  LocalGameTransition move(
    LocalGameState state, {
    required String playerId,
    required int expectedVersion,
    required String pawnId,
  }) {
    _validateAction(state, playerId, expectedVersion);
    final rollValue = state.pendingRoll;
    if (rollValue == null) {
      throw const LocalGameException(LocalActionError.rollRequired);
    }
    final index = state.pawns.indexWhere((pawn) => pawn.id == pawnId);
    if (index < 0) {
      throw const LocalGameException(LocalActionError.pawnNotFound);
    }
    final pawn = state.pawns[index];
    if (pawn.playerId != playerId) {
      throw const LocalGameException(LocalActionError.pawnNotOwned);
    }

    final result = movement.resolve(
      path: paths.forPlayer(playerId),
      current: pawn.position,
      diceValue: rollValue,
      sixRequiredToEnter: sixRequiredToEnter,
      requireExactFinishRoll: requireExactFinishRoll,
    );
    if (!result.isSuccess) {
      throw const LocalGameException(LocalActionError.illegalMove);
    }

    final pawns = List<LocalPawn>.of(state.pawns);
    pawns[index] = pawn.copyWith(position: result.resolution!.position);
    var captured = false;
    final destination = result.resolution!.destinationCell;
    if (destination != null && !safeCellIndexes.contains(destination)) {
      final opponentIndexes = <int>[];
      for (var i = 0; i < pawns.length; i++) {
        if (i == index) continue;
        final other = pawns[i];
        if (other.playerId == playerId ||
            other.position.section != PawnRouteSection.mainTrack) {
          continue;
        }
        final otherCell = paths.forPlayer(other.playerId)
            .cellAtProgress(other.position.progress!);
        if (otherCell == destination) opponentIndexes.add(i);
      }

      // A stacked pair is protected under the default MVP rule. Keep this
      // explicit and configurable because Ludo variants differ on block rules.
      if (!captureOnlySingleOpponentPawn || opponentIndexes.length == 1) {
        for (final opponentIndex in opponentIndexes) {
          pawns[opponentIndex] = pawns[opponentIndex].copyWith(
            position: const PawnRoutePosition(section: PawnRouteSection.yard),
          );
          captured = true;
        }
      }
    }

    final events = <LocalGameEvent>[
      LocalGameEvent('PawnMoved', playerId: playerId, pawnId: pawnId, value: rollValue),
    ];
    if (captured) {
      events.add(LocalGameEvent('PawnCaptured', playerId: playerId, pawnId: pawnId));
    }
    if (result.resolution!.finishes) {
      events.add(LocalGameEvent('PawnFinished', playerId: playerId, pawnId: pawnId));
    }

    final allFinished = pawns
        .where((item) => item.playerId == playerId)
        .every((item) => item.position.section == PawnRouteSection.finished);
    var next = state.copyWith(
      pawns: pawns,
      clearPendingRoll: true,
      version: state.version + 1,
    );
    if (allFinished && finishEndsMatchImmediately) {
      next = next.copyWith(
        completed: true,
        winnerPlayerId: playerId,
        version: next.version + 1,
      );
      events.add(LocalGameEvent('GameCompleted', playerId: playerId));
      return LocalGameTransition(next, events);
    }

    final bonus = (rollValue == 6 && extraRollOnSix) ||
        (captured && extraRollOnCapture) ||
        (result.resolution!.finishes && extraRollOnFinish);
    if (bonus) {
      next = next.copyWith(
        consecutiveSixes: rollValue == 6 ? state.consecutiveSixes : 0,
        version: next.version + 1,
      );
      events.add(LocalGameEvent('ExtraRollGranted', playerId: playerId));
    } else {
      next = _advance(next.copyWith(consecutiveSixes: 0));
      events.add(LocalGameEvent('TurnEnded', playerId: playerId));
    }
    return LocalGameTransition(next, events);
  }

  void _validateAction(LocalGameState state, String playerId, int version) {
    if (state.completed) {
      throw const LocalGameException(LocalActionError.gameCompleted);
    }
    if (version != state.version) {
      throw const LocalGameException(LocalActionError.staleVersion);
    }
    if (state.players.isEmpty || state.currentPlayerId != playerId) {
      throw const LocalGameException(LocalActionError.wrongPlayer);
    }
  }

  LocalGameState _advance(LocalGameState state) {
    var nextIndex = state.currentPlayerIndex;
    for (var i = 0; i < state.players.length; i++) {
      nextIndex = (nextIndex + 1) % state.players.length;
      final nextPlayer = state.players[nextIndex];
      final playerPawns = state.pawns.where((pawn) => pawn.playerId == nextPlayer);
      if (playerPawns.isNotEmpty &&
          !playerPawns.every((pawn) => pawn.position.section == PawnRouteSection.finished)) {
        break;
      }
    }
    return state.copyWith(
      currentPlayerIndex: nextIndex,
      clearPendingRoll: true,
      consecutiveSixes: 0,
      version: state.version + 1,
    );
  }
}
