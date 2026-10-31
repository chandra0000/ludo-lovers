import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('AI turn announces waiting state and hides manual pawn controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final greenTurnWithPendingRoll = setup.initialState.copyWith(
      currentPlayerIndex: 1,
      pendingRoll: 6,
      version: 1,
    );
    final controller = LocalGameController(
      gameSetup: setup,
      initialState: greenTurnWithPendingRoll,
      nextDiceValue: () => 2,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller, playAgainstAi: true),
      ),
    );

    expect(find.byKey(const ValueKey('ai_mode_status')), findsOneWidget);
    expect(find.text('AI OPPONENTS ON · YOU PLAY ORANGE'), findsOneWidget);

    final rollButton = tester.widget<InkWell>(
      find.byKey(const ValueKey('roll_dice_button')),
    );
    expect(
      rollButton.onTap,
      isNull,
      reason: 'The human must not roll during an AI opponent turn.',
    );

    final rollSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('roll_dice_button_semantics')),
    );
    expect(rollSemantics.properties.button, isTrue);
    expect(rollSemantics.properties.enabled, isFalse);
    expect(
      rollSemantics.properties.label,
      'Dice unavailable. AI opponent turn.',
    );
    expect(
      rollSemantics.properties.hint,
      'The AI is choosing its move. Please wait.',
    );

    expect(
      find.byKey(const ValueKey('legal_pawn_green_pawn_1')),
      findsNothing,
      reason: 'AI turns must not expose manual pawn tap targets.',
    );

    // Stop the scheduled AI timer by unmounting before its delayed action.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
