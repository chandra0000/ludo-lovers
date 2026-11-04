import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';
import 'package:ludo_lovers/app/theme/app_theme.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

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
  testWidgets('compact hub exposes AI, 2P, 4P and Team Up choices',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const GameModeSelectionScreen()),
    );

    expect(find.text('VS AI'), findsOneWidget);
    expect(find.text('2P'), findsOneWidget);
    expect(find.text('4P'), findsOneWidget);
    expect(find.text('TEAM UP'), findsOneWidget);
    expect(find.text('Choose how to play'), findsNothing);
    expect(find.text('Online rooms'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Team Up tile opens the 2-vs-2 match with team identities',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const GameModeSelectionScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('mode_team_up_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('team_up_identity_banner')), findsOneWidget);
    expect(find.text('TEAM A'), findsOneWidget);
    expect(find.text('TEAM B'), findsOneWidget);
    expect(find.text('ORANGE + MAGENTA'), findsOneWidget);
    expect(find.text('GREEN + BLUE'), findsOneWidget);
  });

  testWidgets('4P tile opens the four-seat local match', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const GameModeSelectionScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('mode_four_players_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
  });

  testWidgets('AI tile opens the local match', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const GameModeSelectionScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('mode_vs_computer_button')));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byType(LocalGameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('portrait_turn_indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('how_to_play_button')), findsOneWidget);
  });

  testWidgets(
    'real launch flow reaches a fully rendered match and survives repeated navigation',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const LudoLoversApp());
      // The production splash waits 2.5s and then fades to the compact hub.
      await pumpFor(tester, const Duration(milliseconds: 3000));
      expect(find.byType(GameModeSelectionScreen), findsOneWidget);
      expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);

      Future<void> openMode(String key) async {
        await tester.tap(find.byKey(ValueKey<String>(key)));
        await pumpFor(tester, const Duration(milliseconds: 600));
        expect(find.byType(LocalGameScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
        expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('live_game_board_artwork')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      Future<void> returnToHub() async {
        Navigator.of(tester.element(find.byType(LocalGameScreen))).pop();
        await pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.byType(GameModeSelectionScreen), findsOneWidget);
      }

      await openMode('mode_four_players_button');
      await returnToHub();

      await openMode('mode_vs_computer_button');
      await returnToHub();

      await tester.tap(find.byKey(const ValueKey('mode_two_players_button')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
      await pumpFor(tester, const Duration(milliseconds: 600));
      expect(find.byType(LocalGameScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
      await returnToHub();

      await openMode('mode_team_up_button');
    },
  );

}
