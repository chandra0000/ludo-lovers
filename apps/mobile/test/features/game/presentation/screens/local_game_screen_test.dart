import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/engine/local_game_factory.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';
import 'package:ludo_lovers/features/game/domain/engine/path_based_local_game_engine.dart';
import 'package:ludo_lovers/features/game/presentation/controllers/local_game_controller.dart';
import 'package:ludo_lovers/features/game/presentation/screens/local_game_screen.dart';

void main() {
  testWidgets(
    'rolls, highlights a legal pawn, moves it, and preserves prototype warning',
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
      expect(find.byKey(const ValueKey('local_playtest_status')), findsOneWidget);
      expect(find.textContaining('Board route and safe cells are provisional'), findsOneWidget);

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
      expect(diceSwitcher.duration, const Duration(milliseconds: 300));
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
      expect(find.text('Rolled 6 · Tap a glowing pawn.'), findsOneWidget);
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
      expect(find.text('ORANGE’S TURN'), findsOneWidget);
      expect(find.text('OUT 1/4'), findsOneWidget);
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
      expect(find.text('GREEN’S TURN'), findsOneWidget);
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
      expect(find.text('GREEN’S TURN'), findsOneWidget);
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
      expect(find.text('GREEN’S TURN'), findsOneWidget);
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
    expect(find.text('MATCH COMPLETE'), findsOneWidget);
    expect(find.text('ORANGE wins!'), findsOneWidget);
    expect(find.byKey(const ValueKey('play_again_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('legal_pawn_orange_pawn_4')), findsNothing);
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('roll_dice_button')),
      ).onPressed,
      isNull,
      reason: 'A completed match must not accept another roll.',
    );

    await tester.tap(find.byKey(const ValueKey('play_again_button')));
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
    expect(find.text('ORANGE’S TURN'), findsOneWidget);
    expect(find.byKey(const ValueKey('play_again_button')), findsNothing);
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
      expect(find.text('GREEN’S TURN'), findsOneWidget);
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
      expect(find.text('OUT 1/4'), findsOneWidget);
      expect(find.text('GREEN’S TURN'), findsOneWidget);
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

    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Quick guide for this local prototype'), findsOneWidget);
    expect(find.text('Roll the dice'), findsOneWidget);
    expect(find.text('Choose a glowing pawn'), findsOneWidget);
    expect(find.text('Reach home exactly'), findsOneWidget);
    expect(
      find.textContaining(
        'The board route and safe-cell positions are still provisional',
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
      find.text('Provisional safe-cell IDs: 0, 8, 13, 21, 26, 34, 39, 47'),
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
    expect(find.byKey(const ValueKey('play_again_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('play_again_button')));
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


}
