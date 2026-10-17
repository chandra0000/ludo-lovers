import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets(
    'rolls, highlights a legal pawn, moves it, and preserves prototype warning',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      expect(controller.state.pendingRoll, 6);
      expect(find.text('Rolled 6 · Tap a glowing pawn.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('destination_cell_0_orange_pawn_1')),
        findsOneWidget,
        reason: 'Legal entry should preview its destination on the board.',
      );

      await tester.tap(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      );
      await tester.pumpAndSettle();

      final pawn = controller.state.pawns.firstWhere(
        (item) => item.id == 'orange_pawn_1',
      );
      expect(pawn.position.section, PawnRouteSection.mainTrack);
      expect(pawn.position.progress, 0);
      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.currentPlayerId, 'orange');
      expect(find.textContaining('ExtraRollGranted'), findsOneWidget);
    },
  );

  testWidgets('restart resets the local match state', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restart match'));
    await tester.pumpAndSettle();

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
    );
  });
}
