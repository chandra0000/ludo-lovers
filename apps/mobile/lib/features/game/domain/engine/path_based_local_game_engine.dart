/// Path-based local gameplay transition service for Ludo Lovers.
///
/// This engine is the canonical local transition service. Board-specific paths
/// and provisional rules must be reviewed before production gameplay.
library;

import '../board/ludo_board_paths.dart';
import 'ludo_path_movement.dart';
import 'ludo_rule_profile.dart';

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
    required List<String> players,
    required List<LocalPawn> pawns,
    required this.currentPlayerIndex,
    this.pendingRoll,
    this.consecutiveSixes = 0,
    this.completed = false,
    this.winnerPlayerId,
    this.version = 0,
  }) : pawns = List<LocalPawn>.unmodifiable(pawns),
       players = List<String>.unmodifiable(players) {
    if (this.players.length < 2 || this.players.length > 4) {
      throw ArgumentError('A local game requires 2 to 4 players.');
    }
    if (this.players.any((player) => player.trim().isEmpty) ||
        this.players.toSet().length != this.players.length) {
      throw ArgumentError('Player IDs must be non-empty and unique.');
    }
    if (currentPlayerIndex < 0 || currentPlayerIndex >= this.players.length) {
      throw ArgumentError.value(currentPlayerIndex, 'currentPlayerIndex');
    }
    if (this.pawns.any((pawn) => !this.players.contains(pawn.playerId))) {
      throw ArgumentError('Every pawn must belong to a player in this game.');
    }
    if (this.players.any((player) => !this.pawns.any((pawn) => pawn.playerId == player))) {
      throw ArgumentError('Every player must have at least one pawn.');
    }
    if (this.pawns.any((pawn) => pawn.id.trim().isEmpty) ||
        this.pawns.map((pawn) => pawn.id).toSet().length != this.pawns.length) {
      throw ArgumentError('Pawn IDs must be non-empty and unique.');
    }
    final roll = pendingRoll;
    if (roll != null && (roll < 1 || roll > 6)) {
      throw ArgumentError.value(roll, 'pendingRoll');
    }
    if (consecutiveSixes < 0 || version < 0) {
      throw ArgumentError('consecutiveSixes and version cannot be negative.');
    }
    if (completed && winnerPlayerId == null) {
      throw ArgumentError('A completed game must identify its winner.');
    }
    if (winnerPlayerId != null && !this.players.contains(winnerPlayerId)) {
      throw ArgumentError('Winner must be a player in this game.');
    }
  }

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

enum LocalGameEventKind {
  diceRolled,
  turnEnded,
  noLegalMove,
  extraRollGranted,
  pawnMoved,
  pawnCaptured,
  pawnFinished,
  gameCompleted,
}

/// Typed, immutable event emitted by one accepted local state transition.
///
/// The common fields remain available to the development UI, while the
/// concrete subtype and its required payload make event handling exhaustive.
sealed class LocalGameEvent {
  const LocalGameEvent({
    this.playerId,
    this.pawnId,
    this.value,
    this.stateVersion,
    this.sequence,
  });

  final String? playerId;
  final String? pawnId;
  final int? value;
  final int? stateVersion;
  final int? sequence;

  String get type;
  LocalGameEventKind get kind;

  LocalGameEvent forTransition({required int version, required int order}) =>
      switch (this) {
        DiceRolled event => DiceRolled(
            playerId: event.playerId!,
            value: event.value!,
            stateVersion: version,
            sequence: order,
          ),
        TurnEnded event => TurnEnded(
            playerId: event.playerId!,
            stateVersion: version,
            sequence: order,
          ),
        NoLegalMove event => NoLegalMove(
            playerId: event.playerId!,
            stateVersion: version,
            sequence: order,
          ),
        ExtraRollGranted event => ExtraRollGranted(
            playerId: event.playerId!,
            stateVersion: version,
            sequence: order,
          ),
        PawnMoved event => PawnMoved(
            playerId: event.playerId!,
            pawnId: event.pawnId!,
            value: event.value!,
            stateVersion: version,
            sequence: order,
          ),
        PawnCaptured event => PawnCaptured(
            playerId: event.playerId!,
            capturedPawnId: event.pawnId!,
            stateVersion: version,
            sequence: order,
          ),
        PawnFinished event => PawnFinished(
            playerId: event.playerId!,
            pawnId: event.pawnId!,
            stateVersion: version,
            sequence: order,
          ),
        GameCompleted event => GameCompleted(
            playerId: event.playerId!,
            stateVersion: version,
            sequence: order,
          ),
      };
}

