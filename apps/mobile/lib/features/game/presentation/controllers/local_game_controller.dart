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
  LocalGameController({int Function()? nextDiceValue})
      : _nextDiceValue = nextDiceValue ?? _randomDiceValue,
        setup = LocalGameFactory.create(allowProvisionalRoutes: true);

  final int Function() _nextDiceValue;
  final LocalGameSetup setup;

  LocalGameState get state => _state;
  late LocalGameState _state = setup.initialState;

  String? lastMessage;
  LocalGameException? lastError;

  static int _randomDiceValue() => Random.secure().nextInt(6) + 1;

  List<String> get legalPawnIds => setup.engine.legalPawnIds(_state);

  void rollDice() {
    lastError = null;
    try {
      final transition = setup.engine.roll(
        _state,
        playerId: _state.currentPlayerId,
        expectedVersion: _state.version,
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

  void movePawn(String pawnId) {
    lastError = null;
    try {
      final transition = setup.engine.move(
        _state,
        playerId: _state.currentPlayerId,
        expectedVersion: _state.version,
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

  void reset() {
    _state = setup.initialState;
    lastError = null;
    lastMessage = 'New local game';
    notifyListeners();
  }

  String pawnLabel(LocalPawn pawn) {
    switch (pawn.position.section) {
      case PawnRouteSection.yard:
        return 'Yard';
      case PawnRouteSection.mainTrack:
        return 'Track ' + pawn.position.progress.toString();
      case PawnRouteSection.homeLane:
        return 'Home ' + pawn.position.progress.toString();
      case PawnRouteSection.finished:
        return 'Finished';
    }
  }
}
