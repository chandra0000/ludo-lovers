import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 50);
  var remaining = duration;
  while (remaining > Duration.zero) {
    final interval = remaining > step ? step : remaining;
    await tester.pump(interval);
    remaining -= interval;
  }
}

void main() {
  testWidgets('app opens directly to the compact game mode hub after splash',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    await pumpFor(tester, const Duration(seconds: 4));

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_vs_computer_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_two_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_four_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_team_up_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('inline_two_player_setup')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding_skip_button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2P setup expands inline, selects two colours and starts match',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: GameModeSelectionScreen()),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mode_two_players_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('inline_two_player_setup')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_orange')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_green')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_blue')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_magenta')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('setup_colour_blue')));
    await tester.pump();
    expect(find.text('Player 1: ORANGE  ·  Player 2: BLUE'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('start_two_player_match_button')),
    );
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
