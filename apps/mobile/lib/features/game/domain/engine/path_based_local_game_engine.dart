/// Path-based local gameplay transition service for Ludo Lovers.
///
/// This engine is the canonical local transition service. Board-specific paths
/// and provisional rules must be reviewed before production gameplay.
library;

import '../board/ludo_board_paths.dart';
import 'ludo_path_movement.dart';
import 'ludo_rule_profile.dart';
import 'team_up_rules.dart';

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
    int? scheduledPlayerIndex,
    this.pendingRoll,
    this.consecutiveSixes = 0,
    this.completed = false,
    this.winnerPlayerId,
    this.winnerTeamId,
    Map<int, TeamUpTeam> teamUpCapturePriorityByCell = const <int, TeamUpTeam>{},
    this.version = 0,
  }) : teamUpCapturePriorityByCell = Map<int, TeamUpTeam>.unmodifiable(teamUpCapturePriorityByCell),
       pawns = List<LocalPawn>.unmodifiable(pawns),
       players = List<String>.unmodifiable(players),
       scheduledPlayerIndex = scheduledPlayerIndex ?? currentPlayerIndex {
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
    if (this.scheduledPlayerIndex < 0 || this.scheduledPlayerIndex >= this.players.length) {
      throw ArgumentError.value(this.scheduledPlayerIndex, 'scheduledPlayerIndex');
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
  /// Seat whose turn is scheduled, distinct from a teammate receiving a transferred roll.
  final int scheduledPlayerIndex;
  final int? pendingRoll;
  final int consecutiveSixes;
  final bool completed;
  final String? winnerPlayerId;
  final String? winnerTeamId;
  /// Last-arriving team for each unsafe mixed-team shared-track cell.
  /// This is authoritative domain state, not reconstructed from animation.
  final Map<int, TeamUpTeam> teamUpCapturePriorityByCell;
  final int version;

  String get currentPlayerId => players[currentPlayerIndex];
  String get scheduledPlayerId => players[scheduledPlayerIndex];

  LocalGameState copyWith({
    List<LocalPawn>? pawns,
    int? currentPlayerIndex,
    int? scheduledPlayerIndex,
    int? pendingRoll,
    bool clearPendingRoll = false,
    int? consecutiveSixes,
    bool? completed,
    String? winnerPlayerId,
    String? winnerTeamId,
    Map<int, TeamUpTeam>? teamUpCapturePriorityByCell,
    int? version,
  }) => LocalGameState(
        players: players,
        pawns: pawns ?? this.pawns,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        scheduledPlayerIndex: scheduledPlayerIndex ?? this.scheduledPlayerIndex,
        pendingRoll: clearPendingRoll ? null : (pendingRoll ?? this.pendingRoll),
        consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
        completed: completed ?? this.completed,
        winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
        winnerTeamId: winnerTeamId ?? this.winnerTeamId,
        teamUpCapturePriorityByCell:
            teamUpCapturePriorityByCell ?? this.teamUpCapturePriorityByCell,
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
  invalidState,
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
    required super.playerId,
    required super.value,
    super.stateVersion,
    super.sequence,
  });

  int get rollValue => value!;
  @override
  String get type => 'DiceRolled';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.diceRolled;
}

final class TurnEnded extends LocalGameEvent {
  const TurnEnded({
    required super.playerId,
    super.stateVersion,
    super.sequence,
  });

  @override
  String get type => 'TurnEnded';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.turnEnded;
}

final class NoLegalMove extends LocalGameEvent {
  const NoLegalMove({
    required super.playerId,
    super.stateVersion,
    super.sequence,
  });

  @override
  String get type => 'NoLegalMove';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.noLegalMove;
}

final class ExtraRollGranted extends LocalGameEvent {
  const ExtraRollGranted({
    required super.playerId,
    super.stateVersion,
    super.sequence,
  });

  @override
  String get type => 'ExtraRollGranted';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.extraRollGranted;
}

final class PawnMoved extends LocalGameEvent {
  const PawnMoved({
    required super.playerId,
    required super.pawnId,
    required super.value,
    super.stateVersion,
    super.sequence,
  });

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
  }) : super(
          playerId: playerId,
          pawnId: capturedPawnId,
        );

  String get capturedPawnId => pawnId!;
  @override
  String get type => 'PawnCaptured';
  @override
  LocalGameEventKind get kind => LocalGameEventKind.pawnCaptured;
}

final class PawnFinished extends LocalGameEvent {
  const PawnFinished({
    required super.playerId,
    required super.pawnId,
    super.stateVersion,
    super.sequence,
  });

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
  bool get isTeamUp => profile.isTeamUp;

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
    final capturedPawnIds = <String>[];
    final capturePriorityByCell =
        Map<int, TeamUpTeam>.of(state.teamUpCapturePriorityByCell);
    final originCell = pawn.position.section == PawnRouteSection.mainTrack
        ? paths.forPlayer(playerId).cellAtProgress(pawn.position.progress!)
        : null;
    pawns[index] = pawn.copyWith(position: result.resolution!.position);

