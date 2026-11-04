import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/widgets/animated_dice_widget.dart';
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
  ) =>
      child;
}

class _DelayedBoardAssetBundle extends CachingAssetBundle {
  final Completer<ByteData> _boardBytes = Completer<ByteData>();

  bool get boardRequested => _boardBytes.isCompleted || _requested;
  bool _requested = false;

  Future<void> releaseBoard() async {
    if (_boardBytes.isCompleted) return;
    _boardBytes.complete(
      await rootBundle.load('assets/images/ludo_board_glass.webp'),
    );
  }

  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('ludo_board_glass.webp')) {
      _requested = true;
      return _boardBytes.future;
    }
    return rootBundle.load(key);
  }
}

class _FailingBoardAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('ludo_board_glass.webp')) {
      return Future<ByteData>.error(
        StateError('Intentional missing-board-artwork test failure'),
      );
    }
    return rootBundle.load(key);
  }
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

Future<void> pumpScreen(
  WidgetTester tester, {
  required LocalGameController controller,
  required AssetBundle bundle,
  bool playAgainstAi = false,
  Size surface = const Size(900, 1600),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: bundle,
      child: MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: LocalGameScreen(
          controller: controller,
          playAgainstAi: playAgainstAi,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a visible loading state while board artwork is pending',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);
    final bundle = _DelayedBoardAssetBundle();

    await pumpScreen(
      tester,
      controller: controller,
      bundle: bundle,
    );
    await pumpFor(tester, const Duration(milliseconds: 100));

    expect(bundle.boardRequested, isTrue);
    expect(find.text('LOADING LUDO BOARD…'), findsOneWidget);
    expect(find.byKey(const ValueKey('live_game_board_artwork_fallback')),
        findsNothing);

    await bundle.releaseBoard();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('live_game_board_artwork_fallback')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a readable fallback when board artwork cannot load',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      controller: controller,
      bundle: _FailingBoardAssetBundle(),
    );
    await pumpFor(tester, const Duration(milliseconds: 800));

    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live_game_board_artwork_fallback')),
      findsOneWidget,
    );
    expect(find.text('BOARD ARTWORK UNAVAILABLE'), findsOneWidget);
    expect(find.byKey(const ValueKey('roll_dice_button_semantics')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps board and dice visible in a portrait tablet viewport',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      controller: controller,
      bundle: rootBundle,
      surface: const Size(800, 1280),
    );
    await pumpFor(tester, const Duration(milliseconds: 600));

    const viewport = Rect.fromLTWH(0, 0, 800, 1280);
    final board = tester.getRect(
      find.byKey(const ValueKey('local_game_board')),
    );
    final dice = tester.getRect(
      find.byKey(const ValueKey('roll_dice_button')),
    );

    expect(viewport.contains(board.topLeft), isTrue);
    expect(viewport.contains(board.bottomRight), isTrue);
    expect(viewport.contains(dice.topLeft), isTrue);
    expect(viewport.contains(dice.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancels the dice animation timer when leaving mid-roll',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await pumpScreen(
      tester,
      controller: controller,
      bundle: rootBundle,
    );
    await pumpFor(tester, const Duration(milliseconds: 400));

    tester.widget<AnimatedDiceWidget>(find.byType(AnimatedDiceWidget)).onRoll();
    await pumpFor(tester, const Duration(milliseconds: 100));
    final versionAfterRoll = controller.state.version;
    expect(versionAfterRoll, greaterThan(0));

    // Replacing the route root disposes LocalGameScreen immediately while
    // its presentation-only dice timer is still active.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('Home')))),
    );
    await pumpFor(tester, const Duration(milliseconds: 1000));

    expect(controller.state.version, versionAfterRoll);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancels AI work and detaches screen listeners across 50 exits',
      (tester) async {
    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();

    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoTransitionsBuilder(),
            },
          ),
        ),
        home: const Scaffold(body: Center(child: Text('Home'))),
      ),
    );

    final initialVersion = controller.state.version;
    for (var cycle = 0; cycle < 50; cycle++) {
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LocalGameScreen(
            controller: controller,
            playAgainstAi: true,
          ),
        ),
      );
      await tester.pump();
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);

      navigatorKey.currentState!.pop();
      await tester.pump();
      await pumpFor(tester, const Duration(milliseconds: 50));
      expect(find.text('Home'), findsOneWidget);
      expect(controller.state.version, initialVersion);
      expect(tester.takeException(), isNull);
    }

    // If a canceled AI timer or stale listener survived a route exit, it would
    // mutate the injected controller or surface an exception here.
    await pumpFor(tester, const Duration(milliseconds: 1000));
    expect(controller.state.version, initialVersion);
    expect(controller.state.currentPlayerId, 'orange');
    expect(tester.takeException(), isNull);
  });
}
