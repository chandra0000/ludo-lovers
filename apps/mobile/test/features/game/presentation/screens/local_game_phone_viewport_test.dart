import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
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

Future<void> _pumpFrames(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 50) {
    await tester.pump(
      Duration(milliseconds: milliseconds - elapsed < 50
          ? milliseconds - elapsed
          : 50),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profiles = <Size>[
    Size(360, 800),
    Size(393, 873),
  ];

  const modes = <({
    String name,
    List<String> players,
    LocalGameMode mode,
    bool againstAi,
  })>[
    (
      name: '2P',
      players: <String>['orange', 'green'],
      mode: LocalGameMode.classic,
      againstAi: false,
    ),
    (
      name: '4P',
      players: LocalGameFactory.playerIds,
      mode: LocalGameMode.classic,
      againstAi: false,
    ),
    (
      name: 'VS AI',
      players: LocalGameFactory.playerIds,
      mode: LocalGameMode.classic,
      againstAi: true,
    ),
    (
      name: 'Team Up',
      players: LocalGameFactory.playerIds,
      mode: LocalGameMode.teamUp,
      againstAi: false,
    ),
  ];

  for (final profile in profiles) {
    for (final mode in modes) {
      testWidgets(
        '${mode.name} renders the complete gameplay surface at ${profile.width.toInt()}x${profile.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = profile;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final setup = LocalGameFactory.create(
            allowProvisionalRoutes: true,
            selectedPlayerIds: mode.players,
            mode: mode.mode,
          );
          final controller = LocalGameController(
            gameSetup: setup,
            nextDiceValue: () => 6,
          );
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: Brightness.dark,
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: {
                    for (final platform in TargetPlatform.values)
                      platform: const _NoTransitionsBuilder(),
                  },
                ),
              ),
              home: LocalGameScreen(
                controller: controller,
                playAgainstAi: mode.againstAi,
                gameMode: mode.mode,
                selectedPlayerIds: mode.players,
              ),
            ),
          );
          await _pumpFrames(tester, 800);

          expect(
            find.byKey(const ValueKey('live_game_board_artwork')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('live_game_board_artwork_fallback')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('local_game_board')),
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

          final viewport = Rect.fromLTWH(0, 0, profile.width, profile.height);
          for (final key in const [
            ValueKey('local_game_board'),
            ValueKey('roll_dice_button'),
          ]) {
            final rect = tester.getRect(find.byKey(key));
            expect(viewport.contains(rect.topLeft), isTrue,
                reason: '${mode.name} $key begins outside the phone viewport: $rect');
            expect(viewport.contains(rect.bottomRight), isTrue,
                reason: '${mode.name} $key ends outside the phone viewport: $rect');
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