    if (isTeamUp && originCell != null) {
      _resolveTeamUpStackDeparture(
        pawns: pawns,
        movingPlayerId: playerId,
        cellId: originCell,
        priorityByCell: capturePriorityByCell,
        capturedPawnIds: capturedPawnIds,
      );
    }

    final destination = result.resolution!.destinationCell;
    if (destination != null && !safeCellIndexes.contains(destination)) {
      if (isTeamUp) {
        _resolveTeamUpStackArrival(
          pawns: pawns,
          arrivingPlayerId: playerId,
          cellId: destination,
          priorityByCell: capturePriorityByCell,
          capturedPawnIds: capturedPawnIds,
        );
      } else {
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
          final otherCell =
              paths.forPlayer(other.playerId).cellAtProgress(otherProgress);
          if (otherCell == destination) opponentIndexes.add(i);
        }

        if (!captureOnlySingleOpponentPawn || opponentIndexes.length == 1) {
          for (final opponentIndex in opponentIndexes) {
            pawns[opponentIndex] = pawns[opponentIndex].copyWith(
              position: const PawnRoutePosition(
                section: PawnRouteSection.yard,
              ),
            );
            capturedPawnIds.add(pawns[opponentIndex].id);
          }
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

    final finishedPlayers = <String>{
      for (final id in state.players)
        if (pawns.where((item) => item.playerId == id).every(
          (item) => item.position.section == PawnRouteSection.finished,
        )) id,
    };
    final allFinished = finishedPlayers.contains(playerId);
    final teamWon = isTeamUp && TeamUpRules.hasTeamWon(
      team: TeamUpRules.teamFor(playerId),
      playersWithAllPawnsFinished: finishedPlayers,
    );
    var next = state.copyWith(
      pawns: pawns,
      teamUpCapturePriorityByCell: capturePriorityByCell,
      clearPendingRoll: true,
      version: state.version + 1,
    );
    if ((isTeamUp ? teamWon : allFinished) && finishEndsMatchImmediately) {
      next = next.copyWith(
        completed: true,
        winnerPlayerId: playerId,
        winnerTeamId: isTeamUp ? TeamUpRules.teamFor(playerId).name : null,
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
        currentPlayerIndex: isTeamUp && allFinished && !teamWon
            ? state.players.indexOf(TeamUpRules.teammateFor(playerId))
            : next.currentPlayerIndex,
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
    _validatePawnPositions(state);
    if (maxConsecutiveSixes < 1) {
      throw StateError('maxConsecutiveSixes must be at least 1.');
    }
  }

  /// Reject malformed route positions before they can corrupt capture or
  /// rendering logic. The renderer and engine share the same player paths.
  void _validatePawnPositions(LocalGameState state) {
    if (isTeamUp) {
      if (state.players.join(',') != TeamUpRules.turnOrder.join(',')) {
        throw const LocalGameException(LocalActionError.invalidState);
      }
      for (final playerId in TeamUpRules.turnOrder) {
        if (state.pawns.where((pawn) => pawn.playerId == playerId).length != 4) {
          throw const LocalGameException(LocalActionError.invalidState);
        }
      }
    }
    for (final pawn in state.pawns) {
      final path = paths.forPlayer(pawn.playerId);
      final progress = pawn.position.progress;
      final valid = switch (pawn.position.section) {
        PawnRouteSection.yard => progress == null,
        PawnRouteSection.mainTrack =>
          progress != null && progress >= 0 && progress < path.trackLength,
        PawnRouteSection.homeLane =>
          progress != null &&
              progress >= path.trackLength &&
              progress < path.finishProgress,
        PawnRouteSection.finished => progress == path.finishProgress,
      };
      if (!valid) {
        throw const LocalGameException(LocalActionError.invalidState);
      }
    }
  }

  void _resolveTeamUpStackDeparture({
    required List<LocalPawn> pawns,
    required String movingPlayerId,
    required int cellId,
    required Map<int, TeamUpTeam> priorityByCell,
    required List<String> capturedPawnIds,
  }) {
    if (safeCellIndexes.contains(cellId)) return;
    final priorityTeam = priorityByCell[cellId];
    if (priorityTeam == null) return;

    final protectedTeam =
        priorityTeam == TeamUpTeam.a ? TeamUpTeam.b : TeamUpTeam.a;
    final priorityIndexes = <int>[];
    final protectedIndexes = <int>[];
    for (var i = 0; i < pawns.length; i++) {
      final occupant = pawns[i];
      if (occupant.position.section != PawnRouteSection.mainTrack) continue;
      final progress = occupant.position.progress!;
      if (paths.forPlayer(occupant.playerId).cellAtProgress(progress) !=
          cellId) {
        continue;
      }
      if (TeamUpRules.teamFor(occupant.playerId) == priorityTeam) {
        priorityIndexes.add(i);
      } else if (TeamUpRules.teamFor(occupant.playerId) == protectedTeam) {
        protectedIndexes.add(i);
      }
    }

    if (priorityIndexes.isEmpty || protectedIndexes.isEmpty) {
      // The last-arriving side left first, or no opposing stack remains.
      priorityByCell.remove(cellId);
      return;
    }

    if (TeamUpRules.teamFor(movingPlayerId) != priorityTeam) {
      // A protected pawn tried to leave while the priority stack remained.
      // The moving pawn has already left; its remaining friendly stack is
      // returned to the yard immediately.
      for (final protectedIndex in protectedIndexes) {
        final capturedPawn = pawns[protectedIndex];
        pawns[protectedIndex] = capturedPawn.copyWith(
          position: const PawnRoutePosition(
            section: PawnRouteSection.yard,
          ),
        );
        capturedPawnIds.add(capturedPawn.id);
      }
      priorityByCell.remove(cellId);
    }
  }

  void _resolveTeamUpStackArrival({
    required List<LocalPawn> pawns,
    required String arrivingPlayerId,
    required int cellId,
    required Map<int, TeamUpTeam> priorityByCell,
    required List<String> capturedPawnIds,
  }) {
    final arrivingTeam = TeamUpRules.teamFor(arrivingPlayerId);
    final teamAIndexes = <int>[];
    final teamBIndexes = <int>[];
    for (var i = 0; i < pawns.length; i++) {
      final occupant = pawns[i];
      if (occupant.position.section != PawnRouteSection.mainTrack) continue;
      final progress = occupant.position.progress!;
      if (paths.forPlayer(occupant.playerId).cellAtProgress(progress) !=
          cellId) {
        continue;
      }
      if (TeamUpRules.teamFor(occupant.playerId) == TeamUpTeam.a) {
        teamAIndexes.add(i);
      } else {
        teamBIndexes.add(i);
      }
    }

    if (teamAIndexes.isEmpty || teamBIndexes.isEmpty) {
      priorityByCell.remove(cellId);
      return;
    }

    // The most recent arrival owns priority for this mixed opposing stack.
    priorityByCell[cellId] = arrivingTeam;
    final arrivingIndexes =
        arrivingTeam == TeamUpTeam.a ? teamAIndexes : teamBIndexes;
    final opposingIndexes =
        arrivingTeam == TeamUpTeam.a ? teamBIndexes : teamAIndexes;

    if (arrivingIndexes.length == opposingIndexes.length) {
      // Equal-sized opposing stacks are resolved immediately in favour of
      // the last-arriving side.
      for (final opposingIndex in opposingIndexes) {
        final capturedPawn = pawns[opposingIndex];
        pawns[opposingIndex] = capturedPawn.copyWith(
          position: const PawnRoutePosition(
            section: PawnRouteSection.yard,
          ),
        );
        capturedPawnIds.add(capturedPawn.id);
      }
      priorityByCell.remove(cellId);
    }
  }

  LocalGameState _advance(LocalGameState state) {
    // Classic mode advances directly from the active seat. Team Up keeps the
    // scheduled seat separate because a finished seat can transfer its roll.
    final basePlayerIndex = isTeamUp
        ? state.scheduledPlayerIndex
        : state.currentPlayerIndex;
    for (var offset = 1; offset <= state.players.length; offset++) {
      final candidateIndex = (basePlayerIndex + offset) % state.players.length;
      final candidateId = state.players[candidateIndex];
      final candidatePawns = state.pawns.where((pawn) => pawn.playerId == candidateId);
      final hasUnfinishedPawn = candidatePawns.any(
        (pawn) => pawn.position.section != PawnRouteSection.finished,
      );
      if (isTeamUp) {
        final finishedPlayers = <String>{
          for (final id in state.players)
            if (state.pawns.where((pawn) => pawn.playerId == id).every(
              (pawn) => pawn.position.section == PawnRouteSection.finished,
            )) id,
        };
        final recipient = TeamUpRules.recipientForScheduledRoll(
          scheduledPlayerId: candidateId,
          playersWithAllPawnsFinished: finishedPlayers,
        );
        if (recipient != null) {
          return state.copyWith(
            currentPlayerIndex: state.players.indexOf(recipient),
            scheduledPlayerIndex: candidateIndex,
            clearPendingRoll: true,
            consecutiveSixes: 0,
            version: state.version,
          );
        }
      } else if (candidatePawns.isNotEmpty && hasUnfinishedPawn) {
        return state.copyWith(
          currentPlayerIndex: candidateIndex,
          scheduledPlayerIndex: candidateIndex,
          clearPendingRoll: true,
          consecutiveSixes: 0,
          version: state.version,
        );
      }
    }
    throw StateError(
      'Cannot advance turn: no eligible player remains. The match should have completed first.',
    );
  }
}
