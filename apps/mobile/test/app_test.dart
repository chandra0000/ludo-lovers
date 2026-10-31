import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  // Advance the requested frame duration so route and UI transitions settle.
  await tester.pump(duration);
}

void main() {
  testWidgets('renders the Ludo Lovers foundation screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('LUDO LOVERS'), findsAtLeastNWidgets(1));
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('ludo_lovers_home_logo')),
    );
    expect(logo.image, isA<AssetImage>());
    expect((logo.image as AssetImage).assetName,
        'assets/images/ludo_lovers_logo.jpg');
    expect(find.text('PLAY • CONNECT • LOVE'), findsAtLeastNWidgets(1));
    expect(find.text('Your next favourite\ngame night starts here.'), findsOneWidget);
    expect(find.text('Love Mode'), findsOneWidget);
    expect(find.text('Explore the Board'), findsOneWidget);
    expect(find.text('Play Now · Choose a Mode'), findsOneWidget);
  });

  testWidgets('opens the board preview', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.ensureVisible(find.byKey(const ValueKey('preview_board_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('preview_board_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Classic Board'), findsOneWidget);
    expect(find.textContaining('Preview only: legal moves'), findsOneWidget);
    expect(find.text('GAMEPLAY LOCKED · ROUTE REVIEW REQUIRED'), findsOneWidget);
    expect(find.text('4 invalid transitions · 8 owner-confirmed safe cells'), findsOneWidget);
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

  testWidgets('board preview exposes route blockers and owner-confirmed safe cells',
      (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.ensureVisible(find.byKey(const ValueKey('preview_board_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('preview_board_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(const ValueKey('board_route_audit_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('board_route_audit_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Route & safe-cell audit'), findsOneWidget);
    expect(find.text('NOT APPROVED FOR RELEASE'), findsOneWidget);
    expect(find.textContaining('4 (5,6) → 5 (6,5)'), findsOneWidget);
    expect(find.textContaining('Structural geometry checks found blockers'), findsOneWidget);
    expect(find.text('Owner-confirmed safe track IDs'), findsOneWidget);
    expect(find.text('0, 8, 13, 21, 26, 34, 39, 47'), findsOneWidget);
    expect(find.textContaining('4 (5,6) → 5 (6,5)'), findsOneWidget);
    expect(find.byKey(const ValueKey('safe_cell_coordinate_audit')), findsOneWidget);
    expect(find.textContaining('0 (1,6)'), findsOneWidget);
    expect(
      find.textContaining('The owner-confirmed safe-cell map contains eight cells'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The physical loop has 52 cells'),
      findsOneWidget,
    );
  });

  testWidgets('opens the local match preview and clearly labels its limitation',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Pick your way to play'), findsOneWidget);
    await tester.ensureVisible(find.text('Start 4-player game'));
    await tester.tap(find.text('Start 4-player game'));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('live_game_board_artwork')), findsOneWidget);
    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('roll_dice_button_semantics')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
  });

  testWidgets('local match rolls, moves a legal pawn, and updates the board',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));




    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();

    expect(controller.state.pendingRoll, 6);
    expect(
      controller.state.pendingRoll,
      6,
      reason: 'The controller must retain the rolled value while a legal pawn is awaiting selection.',
    );

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
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
    );
    await tester.pump();

    final versionBeforeRestart = controller.state.version;
    controller.reset();
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.version, versionBeforeRestart + 1);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
    );

  });

  testWidgets('local match advances turn after a legal non-bonus move',
      (tester) async {
    final rolls = <int>[6, 3];
    final controller = LocalGameController(nextDiceValue: () => rolls.removeAt(0));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));

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

  });

  testWidgets('local match auto-advances when a roll has no legal pawns',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 3);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LocalGameScreen(controller: controller)),
    );
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const ValueKey('roll_dice_button')));
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pump();

    expect(controller.state.currentPlayerId, 'green');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.legalPawnIds, isEmpty);

  });

}
