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
    expect(find.text('GAMEPLAY LOCKED · ROUTE REVIEW REQUIRED'), findsOneWidget);
    expect(find.text('0 invalid transitions · 8 provisional safe cells'), findsOneWidget);
    expect(find.byKey(const ValueKey('board_route_gate_summary')), findsOneWidget);
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

  testWidgets('board preview exposes route blockers and provisional safe cells',
      (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    await tester.tap(find.byKey(const ValueKey('preview_board_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board_route_audit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Route & safe-cell audit'), findsOneWidget);
    expect(find.text('NOT APPROVED FOR RELEASE'), findsOneWidget);
    expect(find.textContaining('4 (5,6) → 5 (6,5)'), findsOneWidget);
    expect(find.textContaining('Structural geometry checks pass'), findsOneWidget);
    expect(find.text('Provisional safe track IDs'), findsOneWidget);
    expect(find.text('0, 8, 13, 21, 26, 34, 39, 47'), findsOneWidget);
    expect(find.textContaining('4 (5,6) → 5 (6,5)'), findsOneWidget);
    expect(find.byKey(const ValueKey('safe_cell_coordinate_audit')), findsOneWidget);
    expect(find.textContaining('0 (1,6)'), findsOneWidget);
    expect(
      find.textContaining('cannot prove this custom board’s exact cell mapping'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The four diagonal corner links pass structural checks'),
      findsOneWidget,
    );
  });

  testWidgets('opens the local match preview and clearly labels its limitation',
      (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();

    expect(find.text('Ludo Lovers · Match'), findsOneWidget);
    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    expect(find.text('YOUR TURN'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('React'), findsOneWidget);
    expect(
      find.byTooltip('Roll a die to begin the current player’s turn.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
  });

  testWidgets('local match help explains provisional rules', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: LocalGameController(nextDiceValue: () => 3))),
    );

    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Roll the dice'), findsOneWidget);
    expect(find.text('Choose a glowing pawn'), findsOneWidget);
    expect(find.text('Prototype warning'), findsOneWidget);
    expect(find.textContaining('still provisional'), findsOneWidget);
  });

  testWidgets('local match rolls, moves a legal pawn, and updates the board',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );

    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('turn_status_semantics'))).label,
      'ORANGE player turn.',
    );
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('GREEN'), findsOneWidget);
    expect(find.text('BLUE'), findsOneWidget);
    expect(find.text('MAGENTA'), findsOneWidget);
    expect(find.text('BOT'), findsNothing);
    expect(find.text('OUT 0/4'), findsNWidgets(4));
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();

    expect(controller.state.pendingRoll, 6);
    expect(find.text('Rolled 6 · Tap a glowing pawn.'), findsOneWidget);
    expect(find.byKey(const ValueKey('last_game_action_semantics')), findsOneWidget);
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
    expect(find.text('OUT 1/4'), findsOneWidget);
    expect(find.text('OUT 0/4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('restart action restores the initial local board state',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
    );
    await tester.pump();

    final versionBeforeRestart = controller.state.version;
    await tester.tap(find.byTooltip('Restart match'));
    await tester.pump();

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.version, versionBeforeRestart + 1);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
    );
    expect(find.text('Roll the dice to start your turn.'), findsOneWidget);
  });

  testWidgets('local match advances turn after a legal non-bonus move',
      (tester) async {
    final rolls = <int>[6, 3];
    final controller = LocalGameController(nextDiceValue: () => rolls.removeAt(0));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );

    // Six enters a pawn and grants the same player another roll.
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();
    expect(controller.legalPawnIds, contains('orange_pawn_1'));
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pump();
    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pawns
        .firstWhere((pawn) => pawn.id == 'orange_pawn_1')
        .position.progress, 0);

    // A non-six move advances the pawn and passes the turn to green.
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();
    expect(controller.state.pendingRoll, 3);
    expect(controller.legalPawnIds, contains('orange_pawn_1'));
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pump();

    expect(
      controller.state.pawns
          .firstWhere((pawn) => pawn.id == 'orange_pawn_1')
          .position.progress,
      3,
    );
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.currentPlayerId, 'green');
    expect(find.text('GREEN’S TURN'), findsOneWidget);
  });

  testWidgets('local match auto-advances when a roll has no legal pawns',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 3);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();

    expect(controller.state.currentPlayerId, 'green');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.legalPawnIds, isEmpty);
    expect(find.text('GREEN’S TURN'), findsOneWidget);
  });

}
