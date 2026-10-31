import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const LudoLoversApp());
    // Allow the initial Material route transition to complete without
    // pumpAndSettle (the live match may schedule AI work continuously).
    await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 400));
  final skip = find.byKey(const ValueKey('onboarding_skip_button'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await pumpFor(tester, const Duration(milliseconds: 500));
  }
}

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    final remaining = duration - elapsed;
    final interval = remaining < step ? remaining : step;
    await tester.pump(interval);
    elapsed += interval;
  }
}

void main() {
  testWidgets('home opens the game-mode hub and back returns home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openHome(tester);

    expect(find.text('LUDO LOVERS'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('local_game_lab_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview_board_button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Pick your way to play'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_vs_computer_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_two_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_four_players_button')), findsOneWidget);

    Navigator.of(tester.element(find.text('Pick your way to play'))).pop();
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('LUDO LOVERS'), findsAtLeastNWidgets(1));
  });

  testWidgets('two-player setup selects two colours and opens a local match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openHome(tester);
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.text('Set up 2-player game'));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.text('Choose your colours'), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_orange')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_green')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_blue')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_magenta')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('setup_colour_blue')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Player 1: ORANGE  ·  Player 2: BLUE'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('start_two_player_match_button')),
    );
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);


    expect(tester.takeException(), isNull);
  });

  testWidgets('AI mode and four-player mode each open the local match screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openHome(tester);
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.tap(find.text('Play vs AI'));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('portrait_turn_indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('how_to_play_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai_mode_status')), findsNothing);



    Navigator.of(tester.element(find.byKey(const ValueKey('roll_dice_button')))).pop();
    await pumpFor(tester, const Duration(milliseconds: 500));
    final fourPlayerAction = find.text('Start 4-player game');
    await tester.ensureVisible(fourPlayerAction);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(fourPlayerAction);
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);




    expect(tester.takeException(), isNull);
  });
}
