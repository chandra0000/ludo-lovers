import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

void main() {
  testWidgets('home opens the game-mode hub and back returns home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.byKey(const ValueKey('local_game_lab_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview_board_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pick your way to play'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_vs_computer_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_two_players_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode_four_players_button')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('LUDO LOVERS'), findsOneWidget);
  });

  testWidgets('two-player setup selects two colours and opens a local match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mode_two_players_button')));
    await tester.pumpAndSettle();

    expect(find.text('Choose your colours'), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_orange')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_green')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_blue')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup_colour_magenta')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('setup_colour_blue')));
    await tester.pumpAndSettle();
    expect(find.text('Player 1: ORANGE  ·  Player 2: BLUE'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('start_two_player_match_button')),
    );
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
    expect(find.text('BLUE'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI mode and four-player mode each open the local match screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LudoLoversApp());
    await tester.tap(find.byKey(const ValueKey('local_game_lab_button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('mode_vs_computer_button')),
    );
    await tester.tap(find.byKey(const ValueKey('mode_vs_computer_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai_mode_status')), findsOneWidget);
    expect(find.text('AI'), findsNWidgets(3));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('mode_four_players_button')),
    );
    await tester.tap(find.byKey(const ValueKey('mode_four_players_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
    expect(find.text('GREEN'), findsAtLeastNWidgets(1));
    expect(find.text('BLUE'), findsAtLeastNWidgets(1));
    expect(find.text('MAGENTA'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
