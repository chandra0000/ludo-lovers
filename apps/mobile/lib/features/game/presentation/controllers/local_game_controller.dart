import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/engine/local_game_factory.dart';
import '../../domain/engine/ludo_path_movement.dart';
import '../../domain/engine/path_based_local_game_engine.dart';

/// Presentation controller for local-only engine experiments.
///
/// Uses an injectable dice source so tests can be deterministic. It is not
/// suitable for competitive online play and labels the route provisional.
class LocalGameController extends ChangeNotifier {
  LocalGameController({
    int Function()? nextDiceValue,
    LocalGameSetup? gameSetup,
    LocalGameState? initialState,
  })  : _nextDiceValue = nextDiceValue ?? _randomDiceValue,
        setup = gameSetup ?? LocalGameFactory.create(allowProvisionalRoutes: true),
        _initialStateOverride = initialState;

  final int Function() _nextDiceValue;
  LocalGameSetup setup;
  final LocalGameState? _initialStateOverride;

  LocalGameState get state => _state;
  late LocalGameState _state = _initialStateOverride ?? setup.initialState;

  String? lastMessage;
  LocalGameException? lastError;

  static int _randomDiceValue() => Random.secure().nextInt(6) + 1;

  List<String> get legalPawnIds => setup.engine.legalPawnIds(_state);

  void rollDice({int? expectedVersion}) {
    if (_rejectStaleInteraction(expectedVersion)) return;
    lastError = null;
    try {
      final transition = setup.engine.roll(
        _state,
        playerId: _state.currentPlayerId,
        expectedVersion: expectedVersion ?? _state.version,
        value: _nextDiceValue(),
      );
      _state = transition.state;
      lastMessage = transition.events.map((event) => event.type).join(' · ');
    } on LocalGameException catch (error) {
      lastError = error;
      lastMessage = error.error.name;
    } finally {
      notifyListeners();
    }
  }

  void movePawn(String pawnId, {int? expectedVersion}) {
    if (_rejectStaleInteraction(expectedVersion)) return;
    lastError = null;
    try {
      final transition = setup.engine.move(
        _state,
        playerId: _state.currentPlayerId,
        expectedVersion: expectedVersion ?? _state.version,
        pawnId: pawnId,
      );
      _state = transition.state;
      lastMessage = transition.events.map((event) => event.type).join(' · ');
    } on LocalGameException catch (error) {
      lastError = error;
      lastMessage = error.error.name;
    } finally {
      notifyListeners();
    }
  }

  /// Rejects callbacks created from an older rendered state before they can
  /// consume a dice value or submit a duplicate move.
  bool _rejectStaleInteraction(int? expectedVersion) {
    if (expectedVersion == null || expectedVersion == _state.version) {
      return false;
    }
    lastError = const LocalGameException(LocalActionError.staleVersion);
    lastMessage = LocalActionError.staleVersion.name;
    notifyListeners();
    return true;
  }

  /// Starts a fresh local match with the selected, distinct player colours.
  ///
  /// Versions remain monotonic so callbacks from the previous match are stale.
  void configurePlayers(List<String> playerIds) {
    final nextSetup = LocalGameFactory.create(
      allowProvisionalRoutes: true,
      selectedPlayerIds: playerIds,
      safeCellIndexes: setup.engine.safeCellIndexes,
    );
    setup = nextSetup;
    _state = nextSetup.initialState.copyWith(version: _state.version + 1);
    lastError = null;
    lastMessage = 'New ' + playerIds.length.toString() + '-player local game';
    notifyListeners();
  }

  void reset() {
    // Keep versions monotonic across rematches. Reusing version 0 would let a
    // delayed callback from the previous match appear current after reset.
    _state = setup.initialState.copyWith(version: _state.version + 1);
    lastError = null;
    lastMessage = 'New local game';
    notifyListeners();
  }

  String pawnLabel(LocalPawn pawn) {
    switch (pawn.position.section) {
      case PawnRouteSection.yard:
        return 'Yard';
      case PawnRouteSection.mainTrack:
        return 'Track ${pawn.position.progress}';
      case PawnRouteSection.homeLane:
        return 'Home ${pawn.position.progress}';
      case PawnRouteSection.finished:
        return 'Finished';
    }
  }
}
