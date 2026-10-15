import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
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
      controller.reset();

      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.version, 0);
      expect(
        controller.state.pawns.every(
          (pawn) => pawn.position.section == PawnRouteSection.yard,
        ),
        isTrue,
      );
      expect(controller.lastError, isNull);
      expect(controller.lastMessage, 'New local game');
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
  });
}