final class DiceRolled extends LocalGameEvent {
  const DiceRolled({
    required String playerId,
    required int value,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId, value: value);

  int get rollValue => value!;
  @override
  String get type => 'DiceRolled';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.diceRolled;
}

final class TurnEnded extends LocalGameEvent {
  const TurnEnded({required String playerId, super.stateVersion, super.sequence})
      : super(playerId: playerId);

  @override
  String get type => 'TurnEnded';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.turnEnded;
}

final class NoLegalMove extends LocalGameEvent {
  const NoLegalMove({required String playerId, super.stateVersion, super.sequence})
      : super(playerId: playerId);

  @override
  String get type => 'NoLegalMove';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.noLegalMove;
}

final class ExtraRollGranted extends LocalGameEvent {
  const ExtraRollGranted({
    required String playerId,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId);

  @override
  String get type => 'ExtraRollGranted';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.extraRollGranted;
}

final class PawnMoved extends LocalGameEvent {
  const PawnMoved({
    required String playerId,
    required String pawnId,
    required int value,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId, pawnId: pawnId, value: value);

  @override
  String get type => 'PawnMoved';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.pawnMoved;
}

final class PawnCaptured extends LocalGameEvent {
  const PawnCaptured({
    required String playerId,
    required String capturedPawnId,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId, pawnId: capturedPawnId);

  String get capturedPawnId => pawnId!;
  @override
  String get type => 'PawnCaptured';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.pawnCaptured;
}

final class PawnFinished extends LocalGameEvent {
  const PawnFinished({
    required String playerId,
    required String pawnId,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId, pawnId: pawnId);

  @override
  String get type => 'PawnFinished';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.pawnFinished;
}

final class GameCompleted extends LocalGameEvent {
  const GameCompleted({
    required String playerId,
    super.stateVersion,
    super.sequence,
  }) : super(playerId: playerId);

  @override
  String get type => 'GameCompleted';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.gameCompleted;
}

class LocalGameTransition {
  LocalGameTransition(this.state, List<LocalGameEvent> events)
      : events = List<LocalGameEvent>.unmodifiable(
          List<LocalGameEvent>.generate(
            events.length,
            (index) => events[index].forTransition(
              version: state.version,
              order: index,
            ),
            growable: false,
          ),
        );

  final LocalGameState state;
  final List<LocalGameEvent> events;
}

/// Small, deterministic engine service. Board-specific paths must be reviewed
/// against the final board diagram before shipping.
class PathBasedLocalGameEngine {
  PathBasedLocalGameEngine({
    required this.paths,
    this.movement = const LudoPathMovement(),
    LudoRuleProfile? profile,
  }) : profile = profile ?? LudoRuleProfile();

  final LudoBoardPaths paths;
  final LudoPathMovement movement;
  final LudoRuleProfile profile;

