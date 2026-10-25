import 'package:flutter/material.dart';
import 'package:ludo_lovers/features/game/domain/board/board_pawn_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets('starts a local two-player match with user-selected colours', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('player_setup_button')));
    await tester.pumpAndSettle();

    expect(find.text('Two-player local match'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('start_two_player_match_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('player_colour_orange')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('player_colour_green')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('player_colour_blue')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('player_colour_magenta')));
    await tester.pump();

    expect(find.text('Player 1: BLUE · Player 2: MAGENTA'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start_two_player_match_button')));
    await tester.pumpAndSettle();

    expect(controller.state.players, <String>['blue', 'magenta']);
    expect(controller.state.pawns, hasLength(8));
    expect(
      controller.state.pawns.every(
        (pawn) => <String>['blue', 'magenta'].contains(pawn.playerId),
      ),
      isTrue,
    );
  });

  testWidgets('local match strip labels seats without implying online status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    expect(find.byKey(const ValueKey('live_game_board_artwork')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byKey(const ValueKey('local_match_player_strip')), findsOneWidget);
    expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
    expect(find.text('GREEN'), findsAtLeastNWidgets(1));
    expect(find.text('BLUE'), findsAtLeastNWidgets(1));
    expect(find.text('MAGENTA'), findsAtLeastNWidgets(1));
    expect(find.text('LOCAL'), findsNothing);
    expect(find.text('YOUR TURN'), findsNothing);
    expect(find.byKey(const ValueKey('match_more_actions_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle_sound_button')), findsNothing);
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('AI chooses a legal capture over an ordinary advance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final greenPath = setup.paths.forPlayer('green');
    final bluePath = setup.paths.forPlayer('blue');
    final safeCells = setup.engine.safeCellIndexes;

    int? captureProgress;
    int? blueProgress;
    int? captureDestination;
    for (var progress = 0; progress < greenPath.trackLength - 1; progress++) {
      final destination = greenPath.mainTrackCells[progress + 1];
      final matchingBlueProgress = bluePath.mainTrackCells.indexOf(destination);
      if (matchingBlueProgress >= 0 &&
          matchingBlueProgress < bluePath.trackLength &&
          !safeCells.contains(destination)) {
        captureProgress = progress;
        blueProgress = matchingBlueProgress;
        captureDestination = destination;
        break;
      }
    }
    expect(captureProgress, isNotNull);
    expect(blueProgress, isNotNull);
    expect(captureDestination, isNotNull);

    int? alternateProgress;
    for (var progress = 0; progress < greenPath.trackLength - 1; progress++) {
      final destination = greenPath.mainTrackCells[progress + 1];
      if (progress != captureProgress &&
          destination != captureDestination &&
          !safeCells.contains(destination)) {
        alternateProgress = progress;
        break;
      }
    }
    expect(alternateProgress, isNotNull);

    final initialState = setup.initialState.copyWith(
      currentPlayerIndex: 1,
      pendingRoll: 1,
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.id == 'green_pawn_1') {
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: captureProgress,
            ),
          );
        }
        if (pawn.id == 'green_pawn_2') {
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: alternateProgress,
            ),
          );
        }
        if (pawn.id == 'blue_pawn_1') {
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: blueProgress,
            ),
          );
        }
        return pawn;
      }).toList(growable: false),
    );
    final controller = LocalGameController(
      nextDiceValue: () => 1,
      gameSetup: setup,
      initialState: initialState,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('toggle_ai_button')));
    await tester.pump(const Duration(milliseconds: 450));

    final greenPawn = controller.state.pawns.firstWhere(
      (pawn) => pawn.id == 'green_pawn_1',
    );
    final bluePawn = controller.state.pawns.firstWhere(
      (pawn) => pawn.id == 'blue_pawn_1',
    );
    expect(greenPawn.position.progress, captureProgress! + 1);
    expect(bluePawn.position.section, PawnRouteSection.yard);
    expect(controller.state.currentPlayerId, 'green');
    expect(controller.state.pendingRoll, isNull);
    expect(controller.lastMessage, contains('PawnCaptured'));
  });

  testWidgets('keeps the complete board square and within a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    final boardFinder = find.byKey(const ValueKey('local_game_board'));
    expect(boardFinder, findsOneWidget);
    final boardSize = tester.getSize(boardFinder);
    expect(boardSize.width, greaterThan(0));
    expect(boardSize.height, greaterThan(0));
    expect(
      boardSize.width,
      closeTo(boardSize.height, 0.01),
      reason: 'The four home areas and centre must not be distorted by layout.',
    );
    expect(
      boardSize.width,
      lessThanOrEqualTo(340),
      reason: 'Board width must fit the 360 px viewport with screen padding.',
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('keeps the board square on compact and landscape screens', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const viewports = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(800, 360),
    ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      final controller = LocalGameController(nextDiceValue: () => 6);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      final boardFinder = find.byKey(const ValueKey('local_game_board'));
      expect(boardFinder, findsOneWidget, reason: 'Viewport: $viewport');
      final boardSize = tester.getSize(boardFinder);
      expect(boardSize.width, greaterThan(0), reason: 'Viewport: $viewport');
      expect(
        boardSize.width,
        closeTo(boardSize.height, 0.01),
        reason: 'The board must remain square at $viewport.',
      );
      expect(
        boardSize.width,
        lessThanOrEqualTo(viewport.width - 20),
        reason: 'The whole board must fit the available width at $viewport.',
      );
      expect(tester.takeException(), isNull, reason: 'Viewport: $viewport');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    }
  });

  testWidgets(
    'rolls, highlights a legal pawn, and moves it on the polished match screen',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
      final initialRollSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('roll_dice_button_semantics')),
      );
      expect(
        initialRollSemantics.properties.hint,
        'Roll a die to begin the current player’s turn.',
      );
      expect(find.byKey(const ValueKey('local_playtest_status')), findsNothing);
      expect(find.text('LOCAL'), findsNothing);
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.text('BLUE'), findsAtLeastNWidgets(1));
      expect(find.text('MAGENTA'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const ValueKey('local_match_player_strip')),
        findsOneWidget,
      );
      expect(find.byType(CircleAvatar), findsNWidgets(4));
      expect(find.byIcon(Icons.person_rounded), findsNothing);
      expect(find.byKey(const ValueKey('compact_turn_status')), findsNothing);
      expect(find.byKey(const ValueKey('match_turn_caption')), findsNothing);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('React'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      expect(controller.state.pendingRoll, 6);
      expect(find.byKey(const ValueKey('dice_result_6')), findsOneWidget);
      final diceSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('dice_result_semantics')),
      );
      expect(diceSemantics.properties.label, 'Dice result: 6');
      expect(diceSemantics.properties.liveRegion, isTrue);
      final diceSwitcher = tester.widget<AnimatedSwitcher>(
        find.ancestor(
          of: find.byKey(const ValueKey('dice_result_6')),
          matching: find.byType(AnimatedSwitcher),
        ).first,
      );
      expect(diceSwitcher.duration, const Duration(milliseconds: 260));
      final rollButtonWhileMovePending =
          tester.widget<ElevatedButton>(find.byKey(const ValueKey('roll_dice_button')));
      expect(
        rollButtonWhileMovePending.onPressed,
        isNull,
        reason: 'A second roll must not be available before the pending move is used.',
      );
      final pendingRollSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('roll_dice_button_semantics')),
      );
      expect(
        pendingRollSemantics.properties.hint,
        'Choose a highlighted pawn to use the current roll.',
      );
      expect(find.text('You rolled 6. Choose a glowing pawn.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
        findsOneWidget,
      );
      final pawnSemantics = tester.widget<Semantics>(
        find.ancestor(
          of: find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(pawnSemantics.properties.button, isTrue);
      expect(pawnSemantics.properties.label, 'Orange pawn 1');
      expect(
        pawnSemantics.properties.hint,
        'Moves this pawn 6 spaces using the current dice roll.',
      );

      expect(
        find.byKey(const ValueKey('destination_cell_0_orange_pawn_1')),
        findsOneWidget,
        reason: 'Legal entry should preview its destination on the board.',
      );

      await tester.tap(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      );
      await tester.pumpAndSettle();

      final pawn = controller.state.pawns.firstWhere(
        (item) => item.id == 'orange_pawn_1',
      );
      expect(pawn.position.section, PawnRouteSection.mainTrack);
      expect(pawn.position.progress, 0);
      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.currentPlayerId, 'orange');
      final rollButtonAfterMove =
          tester.widget<ElevatedButton>(find.byKey(const ValueKey('roll_dice_button')));
      expect(
        rollButtonAfterMove.onPressed,
        isNotNull,
        reason: 'The extra turn should allow a fresh roll after the move resolves.',
      );
      expect(find.textContaining('ExtraRollGranted'), findsOneWidget);
      expect(
        find.text('Bonus roll unlocked — it is still your turn.'),
        findsOneWidget,
      );
      final feedbackSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('local_action_feedback_semantics')),
      );
      expect(
        feedbackSemantics.properties.label,
        'Bonus roll unlocked — it is still your turn.',
      );
      expect(feedbackSemantics.properties.liveRegion, isTrue);
    },
  );


  testWidgets(
    'ignores a duplicate pawn tap from an outdated board frame',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = LocalGameController(nextDiceValue: () => 6);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      final pawnFinder = find.byKey(
        const ValueKey('legal_pawn_orange_pawn_1'),
      );
      final stalePawnWidget = tester.widget<GestureDetector>(pawnFinder);
      final versionBeforeMove = controller.state.version;

      stalePawnWidget.onTap!();
      stalePawnWidget.onTap!();
      await tester.pumpAndSettle();

      final pawn = controller.state.pawns.firstWhere(
        (item) => item.id == 'orange_pawn_1',
      );
      expect(controller.state.version, versionBeforeMove + 1);
      expect(pawn.position.section, PawnRouteSection.mainTrack);
      expect(pawn.position.progress, 0);
      expect(controller.state.pendingRoll, isNull);
      expect(controller.lastError?.error, LocalActionError.staleVersion);
    },
  );


  testWidgets(
    'previews the private home-lane destination before accepting a move',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final orangePath = setup.paths.forPlayer('orange');
      final startOfHomeLane = orangePath.trackLength;
      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id != 'orange_pawn_1') return pawn;
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: orangePath.trackLength - 1,
            ),
          );
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 1,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      final homeLaneCell = orangePath.cellAtProgress(startOfHomeLane);
      expect(homeLaneCell, isNotNull);
      expect(
        find.byKey(
          ValueKey('destination_cell_${homeLaneCell}_orange_pawn_1'),
        ),
        findsOneWidget,
        reason: 'The preview should show the exact private-lane destination.',
      );

      await tester.tap(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
      );
      await tester.pumpAndSettle();

      final movedPawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'orange_pawn_1',
      );
      expect(movedPawn.position.section, PawnRouteSection.homeLane);
      expect(movedPawn.position.progress, orangePath.trackLength);
      expect(
        find.byKey(
          ValueKey('destination_cell_${homeLaneCell}_orange_pawn_1'),
        ),
        findsNothing,
        reason: 'A consumed roll must clear the stale destination preview.',
      );
    },
  );

  testWidgets(
    'shows capture resolution and keeps the bonus turn in sync',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      // Orange moves from global cell 1 to 2; blue's relative progress 15
      // resolves to that same provisional shared-track cell.
      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(
              position: const PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: 1,
              ),
            );
          }
          if (pawn.id == 'blue_pawn_1') {
            return pawn.copyWith(
              position: const PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: 15,
              ),
            );
          }
          return pawn;
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 1,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
      await tester.pumpAndSettle();

      final orangePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'orange_pawn_1',
      );
      final capturedBluePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'blue_pawn_1',
      );
      expect(orangePawn.position.progress, 2);
      expect(orangePawn.position.section, PawnRouteSection.mainTrack);
      expect(capturedBluePawn.position.section, PawnRouteSection.yard);
      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.pendingRoll, isNull);
      expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
      
      expect(find.textContaining('PawnCaptured'), findsOneWidget);
      expect(
        find.text('Brilliant capture! An opponent pawn returns to the yard.'),
        findsOneWidget,
      );
      expect(find.textContaining('ExtraRollGranted'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(
          find.byKey(const ValueKey('roll_dice_button')),
        ).onPressed,
        isNotNull,
        reason: 'A capture should grant the current player another roll.',
      );
    },
  );

  testWidgets(
    'keeps the entry cell safe when a pawn leaves the yard',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final orangePath = setup.paths.forPlayer('orange');
      final bluePath = setup.paths.forPlayer('blue');
      final entryCell = orangePath.mainTrackCells.first;
      expect(
        setup.engine.safeCellIndexes,
        contains(entryCell),
        reason: 'A player’s entry square must be configured as safe.',
      );
      final blueProgress = bluePath.mainTrackCells.indexOf(entryCell);
      expect(blueProgress, greaterThanOrEqualTo(0));

      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'blue_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: blueProgress,
              ),
            );
          }
          return pawn;
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 6,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
      await tester.pumpAndSettle();

      final orangePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'orange_pawn_1',
      );
      final bluePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'blue_pawn_1',
      );
      expect(orangePawn.position.section, PawnRouteSection.mainTrack);
      expect(orangePath.cellAtProgress(orangePawn.position.progress!), entryCell);
      expect(bluePath.cellAtProgress(bluePawn.position.progress!), entryCell);
      expect(bluePawn.position.section, PawnRouteSection.mainTrack);
      expect(controller.state.currentPlayerId, 'orange');
      expect(controller.state.pendingRoll, isNull);
      expect(find.textContaining('PawnCaptured'), findsNothing);
      expect(find.textContaining('ExtraRollGranted'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps an opponent pawn safe and advances the turn without a capture bonus',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final orangePath = setup.paths.forPlayer('orange');
      final bluePath = setup.paths.forPlayer('blue');
      final safeCell = setup.engine.safeCellIndexes.firstWhere(
        (cell) => orangePath.mainTrackCells.indexOf(cell) > 0,
      );
      final orangeDestinationProgress = orangePath.mainTrackCells.indexOf(safeCell);
      final blueProgress = bluePath.mainTrackCells.indexOf(safeCell);
      expect(orangeDestinationProgress, greaterThanOrEqualTo(0));
      expect(blueProgress, greaterThanOrEqualTo(0));
      final orangeStartProgress = orangeDestinationProgress - 1;

      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: orangeStartProgress,
              ),
            );
          }
          if (pawn.id == 'blue_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: blueProgress,
              ),
            );
          }
          return pawn;
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 1,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
      await tester.pumpAndSettle();

      final orangePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'orange_pawn_1',
      );
      final bluePawn = controller.state.pawns.firstWhere(
        (pawn) => pawn.id == 'blue_pawn_1',
      );
      expect(orangePath.cellAtProgress(orangePawn.position.progress!), safeCell);
      expect(bluePath.cellAtProgress(bluePawn.position.progress!), safeCell);
      expect(bluePawn.position.section, PawnRouteSection.mainTrack);
      expect(controller.state.currentPlayerId, 'green');
      expect(controller.state.pendingRoll, isNull);
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.textContaining('PawnCaptured'), findsNothing);
      expect(find.textContaining('ExtraRollGranted'), findsNothing);
      expect(find.textContaining('TurnEnded'), findsOneWidget);
    },
  );

  testWidgets(
    'protects a stacked opponent pair and does not grant a capture bonus',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final orangePath = setup.paths.forPlayer('orange');
      final bluePath = setup.paths.forPlayer('blue');
      final destinationProgress = orangePath.mainTrackCells.indexWhere(
        (cell) => !setup.engine.safeCellIndexes.contains(cell),
      );
      expect(destinationProgress, greaterThan(0));
      final destinationCell = orangePath.cellAtProgress(destinationProgress)!;
      final blueProgress = bluePath.mainTrackCells.indexOf(destinationCell);
      expect(blueProgress, greaterThanOrEqualTo(0));
      final orangeStartProgress = destinationProgress - 1;

      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id == 'orange_pawn_1') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: orangeStartProgress,
              ),
            );
          }
          if (pawn.id == 'blue_pawn_1' || pawn.id == 'blue_pawn_2') {
            return pawn.copyWith(
              position: PawnRoutePosition(
                section: PawnRouteSection.mainTrack,
                progress: blueProgress,
              ),
            );
          }
          return pawn;
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 1,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
      await tester.pumpAndSettle();

      final bluePawns = controller.state.pawns.where(
        (pawn) => pawn.id == 'blue_pawn_1' || pawn.id == 'blue_pawn_2',
      );
      expect(
        bluePawns.every(
          (pawn) =>
              pawn.position.section == PawnRouteSection.mainTrack &&
              bluePath.cellAtProgress(pawn.position.progress!) == destinationCell,
        ),
        isTrue,
      );
      expect(controller.state.currentPlayerId, 'green');
      expect(controller.state.pendingRoll, isNull);
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.textContaining('PawnCaptured'), findsNothing);
      expect(find.textContaining('ExtraRollGranted'), findsNothing);
      expect(find.textContaining('TurnEnded'), findsOneWidget);
    },
  );

  testWidgets(
    'rejects a home-lane overshoot and advances the turn in the UI',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final finishProgress = setup.paths.forPlayer('orange').finishProgress;
      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id != 'orange_pawn_1') return pawn;
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: finishProgress - 1,
            ),
          );
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 2,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      expect(controller.state.pendingRoll, isNull);
      expect(controller.state.currentPlayerId, 'green');
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.textContaining('NoLegalMove · TurnEnded'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('legal_pawn_orange_pawn_1')),
        findsNothing,
        reason: 'A roll that overshoots the finish must not make the pawn selectable.',
      );
      final pawn = controller.state.pawns.firstWhere(
        (item) => item.id == 'orange_pawn_1',
      );
      expect(pawn.position.section, PawnRouteSection.homeLane);
      expect(pawn.position.progress, finishProgress - 1);
    },
  );

  testWidgets(
    'shows a distinct home celebration when a pawn reaches the finish',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
      final finishProgress = setup.paths.forPlayer('orange').finishProgress;
      final initialState = setup.initialState.copyWith(
        pawns: setup.initialState.pawns.map((pawn) {
          if (pawn.id != 'orange_pawn_1') return pawn;
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: finishProgress - 1,
            ),
          );
        }).toList(growable: false),
      );
      final controller = LocalGameController(
        nextDiceValue: () => 1,
        gameSetup: setup,
        initialState: initialState,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
      await tester.pumpAndSettle();

      expect(
        controller.state.pawns
            .firstWhere((pawn) => pawn.id == 'orange_pawn_1')
            .position.section,
        PawnRouteSection.finished,
      );
      expect(
        find.text('Home at last! Your pawn reached the centre.'),
        findsOneWidget,
      );
      expect(
        tester.widget<Icon>(
          find.byKey(const ValueKey('local_action_feedback_icon')),
        ).icon,
        Icons.home_rounded,
      );
      expect(controller.state.completed, isFalse);
    },
  );

  testWidgets('passes a non-six roll when every pawn is still in the yard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 3);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();

    expect(controller.state.currentPlayerId, 'green');
    expect(controller.state.pendingRoll, isNull);
    expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')), findsNothing);
    expect(find.text('GREEN'), findsAtLeastNWidgets(1));
  });

  testWidgets('restart resets the local match state', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restart match'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm_restart_button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm_restart_button')));
    await tester.pumpAndSettle();

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
    );
  });

  testWidgets('shows the winner, locks completed play, and rematches cleanly', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final finishProgress = setup.paths.forPlayer('orange').finishProgress;
    final winningState = setup.initialState.copyWith(
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.playerId != 'orange') return pawn;
        if (pawn.id == 'orange_pawn_4') {
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: finishProgress - 2,
            ),
          );
        }
        return pawn.copyWith(
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: finishProgress,
          ),
        );
      }).toList(growable: false),
    );
    final controller = LocalGameController(
      nextDiceValue: () => 2,
      gameSetup: setup,
      initialState: winningState,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_4')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_4')));
    await tester.pumpAndSettle();

    expect(controller.state.completed, isTrue);
    expect(controller.state.winnerPlayerId, 'orange');
    expect(find.text('ORANGE TAKES THE CROWN'), findsOneWidget);
    expect(find.text('ORANGE TAKES THE CROWN'), findsOneWidget);
    expect(find.byKey(const ValueKey('match_standings_panel')), findsOneWidget);
    expect(find.text('MATCH STANDINGS'), findsOneWidget);
    expect(find.text('ORANGE · WINNER'), findsOneWidget);
    expect(find.byKey(const ValueKey('results_home_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('results_rematch_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_4')), findsNothing);
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('roll_dice_button')),
      ).onPressed,
      isNull,
      reason: 'A completed match must not accept another roll.',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('results_rematch_button')));
    await tester.tap(find.byKey(const ValueKey('results_rematch_button')));
    await tester.pumpAndSettle();

    expect(controller.state.completed, isFalse);
    expect(controller.state.winnerPlayerId, isNull);
    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(
      controller.state.pawns.every(
        (pawn) => pawn.position.section == PawnRouteSection.yard,
      ),
      isTrue,
      reason: 'Rematch must restore the canonical fresh-game state.',
    );
    expect(find.text('ORANGE'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('results_rematch_button')), findsNothing);
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('roll_dice_button')),
      ).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'keeps turn HUD and pawn counters synchronized after a skipped turn',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final rolls = <int>[3, 6];
      final controller = LocalGameController(
        nextDiceValue: () => rolls.removeAt(0),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: LocalGameScreen(controller: controller),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();

      expect(controller.state.currentPlayerId, 'green');
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.textContaining('NoLegalMove · TurnEnded'), findsOneWidget);
      expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('legal_pawn_green_pawn_1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('legal_pawn_green_pawn_1')));
      await tester.pumpAndSettle();

      expect(controller.state.currentPlayerId, 'green');
      expect(
        controller.state.pawns.firstWhere((pawn) => pawn.id == 'green_pawn_1')
            .position.section,
        PawnRouteSection.mainTrack,
      );
      
      expect(find.text('GREEN'), findsAtLeastNWidgets(1));
      expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')), findsNothing);
    },
  );


  testWidgets('explains provisional rules and returns safely to the match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('match_more_actions_button')));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);
    await tester.tap(find.text('How to play').last);
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Quick guide for this local prototype'), findsOneWidget);
    expect(find.text('Roll the dice'), findsOneWidget);
    expect(find.text('Choose a glowing pawn'), findsOneWidget);
    expect(find.text('Reach home exactly'), findsOneWidget);
    expect(
      find.textContaining(
        'The owner-confirmed safe/star positions are fixed. The complete board route still requires on-device visual review.',
      ),
      findsOneWidget,
    );
    expect(find.text('Board geometry review'), findsOneWidget);
    expect(find.text('Provisional entries'), findsOneWidget);
    expect(find.text('ORANGE · track entry 0'), findsOneWidget);
    expect(find.text('GREEN · track entry 13'), findsOneWidget);
    expect(find.text('BLUE · track entry 39'), findsOneWidget);
    expect(find.text('MAGENTA · track entry 26'), findsOneWidget);
    expect(
      find.text('Owner-confirmed safe-cell IDs: 0, 8, 13, 21, 26, 34, 39, 47'),
      findsOneWidget,
    );
    for (final transition in <String>[
      '4 (5,6) → 5 (6,5)',
      '17 (8,5) → 18 (9,6)',
      '30 (9,8) → 31 (8,9)',
      '43 (6,9) → 44 (5,8)',
    ]) {
      expect(find.text(transition), findsOneWidget);
    }

    await tester.tap(find.text('Back to match'));
    await tester.pumpAndSettle();

    expect(find.text('Quick guide for this local prototype'), findsNothing);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
  });

  testWidgets('animates a pawn from its yard onto the shared track', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    final marker = find.byKey(
      const ValueKey('pawn_marker_orange_pawn_1'),
    );
    expect(marker, findsOneWidget);
    expect(
      tester.widget<AnimatedPositioned>(marker).duration,
      const Duration(milliseconds: 260),
    );
    final start = tester.getTopLeft(marker);

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(marker);

    expect(end, isNot(start));
    expect(
      controller.state.pawns
          .firstWhere((pawn) => pawn.id == 'orange_pawn_1')
          .position.section,
      PawnRouteSection.mainTrack,
    );
  });


  testWidgets('animates through each route cell and lands on the engine destination', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final initialState = setup.initialState.copyWith(
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.id != 'orange_pawn_1') return pawn;
        return pawn.copyWith(
          position: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 0,
          ),
        );
      }).toList(growable: false),
    );
    final controller = LocalGameController(
      gameSetup: setup,
      initialState: initialState,
      nextDiceValue: () => 3,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    final marker = find.byKey(
      const ValueKey('pawn_marker_orange_pawn_1'),
    );
    final board = find.byKey(const ValueKey('local_game_board'));
    final boardTopLeft = tester.getTopLeft(board);
    final boardSize = tester.getSize(board).width;
    const pawnId = 'orange_pawn_1';
    final pawnLayout = BoardPawnLayout.classic();

    Offset expectedTopLeft(int progress) {
      final visual = pawnLayout.resolve(
        playerId: 'orange',
        pawnId: pawnId,
        position: PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: progress,
        ),
      );
      final diameter = boardSize / 15 * 0.58;
      return boardTopLeft +
          Offset(
            visual.point.x * boardSize - diameter / 2,
            visual.point.y * boardSize - diameter / 2,
          );
    }

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pump(); // Start the first AnimatedPositioned transition.

    // Each timer is longer than the AnimatedPositioned duration, so the pawn
    // must settle on each intermediate cell before advancing to the next one.
    await tester.pump(const Duration(milliseconds: 300));
    final firstCell = tester.getTopLeft(marker);
    expect(firstCell.dx, closeTo(expectedTopLeft(1).dx, 1.5));
    expect(firstCell.dy, closeTo(expectedTopLeft(1).dy, 1.5));

    // Timer callbacks are delivered at the next test frame; pump that frame,
    // then let the full 260ms AnimatedPositioned transition finish.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 260));
    final secondCell = tester.getTopLeft(marker);
    expect(secondCell.dx, closeTo(expectedTopLeft(2).dx, 1.5));
    expect(secondCell.dy, closeTo(expectedTopLeft(2).dy, 1.5));
    expect(secondCell, isNot(firstCell));

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 260));
    final finalCell = tester.getTopLeft(marker);
    expect(finalCell.dx, closeTo(expectedTopLeft(3).dx, 1.5));
    expect(finalCell.dy, closeTo(expectedTopLeft(3).dy, 1.5));
    expect(finalCell, isNot(secondCell));
    expect(
      controller.state.pawns
          .firstWhere((pawn) => pawn.id == pawnId)
          .position.progress,
      3,
    );

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    final settled = tester.getTopLeft(marker);
    expect(settled.dx, closeTo(expectedTopLeft(3).dx, 1.5));
    expect(settled.dy, closeTo(expectedTopLeft(3).dy, 1.5));
  });

  testWidgets('AI opponents take turns and return control to orange', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rolls = <int>[6, 1, 3, 3, 3];
    var rollIndex = 0;
    final controller = LocalGameController(
      nextDiceValue: () => rolls[rollIndex++ % rolls.length],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('toggle_ai_button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ai_mode_status')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();

    // A one advances orange and passes the turn to the AI-controlled seats.
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();

    // Advance the fake clock for the three independently scheduled AI turns.
    for (var turn = 0; turn < 3; turn++) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(rollIndex, 5);
    expect(find.byKey(const ValueKey('ai_mode_status')), findsOneWidget);
  });


  testWidgets('celebrates a completed local match with the winner banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = LocalGameFactory.create(allowProvisionalRoutes: true);
    final orangePath = setup.paths.forPlayer('orange');
    final initialState = setup.initialState.copyWith(
      pawns: setup.initialState.pawns.map((pawn) {
        if (pawn.playerId != 'orange') return pawn;
        if (pawn.id == 'orange_pawn_1') {
          return pawn.copyWith(
            position: PawnRoutePosition(
              section: PawnRouteSection.homeLane,
              progress: orangePath.finishProgress - 1,
            ),
          );
        }
        return pawn.copyWith(
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: orangePath.finishProgress,
          ),
        );
      }).toList(growable: false),
    );
    final controller = LocalGameController(
      nextDiceValue: () => 1,
      gameSetup: setup,
      initialState: initialState,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();

    expect(controller.state.completed, isTrue);
    expect(controller.state.winnerPlayerId, 'orange');
    expect(find.byKey(const ValueKey('match_finish_banner')), findsOneWidget);
    expect(find.text('MATCH WON'), findsOneWidget);
    expect(find.text('ORANGE TAKES THE CROWN'), findsOneWidget);
    expect(find.byKey(const ValueKey('results_rematch_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('results_rematch_button')));
    await tester.pumpAndSettle();

    expect(controller.state.completed, isFalse);
    expect(controller.state.currentPlayerId, 'orange');
    expect(find.byKey(const ValueKey('match_finish_banner')), findsNothing);
  });


  testWidgets('AI handles a six bonus roll before passing to the next seat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rolls = <int>[6, 1, 6, 1, 3, 3];
    var rollIndex = 0;
    final controller = LocalGameController(
      nextDiceValue: () => rolls[rollIndex++ % rolls.length],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('toggle_ai_button')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();

    // Orange's six grants another roll; use the one, then pass to Green.
    await tester.tap(find.byKey(const ValueKey('roll_dice_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('legal_pawn_orange_pawn_1')));
    await tester.pumpAndSettle();
    expect(controller.state.currentPlayerId, 'green');

    // pumpAndSettle may advance scheduled timers too, so verify the final
    // outcome instead of depending on an exact intermediate frame.
    for (var turn = 0; turn < 6; turn++) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(
      controller.state.pawns
          .firstWhere((pawn) => pawn.id == 'green_pawn_1')
          .position.section,
      PawnRouteSection.mainTrack,
      reason: 'The AI must use its six to bring a pawn out of the yard.',
    );
    expect(controller.state.currentPlayerId, 'orange');
    expect(controller.state.pendingRoll, isNull);
    expect(
      rollIndex,
      6,
      reason: 'Green consumes its six bonus roll before Blue and Magenta pass.',
    );
  });



  testWidgets('restart requires confirmation and can be cancelled', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    final originalVersion = controller.state.version;
    await tester.tap(find.byKey(const ValueKey('restart_match_button')));
    await tester.pumpAndSettle();
    expect(find.text('Restart this match?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel_restart_button')));
    await tester.pumpAndSettle();
    expect(controller.state.version, originalVersion);

    await tester.tap(find.byKey(const ValueKey('restart_match_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_restart_button')));
    await tester.pumpAndSettle();
    expect(controller.state.version, greaterThan(originalVersion));
    expect(controller.state.completed, isFalse);
  });

  testWidgets('leaving a local match requires explicit confirmation', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: Text('Home destination')),
      ),
    );
    await tester.tap(find.text('Home destination'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Home destination'))).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalGameScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leave_match_button')));
    await tester.pumpAndSettle();
    expect(find.text('Leave this match?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel_leave_match_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('local_game_board')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('leave_match_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_leave_match_button')));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    expect(find.byKey(const ValueKey('local_game_board')), findsNothing);
  });


  testWidgets('pause menu freezes the match until the player resumes', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LocalGameController(nextDiceValue: () => 6);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LocalGameScreen(controller: controller),
      ),
    );

    final versionBeforePause = controller.state.version;
    await tester.tap(find.byKey(const ValueKey('pause_match_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('match_paused_dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('resume_match_button')), findsOneWidget);
    expect(controller.state.version, versionBeforePause);

    await tester.tap(find.byKey(const ValueKey('resume_match_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('match_paused_dialog')), findsNothing);
    expect(controller.state.version, versionBeforePause);
    expect(find.byKey(const ValueKey('roll_dice_button')), findsOneWidget);
  });

  testWidgets('players can choose an animal avatar for match recognition', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const LocalGameScreen(),
      ),
    );

    expect(find.byKey(const ValueKey('animal_avatar_orange')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose_animal_avatar_orange')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('animal_avatar_picker')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('animal_avatar_option_lion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('animal_avatar_picker')), findsNothing);
    expect(find.byKey(const ValueKey('animal_avatar_orange')), findsOneWidget);
    expect(find.text('🦁'), findsOneWidget);
    // Other players keep their own default animal identities.
    expect(find.text('🐸'), findsOneWidget);
    expect(find.text('🐼'), findsOneWidget);
    expect(find.text('🐱'), findsOneWidget);
  });

}
