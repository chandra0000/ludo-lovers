import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

Future<void> _pumpGameplayFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 16; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  Future<void> openMode(
    WidgetTester tester, {
    required String modeKey,
    bool configureTwoPlayers = false,
  }) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GameModeSelectionScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(ValueKey(modeKey)));
    await tester.pump();

    if (configureTwoPlayers) {
      expect(find.byKey(const ValueKey('inline_two_player_setup')), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('start_two_player_match_button')),
      );
    }

    await _pumpGameplayFrames(tester);

    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live_game_board_artwork')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roll_dice_button_semantics')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pawn_marker_orange_pawn_1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }

  testWidgets('2P setup navigates into a rendered local match', (tester) async {
    await openMode(
      tester,
      modeKey: 'mode_two_players_button',
      configureTwoPlayers: true,
    );
  });

  testWidgets('4P selection navigates into a rendered local match', (tester) async {
    await openMode(tester, modeKey: 'mode_four_players_button');
  });

  testWidgets('VS AI selection navigates into a rendered local match', (tester) async {
    await openMode(tester, modeKey: 'mode_vs_computer_button');
  });

  testWidgets('Team Up selection navigates into a rendered local match', (tester) async {
    await openMode(tester, modeKey: 'mode_team_up_button');
  });
}