  Set<int> get safeCellIndexes => profile.safeCellIndexes;
  bool get sixRequiredToEnter => profile.sixRequiredToEnter;
  bool get extraRollOnSix => profile.extraRollOnSix;
  bool get extraRollOnCapture => profile.extraRollOnCapture;
  bool get extraRollOnFinish => profile.extraRollOnFinish;
  bool get requireExactFinishRoll => profile.requireExactFinishRoll;
  int get maxConsecutiveSixes => profile.maxConsecutiveSixes;
  bool get thirdSixEndsTurnWithoutMove => profile.thirdSixEndsTurnWithoutMove;
  bool get finishEndsMatchImmediately => profile.finishEndsMatchImmediately;
  bool get captureOnlySingleOpponentPawn => profile.captureOnlySingleOpponentPawn;

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
        DiceRolled(playerId: playerId, value: value),
        TurnEnded(playerId: playerId),
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
          rolled.copyWith(clearPendingRoll: true, version: state.version + 1),
          <LocalGameEvent>[
            DiceRolled(playerId: playerId, value: value),
            NoLegalMove(playerId: playerId),
            ExtraRollGranted(playerId: playerId),
          ],
        );
      }
      return LocalGameTransition(
        _advance(rolled.copyWith(
          clearPendingRoll: true,
          consecutiveSixes: 0,
          version: state.version + 1,
        )),
        <LocalGameEvent>[
          DiceRolled(playerId: playerId, value: value),
          NoLegalMove(playerId: playerId),
          TurnEnded(playerId: playerId),
        ],
      );
    }
    return LocalGameTransition(rolled, <LocalGameEvent>[
      DiceRolled(playerId: playerId, value: value),
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
    final capturedPawnIds = <String>[];
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
        final otherProgress = other.position.progress;
        if (otherProgress == null) {
          throw StateError(
            'Invalid game state: main-track pawn ${other.id} has no progress.',
          );
        }
        final otherCell = paths.forPlayer(other.playerId)
            .cellAtProgress(otherProgress);
        if (otherCell == destination) opponentIndexes.add(i);
      }

      // A stacked pair is protected under the default MVP rule. Keep this
      // explicit and configurable because Ludo variants differ on block rules.
      if (!captureOnlySingleOpponentPawn || opponentIndexes.length == 1) {
        for (final opponentIndex in opponentIndexes) {
          pawns[opponentIndex] = pawns[opponentIndex].copyWith(
            position: const PawnRoutePosition(section: PawnRouteSection.yard),
          );
          capturedPawnIds.add(pawns[opponentIndex].id);
        }
      }
    }

    final events = <LocalGameEvent>[
      PawnMoved(playerId: playerId, pawnId: pawnId, value: rollValue),
    ];
    for (final capturedPawnId in capturedPawnIds) {
      events.add(
        PawnCaptured(playerId: playerId, capturedPawnId: capturedPawnId),
      );
    }
    final captured = capturedPawnIds.isNotEmpty;
    if (result.resolution!.finishes) {
      events.add(PawnFinished(playerId: playerId, pawnId: pawnId));
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
        version: next.version,
      );
      events.add(GameCompleted(playerId: playerId));
      return LocalGameTransition(next, events);
    }

    final bonus = (rollValue == 6 && extraRollOnSix) ||
        (captured && extraRollOnCapture) ||
        (result.resolution!.finishes && extraRollOnFinish);
    if (bonus) {
      next = next.copyWith(
        consecutiveSixes: rollValue == 6 ? state.consecutiveSixes : 0,
        version: next.version,
      );
      events.add(ExtraRollGranted(playerId: playerId));
    } else {
      next = _advance(next.copyWith(consecutiveSixes: 0));
      events.add(TurnEnded(playerId: playerId));
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
    if (state.currentPlayerId != playerId) {
      throw const LocalGameException(LocalActionError.wrongPlayer);
    }
    if (maxConsecutiveSixes < 1) {
      throw StateError('maxConsecutiveSixes must be at least 1.');
    }
  }

  LocalGameState _advance(LocalGameState state) {
    // Search each other player at most once. Never silently leave the turn on
    // a player whose pawns are all finished if no eligible player exists.
    for (var offset = 1; offset <= state.players.length; offset++) {
      final candidateIndex =
          (state.currentPlayerIndex + offset) % state.players.length;
      final candidateId = state.players[candidateIndex];
      final candidatePawns =
          state.pawns.where((pawn) => pawn.playerId == candidateId).toList();
      final hasUnfinishedPawn = candidatePawns.any(
        (pawn) => pawn.position.section != PawnRouteSection.finished,
      );
      if (candidatePawns.isNotEmpty && hasUnfinishedPawn) {
        return state.copyWith(
          currentPlayerIndex: candidateIndex,
          clearPendingRoll: true,
          consecutiveSixes: 0,
          version: state.version,
        );
      }
    }

    throw StateError(
      'Cannot advance turn: no player has an unfinished pawn. '
      'The game state should have been completed before turn advancement.',
    );
  }
}
