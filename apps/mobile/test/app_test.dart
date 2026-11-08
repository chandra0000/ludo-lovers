import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/board_preview_screen.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 50);
  var remaining = duration;
  while (remaining > Duration.zero) {
    final step = remaining > frame ? frame : remaining;
    await tester.pump(step);
    remaining -= step;
  }
}

void main() {
  testWidgets('shows the game hub on the first app frame', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());

    expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);
    expect(find.text('VS AI'), findsOneWidget);
    expect(find.byKey(const ValueKey('ludo_lovers_splash_logo')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders compact game hub without a timed splash', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    await pumpFor(tester, const Duration(seconds: 4));

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);
    expect(find.text('VS AI'), findsOneWidget);
    expect(find.text('2P'), findsOneWidget);
    expect(find.text('4P'), findsOneWidget);
    expect(find.text('TEAM UP'), findsOneWidget);
    expect(find.text('Your next favourite'), findsNothing);
    expect(find.byKey(const ValueKey('onboarding_skip_button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('board preview remains available for future review', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BoardPreviewScreen()),
    );
    await tester.pump();

    expect(find.text('Classic Board'), findsOneWidget);
    expect(find.textContaining('Preview only: legal moves'), findsOneWidget);
    expect(find.text('GAMEPLAY LOCKED · ROUTE REVIEW REQUIRED'), findsOneWidget);
    expect(find.byKey(const ValueKey('board_route_gate_summary')), findsOneWidget);
  });

  testWidgets('board preview route audit remains available', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BoardPreviewScreen()),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const ValueKey('board_route_audit_button')));
    await tester.tap(find.byKey(const ValueKey('board_route_audit_button')));
    await pumpFor(tester, const Duration(milliseconds: 300));

    expect(find.text('Route & safe-cell audit'), findsOneWidget);
    expect(find.text('NOT APPROVED FOR RELEASE'), findsOneWidget);
    expect(find.textContaining('4 (5,6) → 5 (6,5)'), findsOneWidget);
    expect(find.text('Provisional safe track IDs'), findsOneWidget);
    expect(find.text('0, 8, 13, 21, 26, 34, 39, 47'), findsOneWidget);
  });

  testWidgets('4P tile opens the local match preview', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: GameModeSelectionScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('mode_four_players_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('live_game_board_artwork')), findsOneWidget);
    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button_semantics')), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
  });

  testWidgets('local match rolls, moves a legal pawn, and updates the board',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: LocalGameScreen(controller: controller),
      ),
    );
    await tester.pump();
    await pumpFor(tester, const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);

    controller.rollDice(expectedVersion: controller.state.version);
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(controller.state.pendingRoll, 6);
    expect(controller.legalPawnIds, contains('orange_pawn_1'));

    controller.movePawn(
      'orange_pawn_1',
      expectedVersion: controller.state.version,
    );
    await pumpFor(tester, const Duration(milliseconds: 100));

    final moved =
        controller.state.pawns.firstWhere((p) => p.id == 'orange_pawn_1');
    expect(moved.position.section, PawnRouteSection.mainTrack);
    expect(controller.state.pendingRoll, isNull);
  });

  testWidgets('restart action restores the initial local board state',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: LocalGameScreen(controller: controller),
      ),
    );
    await tester.pump();
    await pumpFor(tester, const Duration(milliseconds: 100));

    controller.rollDice(expectedVersion: controller.state.version);
    await pumpFor(tester, const Duration(milliseconds: 100));
    controller.movePawn(
      'orange_pawn_1',
      expectedVersion: controller.state.version,
    );
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(
      controller.state.pawns
          .firstWhere((p) => p.id == 'orange_pawn_1')
          .position
          .section,
      PawnRouteSection.mainTrack,
    );

    controller.reset();
    await pumpFor(tester, const Duration(milliseconds: 100));

    expect(
      controller.state.pawns
          .firstWhere((p) => p.id == 'orange_pawn_1')
          .position
          .section,
      PawnRouteSection.yard,
    );
    expect(controller.state.pendingRoll, isNull);
    expect(controller.state.currentPlayerId, 'orange');
  });

  testWidgets('local match advances turn after a legal non-bonus move',
      (tester) async {
    var rollIndex = 0;
    final rolls = <int>[6, 3];
    final controller = LocalGameController(
      nextDiceValue: () => rolls[rollIndex++ % rolls.length],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: LocalGameScreen(controller: controller),
      ),
    );
    await tester.pump();
    await pumpFor(tester, const Duration(milliseconds: 100));

    controller.rollDice(expectedVersion: controller.state.version);
    await pumpFor(tester, const Duration(milliseconds: 100));
    controller.movePawn(
      'orange_pawn_1',
      expectedVersion: controller.state.version,
    );
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(controller.state.currentPlayerId, 'orange');

    controller.rollDice(expectedVersion: controller.state.version);
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(controller.state.pendingRoll, 3);
    controller.movePawn(
      'orange_pawn_1',
      expectedVersion: controller.state.version,
    );
    await pumpFor(tester, const Duration(milliseconds: 100));

    expect(
      controller.state.pawns
          .firstWhere((p) => p.id == 'orange_pawn_1')
          .position
          .progress,
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
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: LocalGameScreen(controller: controller),
      ),
    );
    await tester.pump();
    await pumpFor(tester, const Duration(milliseconds: 100));

    controller.rollDice(expectedVersion: controller.state.version);
    await pumpFor(tester, const Duration(milliseconds: 100));

    expect(controller.state.currentPlayerId, 'green');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.legalPawnIds, isEmpty);
  });

}
