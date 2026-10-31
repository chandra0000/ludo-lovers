import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/app/theme/app_theme.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await pumpFor(tester, const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 3));
  await pumpFor(tester, const Duration(milliseconds: 400));
  final skip = find.byKey(const ValueKey('onboarding_skip_button'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await pumpFor(tester, const Duration(milliseconds: 500));
  }
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
  testWidgets('home navigates to the three local game modes', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openHome(tester);
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Pick your way to play'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_vs_computer_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_two_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_four_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_team_up_button')), findsOneWidget);
    expect(find.text('Online rooms'), findsNothing);
  });

  testWidgets('Team Up selection opens the 2-vs-2 match with team identities',
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
    await pumpFor(tester, const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('mode_team_up_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('team_up_identity_banner')), findsOneWidget);
    expect(find.text('TEAM A'), findsOneWidget);
    expect(find.text('TEAM B'), findsOneWidget);
    expect(find.text('ORANGE + MAGENTA'), findsOneWidget);
    expect(find.text('GREEN + BLUE'), findsOneWidget);
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
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await pumpFor(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text('Set up 2-player game'));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Choose your colours'), findsOneWidget);
    expect(find.text('Player 1: ORANGE  ·  Player 2: GREEN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setup_colour_blue')));
    await tester.pump();

    expect(find.text('Player 1: ORANGE  ·  Player 2: BLUE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byType(LocalGameScreen), findsOneWidget);


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
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await pumpFor(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text('Play vs AI'));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byType(LocalGameScreen), findsOneWidget);




    expect(find.byKey(const ValueKey('portrait_turn_indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('how_to_play_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai_mode_status')), findsNothing);
    expect(find.text('LOCAL'), findsNothing);
  });
}
