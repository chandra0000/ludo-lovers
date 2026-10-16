import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('plays a local turn by rolling and tapping a legal board pawn',
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

    expect(find.text('PROTOTYPE ONLY · The board route and safe cells are provisional. Test local turns here; do not treat this as release-ready gameplay.'), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();

    expect(controller.state.pendingRoll, 6);
    expect(find.text('Rolled 6 · Tap a glowing pawn.'), findsOneWidget);
    expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();

    final movedPawn = controller.state.pawns.firstWhere(
      (pawn) => pawn.id == 'orange_pawn_1',
    );
    expect(movedPawn.position.section, PawnRouteSection.mainTrack);
    expect(movedPawn.position.progress, 0);
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.currentPlayerId, 'orange');
    expect(find.textContaining('ExtraRollGranted'), findsOneWidget);
  });
}
