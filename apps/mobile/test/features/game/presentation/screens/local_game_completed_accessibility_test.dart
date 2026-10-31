import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

Future<void> tapWhenHitTestable(WidgetTester tester, Finder finder) async {
  final target = finder.hitTestable();
  for (var attempt = 0; attempt < 40; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.tap(target);
      await tester.pump();
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(target, findsOneWidget,
      reason: 'The control did not become hit-testable after waiting for route transitions.');
}

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  // Advance in bounded frames: a single long pump can skip intermediate
  // animation frames and leave route/board overlays in an input-blocking state.
  const frame = Duration(milliseconds: 50);
  var remaining = duration;
  while (remaining > Duration.zero) {
    final step = remaining > frame ? frame : remaining;
    await tester.pump(step);
    remaining -= step;
  }
}

void main() {
  testWidgets(
    'completed match announces restart guidance and Rematch resets it',
    (tester) async {
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
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await pumpFor(tester, const Duration(milliseconds: 400));

      expect(find.text('MATCH WON'), findsOneWidget);
      expect(find.byKey(const ValueKey('results_rematch_button')), findsOneWidget);

      final rollButton = tester.widget<InkWell>(
        find.byKey(const ValueKey('roll_dice_button')),
      );
      expect(rollButton.onTap, isNull);

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
        'The match is finished. Choose Rematch to start a new match.',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('results_rematch_button')),
      );
      await tapWhenHitTestable(tester, find.byKey(const ValueKey('results_rematch_button')));
      await pumpFor(tester, const Duration(milliseconds: 500));

      expect(find.text('MATCH WON'), findsNothing);
      expect(find.byKey(const ValueKey('results_rematch_button')), findsNothing);
      final resetRollButton = tester.widget<InkWell>(
        find.byKey(const ValueKey('roll_dice_button')),
      );
      expect(resetRollButton.onTap, isNotNull);
      expect(controller.state.completed, isFalse);
      expect(controller.state.currentPlayerId, 'orange');
    },
  );
}
