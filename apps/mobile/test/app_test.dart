import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('renders the Ludo Lovers foundation screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.text('PLAY • CONNECT • LOVE'), findsOneWidget);
    expect(find.text('Your next favourite\ngame night starts here.'), findsOneWidget);
    expect(find.text('Love Mode'), findsOneWidget);
    expect(find.text('Explore the Board'), findsOneWidget);
    expect(find.text('Play Local Match (Prototype)'), findsOneWidget);
  });

  testWidgets('opens the board preview', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    await tester.tap(find.byKey(const ValueKey('preview_board_button')));
    await tester.pumpAndSettle();

    expect(find.text('Classic Board'), findsOneWidget);
    expect(find.textContaining('Preview only: legal moves'), findsOneWidget);
    expect(find.textContaining('Tap a sample pawn'), findsOneWidget);

    final board = tester.getRect(find.byKey(const ValueKey('interactive_board')));
    // The keyed square includes an 8 px decorative inset around the board.
    const inset = 8.0;
    final boardWidth = board.width - inset * 2;
    final boardHeight = board.height - inset * 2;
    await tester.tapAt(Offset(
      board.left + inset + boardWidth * (1.5 / 15),
      board.top + inset + boardHeight * (6.5 / 15),
    ));
    await tester.pump();
    expect(find.text('Sample pawn selected on cell 0.'), findsOneWidget);
    expect(find.byKey(const ValueKey('clear_pawn_selection_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clear_pawn_selection_button')));
    await tester.pump();
    expect(find.textContaining('Tap a sample pawn'), findsOneWidget);
    expect(find.byKey(const ValueKey('clear_pawn_selection_button')), findsNothing);
  });

  testWidgets('opens the local match preview and clearly labels its limitation',
      (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();

    expect(find.text('Local Match Preview'), findsOneWidget);
    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    expect(find.text('Roll Dice'), findsOneWidget);
    expect(find.textContaining('PROTOTYPE ONLY'), findsOneWidget);
    expect(find.textContaining('board route and safe cells are provisional'), findsOneWidget);
  });

  testWidgets('local match rolls, moves a legal pawn, and updates the board',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );

    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();

    expect(controller.state.pendingRoll, 6);
    expect(find.text('Rolled 6 · Tap a glowing pawn.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
    );
    await tester.pump();

    final movedPawn = controller.state.pawns
        .firstWhere((pawn) => pawn.id == 'orange_pawn_1');
    expect(movedPawn.position.section, PawnRouteSection.mainTrack);
    expect(movedPawn.position.progress, 0);
    expect(controller.state.pendingRoll, isNull);
    // A six grants another turn under the current local rule profile.
    expect(controller.state.currentPlayerId, 'orange');
    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      findsNothing,
    );
  });

  testWidgets('restart action restores the initial local board state',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Restart match'));
    await tester.pump();

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.version, 0);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
    );
    expect(find.text('Roll the dice to start your turn.'), findsOneWidget);
  });
}
