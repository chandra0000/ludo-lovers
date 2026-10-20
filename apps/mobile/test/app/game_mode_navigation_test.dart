import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/app/theme/app_theme.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('home navigates to the three local game modes', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pick your way to play'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_vs_computer_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_two_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_four_players_button')), findsOneWidget);
    expect(find.text('Online rooms'), findsNothing);
  });

  testWidgets('two-player setup lets players choose two distinct colours',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const GameModeSelectionScreen(),
      ),
    );
    await tester.tap(find.text('Set up 2-player game'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your colours'), findsOneWidget);
    expect(find.text('Player 1: ORANGE  ·  Player 2: GREEN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup_colour_blue')));
    await tester.pump();

    expect(find.text('Player 1: ORANGE  ·  Player 2: BLUE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
    expect(find.text('BLUE'), findsAtLeastNWidgets(1));
    expect(find.text('GREEN'), findsNothing);
  });

  testWidgets('computer mode starts with one human and three AI seats',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const GameModeSelectionScreen(),
      ),
    );
    await tester.tap(find.text('Play vs AI'));
    await tester.pump();

    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('AI'), findsNWidgets(3));
    expect(find.text('LOCAL'), findsNothing);
  });
}
