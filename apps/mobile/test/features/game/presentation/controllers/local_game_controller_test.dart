import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';

void main() {
  group('LocalGameController', () {
    test('rolls a deterministic six and exposes legal pawns', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.version, 0);
      expect(controller.legalPawnIds, isEmpty);

      controller.rollDice();

      expect(controller.state.pendingRoll, 6);
      expect(controller.state.version, greaterThan(0));
      expect(controller.legalPawnIds, hasLength(4));
      expect(controller.lastError, isNull);
    });

    test('moves a selected legal pawn and grants the six bonus turn', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      controller.rollDice();
      controller.movePawn('orange_pawn_1');

      final pawn = controller.state.pawns
          .firstWhere((item) => item.id == 'orange_pawn_1');
      expect(pawn.position.section, PawnRouteSection.mainTrack);
      expect(pawn.position.progress, 0);
      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.pendingRoll, isNull);
      expect(controller.lastError, isNull);
      expect(controller.lastMessage, contains('ExtraRollGranted'));
    });

    test('reset restores a clean initial game', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      controller.rollDice();
      controller.movePawn('orange_pawn_1');
      final versionBeforeReset = controller.state.version;
      controller.reset();

      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.version, versionBeforeReset + 1);
      expect(
        controller.state.pawns.every(
          (pawn) => pawn.position.section == PawnRouteSection.yard,
        ),
        isTrue,
      );
      expect(controller.lastError, isNull);
      expect(controller.lastMessage, 'New local game');
    });

    test('reset restores the configured initial state override', () {
      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final configuredInitialState = setup.initialState.copyWith(
        currentPlayerIndex: 1,
        version: 4,
      );
      final controller = LocalGameController(
        gameSetup: setup,
        initialState: configuredInitialState,
        nextDiceValue: () => 6,
      );
      addTearDown(controller.dispose);

      controller.rollDice();
      final versionBeforeReset = controller.state.version;
      controller.reset();

      expect(controller.state.currentPlayerId, 'green');
      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.version, versionBeforeReset + 1);
      expect(
        controller.state.pawns.every(
          (pawn) => pawn.position.section == PawnRouteSection.yard,
        ),
        isTrue,
      );
    });

    test('rejects callbacks from the previous match after reset', () {
      var diceCalls = 0;
      final controller = LocalGameController(
        nextDiceValue: () {
          diceCalls++;
          return 6;
        },
      );
      addTearDown(controller.dispose);

      final oldRenderedVersion = controller.state.version;
      controller.rollDice();
      controller.movePawn('orange_pawn_1');
      controller.reset();
      final resetState = controller.state;

      expect(resetState.version, greaterThan(oldRenderedVersion));
      expect(
        resetState.pawns.every(
          (pawn) => pawn.position.section == PawnRouteSection.yard,
        ),
        isTrue,
      );

      controller.rollDice(expectedVersion: oldRenderedVersion);

      expect(identical(controller.state, resetState), isTrue);
      expect(controller.state.pendingRoll, isNull);
      expect(diceCalls, 1);
      expect(controller.lastError?.error, LocalActionError.staleVersion);
    });

    test('records a no-legal-move turn without crashing the screen', () {
      final controller = LocalGameController(nextDiceValue: () => 3);
      addTearDown(controller.dispose);

      controller.rollDice();

      expect(controller.state.currentPlayerId, 'green');
      expect(controller.lastMessage, contains('NoLegalMove'));
      expect(controller.lastError, isNull);
    });

    test('notifies listeners after a successful state transition', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.rollDice();

      expect(notifications, 1);
      expect(controller.state.pendingRoll, 6);
    });

    test('rejects an invalid dice source value without changing the game', () {
      final controller = LocalGameController(nextDiceValue: () => 7);
      addTearDown(controller.dispose);
      final before = controller.state;

      controller.rollDice();

      expect(controller.state.version, before.version);
      expect(controller.state.pendingRoll, isNull);
      expect(controller.lastError, isNotNull);
      expect(controller.lastMessage, contains('invalidRoll'));
    });

    test('keeps the pending roll when an illegal pawn is selected', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      controller.rollDice();
      final versionAfterRoll = controller.state.version;
      controller.movePawn('not_a_real_pawn');

      expect(controller.state.pendingRoll, 6);
      expect(controller.state.version, versionAfterRoll);
      expect(controller.lastError, isNotNull);
      expect(controller.lastMessage, isNotNull);
    });

    test('rejects stale rendered callbacks before consuming a dice value', () {
      var diceCalls = 0;
      final controller = LocalGameController(
        nextDiceValue: () {
          diceCalls++;
          return 6;
        },
      );
      addTearDown(controller.dispose);

      controller.rollDice();
      final afterRoll = controller.state;
      expect(diceCalls, 1);
      expect(afterRoll.pendingRoll, 6);

      controller.rollDice(expectedVersion: 0);

      expect(identical(controller.state, afterRoll), isTrue);
      expect(controller.state.version, afterRoll.version);
      expect(controller.state.pendingRoll, 6);
      expect(
        diceCalls,
        1,
        reason: 'A stale roll callback must not consume the dice source.',
      );
      expect(controller.lastError?.error, LocalActionError.staleVersion);
    });

    test('rejects a stale pawn callback without consuming the pending roll', () {
      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      controller.rollDice();
      final afterRoll = controller.state;
      controller.movePawn('orange_pawn_1', expectedVersion: 0);

      expect(identical(controller.state, afterRoll), isTrue);
      expect(controller.state.version, afterRoll.version);
      expect(controller.state.pendingRoll, 6);
      expect(
        controller.state.pawns
            .firstWhere((pawn) => pawn.id == 'orange_pawn_1')
            .position.section,
        PawnRouteSection.yard,
      );
      expect(controller.lastError?.error, LocalActionError.staleVersion);
    });
  });
}
