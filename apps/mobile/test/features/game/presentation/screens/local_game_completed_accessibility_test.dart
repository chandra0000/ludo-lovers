import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('completed match announces restart guidance and Play Again resets it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final completedState = setup.initialState.copyWith(
      pawns: setup.initialState.pawns
          .map(
            (pawn) => pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.finished,
                progress: setup.paths.forPlayer(pawn.playerId).finishProgress,
              ),
            ),
          )
          .toList(growable: false),
      completed: true,
      winnerPlayerId: 'orange',
      version: 1,
    );
    final controller = LocalGameController(
      gameSetup: setup,
      initialState: completedState,
      nextDiceValue: () => 2,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    expect(find.text('MATCH WON'), findsOneWidget);
    expect(find.byKey(const ValueKey('play_again_button')), findsOneWidget);

    final rollButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('roll_dice_button')),
    );
    expect(rollButton.onPressed, isNull);

    final rollSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('roll_dice_button_semantics')),
    );
    expect(rollSemantics.properties.button, isTrue);
    expect(rollSemantics.properties.enabled, isFalse);
    expect(
      rollSemantics.properties.label,
      'Dice unavailable. Match complete.',
    );
    expect(
      rollSemantics.properties.hint,
      'The match is finished. Choose Play Again to start a new match.',
    );

    await tester.tap(find.byKey(const ValueKey('play_again_button')));
    await tester.pumpAndSettle();

    expect(find.text('MATCH WON'), findsNothing);
    expect(find.byKey(const ValueKey('play_again_button')), findsNothing);
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('roll_dice_button')),
      ).onPressed,
      isNotNull,
    );
    expect(controller.state.completed, isFalse);
    expect(controller.state.currentPlayerId, 'orange');
  });
}
