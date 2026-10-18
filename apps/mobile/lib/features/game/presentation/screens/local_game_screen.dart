import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/board/board_coordinate_layout.dart';
import '../../domain/board/board_pawn_layout.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_board_fixture.dart';
import '../../domain/board/classic_ludo_board_painter.dart';
import '../../domain/engine/ludo_path_movement.dart';
import '../../domain/engine/path_based_local_game_engine.dart';
import '../controllers/local_game_controller.dart';

/// Development-only board-backed local match.
///
/// The local rules engine is connected to the board for end-to-end testing,
/// but the board route and safe-cell IDs remain provisional and are not
/// approved for release or competitive play.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key, this.controller});

  /// Optional controller injection for deterministic widget tests.
  final LocalGameController? controller;

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late final LocalGameController _controller =
      widget.controller ?? LocalGameController();
  late final BoardPawnLayout _pawnLayout = BoardPawnLayout(
    layout: ClassicLudoBoardCoordinateFactory.create(),
  );
  late final _paths = ClassicLudoBoardFixture.create();
  static const LudoPathMovement _movement = LudoPathMovement();

  Timer? _aiTimer;
  bool _playAgainstAi = false;
  bool _aiThinking = false;
  static const String _humanPlayerId = 'orange';

  static const Map<String, Color> _colors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  @override
  void dispose() {
    _aiTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _toggleAiMode() {
    setState(() {
      _playAgainstAi = !_playAgainstAi;
      _aiTimer?.cancel();
      _aiTimer = null;
    });
    _scheduleAiTurn(_controller.state);
  }

  void _scheduleAiTurn(LocalGameState state) {
    if (!_playAgainstAi ||
        state.completed ||
        state.currentPlayerId == _humanPlayerId ||
        _aiThinking ||
        _aiTimer != null) {
      return;
    }

    final expectedPlayerId = state.currentPlayerId;
    _aiTimer = Timer(const Duration(milliseconds: 420), () {
      _aiTimer = null;
      if (!mounted ||
          !_playAgainstAi ||
          _controller.state.completed ||
          _controller.state.currentPlayerId != expectedPlayerId) {
        return;
      }

      _aiThinking = true;
      try {
        final beforeRoll = _controller.state;
        if (beforeRoll.pendingRoll == null) {
          _controller.rollDice(expectedVersion: beforeRoll.version);
        }

        final afterRoll = _controller.state;
        if (!afterRoll.completed &&
            afterRoll.currentPlayerId == expectedPlayerId &&
            afterRoll.pendingRoll != null) {
          final legalIds = _controller.legalPawnIds;
          if (legalIds.isNotEmpty) {
            final selectedPawnId = _chooseAiPawn(legalIds, afterRoll);
            _controller.movePawn(
              selectedPawnId,
              expectedVersion: afterRoll.version,
            );
          }
        }
      } finally {
        _aiThinking = false;
        _scheduleAiTurn(_controller.state);
      }
    });
  }

  String _chooseAiPawn(List<String> legalPawnIds, LocalGameState state) {
    String bestPawnId = legalPawnIds.first;
    var bestScore = -1 << 30;

    for (final pawnId in legalPawnIds) {
      final pawn = state.pawns.firstWhere((item) => item.id == pawnId);
      final path = _paths.forPlayer(pawn.playerId);
      final resolution = _movement.resolve(
        path: path,
        current: pawn.position,
        diceValue: state.pendingRoll!,
        sixRequiredToEnter: _controller.setup.engine.sixRequiredToEnter,
        requireExactFinishRoll:
            _controller.setup.engine.requireExactFinishRoll,
      );
      final move = resolution.resolution;
      if (move == null) continue;

      var score = 0;
      if (move.finishes) {
        score += 10000;
      } else if (pawn.position.section == PawnRouteSection.yard) {
        score += 1500;
      } else if (move.position.section == PawnRouteSection.homeLane) {
        score += 1200 + (move.position.progress ?? 0);
      } else {
        score += (move.position.progress ?? 0) * 10;
      }

      final destinationCell = move.destinationCell;
      if (destinationCell != null &&
          move.position.section == PawnRouteSection.mainTrack &&
          !_controller.setup.engine.safeCellIndexes.contains(destinationCell)) {
        final captures = state.pawns.where((opponent) {
          if (opponent.playerId == pawn.playerId ||
              opponent.position.section != PawnRouteSection.mainTrack) {
            return false;
          }
          final opponentProgress = opponent.position.progress;
          if (opponentProgress == null) return false;
          return _paths
                  .forPlayer(opponent.playerId)
                  .cellAtProgress(opponentProgress) ==
              destinationCell;
        }).length;
        score += captures * 5000;
      }

      // Prefer a safe landing when an opponent could reach this cell
      // with a single ordinary roll. This is a heuristic, not a guarantee:
      // the opponent may not roll the required value next turn.
      if (destinationCell != null &&
          move.position.section == PawnRouteSection.mainTrack &&
          !_controller.setup.engine.safeCellIndexes.contains(destinationCell)) {
        var threateningOpponents = 0;
        for (final opponent in state.pawns) {
          if (opponent.playerId == pawn.playerId ||
              opponent.position.section != PawnRouteSection.mainTrack) {
            continue;
          }
          final opponentProgress = opponent.position.progress;
          if (opponentProgress == null) continue;
          final opponentPath = _paths.forPlayer(opponent.playerId);
          if (opponentProgress >= opponentPath.trackLength) continue;
          final opponentCell = opponentPath.cellAtProgress(opponentProgress);
          if (opponentCell == null) continue;
          final opponentTrackIndex =
              opponentPath.mainTrackCells.indexOf(opponentCell);
          final targetTrackIndex =
              opponentPath.mainTrackCells.indexOf(destinationCell);
          if (opponentTrackIndex < 0 || targetTrackIndex < 0) continue;
          final distance = (targetTrackIndex -
                  opponentTrackIndex +
                  opponentPath.trackLength) %
              opponentPath.trackLength;
          if (distance >= 1 && distance <= 6) {
            threateningOpponents++;
          }
        }
        score -= threateningOpponents * 850;
      }

      if (score > bestScore) {
        bestScore = score;
        bestPawnId = pawnId;
      }
    }
    return bestPawnId;
  }

  String _accessiblePawnName(String pawnId) {
    final parts = pawnId.split('_');
    final playerId = parts.isNotEmpty ? parts.first : pawnId;
    final pawnNumber = parts.isNotEmpty ? parts.last : '';
    final playerName = switch (playerId) {
      'orange' => 'Orange',
      'green' => 'Green',
      'blue' => 'Blue',
      'magenta' => 'Magenta',
      _ => playerId,
    };
    return '$playerName pawn $pawnNumber';
  }

  String? _friendlyActionFeedback(LocalGameState state) {
    final message = _controller.lastMessage;
    if (message == null) return null;
    if (state.completed || message.contains('GameCompleted')) {
      return '${(state.winnerPlayerId ?? state.currentPlayerId).toUpperCase()} wins the match!';
    }
    if (message.contains('PawnCaptured')) {
      return 'Brilliant capture! An opponent pawn returns to the yard.';
    }
    if (message.contains('PawnFinished')) {
      return 'Home at last! Your pawn reached the centre.';
    }
    if (message.contains('NoLegalMove') && message.contains('ExtraRollGranted')) {
      return 'No legal move this time, but you earned another roll.';
    }
    if (message.contains('ExtraRollGranted')) {
      return 'Bonus roll unlocked — it is still your turn.';
    }
    if (message.contains('NoLegalMove')) {
      return 'No legal moves. Your turn has passed.';
    }
    if (message.contains('DiceRolled')) {
      return state.pendingRoll == null
          ? 'No move available for that roll.'
          : 'You rolled ${state.pendingRoll}. Choose a glowing pawn.';
    }
    if (message.contains('PawnMoved')) {
      return 'Pawn moved. Keep the momentum going!';
    }
    if (message.contains('TurnEnded')) {
      return 'Turn complete. The next player is up.';
    }
    return null;
  }

  void _showRules() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'How to play',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quick guide for this local prototype',
                style: TextStyle(color: AppTheme.readableText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const _RuleRow(
                number: '1',
                title: 'Roll the dice',
                detail: 'Tap Roll Dice when it is your turn. A six is required to bring a pawn out of the yard.',
              ),
              const _RuleRow(
                number: '2',
                title: 'Choose a glowing pawn',
                detail: 'After a roll, only pawns marked with a gold ring can be moved.',
              ),
              const _RuleRow(
                number: '3',
                title: 'Earn another roll',
                detail: 'In this provisional rules profile, rolling a six grants another roll. Captures and finishing may also grant one.',
              ),
              const _RuleRow(
                number: '4',
                title: 'Reach home exactly',
                detail: 'A pawn must reach the final home position with an exact roll; an overshoot is not allowed.',
              ),
              const _RuleRow(
                number: '5',
                title: 'Prototype warning',
                detail: 'The board route and safe-cell positions are still provisional. This guide describes the current local test rules, not approved online or competitive rules.',
              ),
              const SizedBox(height: 16),
              Text(
                'Board geometry review',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'These four diagonal corner links match the independent reference cross-check. The full board artwork and safe-cell placement still need visual approval:',
                style: TextStyle(
                  color: AppTheme.readableText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final index
                  in ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.panelRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ClassicLudoBoardCoordinateFactory.describeTransition(index),
                      style: const TextStyle(
                        color: AppTheme.cream,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Provisional entries',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              for (final seat in ClassicLudoBoardDefinition.seats)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${seat.id.toUpperCase()} · track entry ${seat.provisionalTrackEntryIndex}',
                    style: const TextStyle(
                      color: AppTheme.readableText,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Provisional safe-cell IDs: ${(ClassicLudoBoardDefinition.provisionalSafeTrackCellIds.toList()..sort()).join(', ')}',
                key: const ValueKey('provisional_safe_cell_ids'),
                style: const TextStyle(
                  color: AppTheme.readableText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Back to match'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ludo Lovers · Match'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey('toggle_ai_button'),
            tooltip: _playAgainstAi ? 'Disable AI opponents' : 'Play against AI',
            onPressed: _toggleAiMode,
            color: _playAgainstAi ? AppTheme.gold : null,
            icon: const Icon(Icons.smart_toy_rounded),
          ),
          IconButton(
            tooltip: 'How to play',
            onPressed: _showRules,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: 'Restart match',
            onPressed: _controller.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The scroll view applies 10 px of horizontal padding on
            // each side, so size the board against its usable content width.
            final boardSize = math.min(
              math.max(0.0, constraints.maxWidth - 20),
              constraints.maxHeight * 0.62,
            );
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final state = _controller.state;
                _scheduleAiTurn(state);
                final current = state.currentPlayerId;
                final isAiTurn =
                    _playAgainstAi && current != _humanPlayerId;
                final legalIds = _controller.legalPawnIds.toSet();
                final visuals = _visuals(state.pawns);
                final actionFeedback = _friendlyActionFeedback(state);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.42),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 12,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _colors[current] ?? AppTheme.cream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Semantics(
                                    key: const ValueKey('turn_status_semantics'),
                                    liveRegion: true,
                                    excludeSemantics: true,
                                    label: state.completed
                                        ? 'Match complete. ${state.winnerPlayerId?.toUpperCase() ?? current.toUpperCase()} wins.'
                                        : '${current.toUpperCase()} player turn.',
                                    child: Text(
                                      state.completed
                                          ? 'MATCH COMPLETE'
                                          : '${current.toUpperCase()}’S TURN',
                                      style: TextStyle(
                                        color: _colors[current] ?? AppTheme.cream,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    state.completed
                                        ? '${state.winnerPlayerId?.toUpperCase() ?? current.toUpperCase()} wins!'
                                        : state.pendingRoll == null
                                            ? 'Roll the dice to start your turn.'
                                            : 'Rolled ${state.pendingRoll} · Tap a glowing pawn.',
                                    style: const TextStyle(
                                      color: AppTheme.readableText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (state.pendingRoll != null)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.55,
                                      end: 1,
                                    ).animate(animation),
                                    child: RotationTransition(
                                      turns: Tween<double>(
                                        begin: -0.08,
                                        end: 0,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  key: ValueKey<String>(
                                    'dice_result_${state.pendingRoll}',
                                  ),
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.panelRaised,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.gold),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppTheme.gold.withValues(alpha: 0.18),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Semantics(
                                    key: const ValueKey('dice_result_semantics'),
                                    label: 'Dice result: ${state.pendingRoll}',
                                    liveRegion: true,
                                    excludeSemantics: true,
                                    child: Text(
                                      '${state.pendingRoll}',
                                      style: const TextStyle(
                                        color: AppTheme.gold,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.92, end: 1).animate(
                              animation,
                            ),
                            child: child,
                          ),
                        ),
                        child: state.completed
                            ? Container(
                                key: const ValueKey('match_finish_banner'),
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      AppTheme.gold.withValues(alpha: 0.22),
                                      AppTheme.panelRaised,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.gold,
                                    width: 1.4,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(alpha: 0.12),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      color: AppTheme.gold,
                                      size: 34,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'MATCH WON',
                                            style: TextStyle(
                                              color: AppTheme.gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${state.winnerPlayerId?.toUpperCase() ?? current.toUpperCase()} TAKES THE CROWN',
                                            key: const ValueKey('match_winner_title'),
                                            style: const TextStyle(
                                              color: AppTheme.cream,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'A brilliant finish. Ready for a rematch?',
                                            style: TextStyle(
                                              color: AppTheme.readableText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('match_finish_banner_hidden'),
                              ),
                      ),
                      const SizedBox(height: 8),
                      _PlayerTurnStrip(
                        currentPlayerId: current,
                        pawns: state.pawns,
                      ),
                      if (_playAgainstAi) ...<Widget>[
                        const SizedBox(height: 6),
                        const Text(
                          'AI OPPONENTS ON · YOU PLAY ORANGE',
                          key: ValueKey('ai_mode_status'),
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        key: const ValueKey('local_playtest_status'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.32),
                          ),
                        ),
                        child: const Text(
                          'LOCAL PLAYTEST · Board route and safe cells are provisional. '
                          'Use this build to test interactions, not competitive rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.readableText,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          key: const ValueKey('local_game_board'),
                          width: boardSize,
                          height: boardSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LayoutBuilder(
                              builder: (context, boardConstraints) {
                                final size = Size(
                                  boardConstraints.maxWidth,
                                  boardConstraints.maxHeight,
                                );
                                final cellSize = size.shortestSide /
                                    ClassicLudoBoardDefinition.gridSize;
                                return Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    const CustomPaint(
                                      painter: ClassicLudoBoardPainter(),
                                    ),
                                    for (final visual in visuals)
                                      _buildAnimatedPawnMarker(
                                        visual: visual,
                                        boardSize: size,
                                        cellSize: cellSize,
                                        isLegal: legalIds.contains(visual.pawnId),
                                      ),
                                    // Preview each legal move's destination using
                                    // the same pure movement resolver as the engine.
                                    // This is an aid for local testing, not route approval.
                                    if (state.pendingRoll != null)
                                      for (final visual in visuals)
                                        if (legalIds.contains(visual.pawnId))
                                          _buildDestinationMarker(
                                            visual: visual,
                                            statePawns: state.pawns,
                                            diceValue: state.pendingRoll!,
                                            boardSize: size,
                                            cellSize: cellSize,
                                          ),
                                    for (final visual in visuals)
                                      if (!isAiTurn &&
                                          legalIds.contains(visual.pawnId))
                                        Positioned(
                                          left: visual.point.x * size.width -
                                              cellSize * 0.48,
                                          top: visual.point.y * size.height -
                                              cellSize * 0.48,
                                          width: cellSize * 0.96,
                                          height: cellSize * 0.96,
                                          child: Semantics(
                                            button: true,
                                            label: _accessiblePawnName(visual.pawnId),
                                            hint: 'Moves this pawn ${state.pendingRoll} spaces using the current dice roll.',
                                            child: GestureDetector(
                                              key: ValueKey<String>(
                                                'legal_pawn_${visual.pawnId}',
                                              ),
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _controller.movePawn(
                                                visual.pawnId,
                                                expectedVersion: state.version,
                                              ),
                                              child: const SizedBox.expand(),
                                            ),
                                          ),
                                        ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          key: const ValueKey('roll_dice_button_semantics'),
                          hint: state.completed
                              ? 'The match is finished. Choose Play Again to start a new match.'
                              : isAiTurn
                              ? 'The AI is choosing its move. Please wait.'
                              : state.pendingRoll != null
                              ? 'Choose a highlighted pawn to use the current roll.'
                              : 'Roll a die to begin the current player’s turn.',
                          child: Tooltip(
                            message: state.pendingRoll != null
                                ? 'Choose a highlighted pawn to use the current roll.'
                                : isAiTurn
                                ? 'AI is choosing its move…'
                                : 'Roll a die to begin the current player’s turn.',
                            child: ElevatedButton.icon(
                            key: const ValueKey('roll_dice_button'),
                            onPressed: state.completed ||
                                    isAiTurn ||
                                    state.pendingRoll != null
                                ? null
                                : () => _controller.rollDice(
                                      expectedVersion: state.version,
                                    ),
                            icon: const Icon(Icons.casino_rounded),
                              label: const Text('Roll Dice'),
                            ),
                          ),
                        ),
                      ),
                      if (state.completed) ...<Widget>[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('play_again_button'),
                            onPressed: _controller.reset,
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Play Again'),
                          ),
                        ),
                      ],
                      if (_controller.lastMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          key: const ValueKey('last_game_action_semantics'),
                          child: Text(
                            _controller.lastMessage!,
                            key: const ValueKey('last_game_action'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (actionFeedback != null) ...<Widget>[
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            key: ValueKey<String>('local_action_feedback_$actionFeedback'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  actionFeedback.contains('capture')
                                      ? Icons.flash_on_rounded
                                      : actionFeedback.contains('Home at last')
                                          ? Icons.home_rounded
                                          : actionFeedback.contains('Bonus roll')
                                              ? Icons.casino_rounded
                                              : actionFeedback.contains('wins the match')
                                                  ? Icons.emoji_events_rounded
                                                  : Icons.auto_awesome_rounded,
                                  key: const ValueKey('local_action_feedback_icon'),
                                  color: AppTheme.gold,
                                  size: 18,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Semantics(
                                    key: const ValueKey('local_action_feedback_semantics'),
                                    label: actionFeedback,
                                    liveRegion: true,
                                    child: Text(
                                      actionFeedback,
                                      key: const ValueKey('local_action_feedback'),
                                      style: const TextStyle(
                                        color: AppTheme.cream,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_controller.lastError != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'Action rejected: ${_controller.lastError!.error.name}',
                          style: const TextStyle(
                            color: AppTheme.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Glowing gold rings mark legal pawns. Tap one to move it. If no pawn glows after a roll, the engine advances the turn automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationMarker({
    required _PawnVisual visual,
    required List<dynamic> statePawns,
    required int diceValue,
    required Size boardSize,
    required double cellSize,
  }) {
    final pawn = statePawns.cast<dynamic>().firstWhere(
          (candidate) => candidate?.id == visual.pawnId,
          orElse: () => null,
        );
    if (pawn == null) return const SizedBox.shrink();

    final result = _movement.resolve(
      path: _paths.forPlayer(pawn.playerId as String),
      current: pawn.position as PawnRoutePosition,
      diceValue: diceValue,
      sixRequiredToEnter: _controller.setup.engine.sixRequiredToEnter,
      requireExactFinishRoll:
          _controller.setup.engine.requireExactFinishRoll,
    );
    final destinationCell = result.resolution?.destinationCell;
    if (destinationCell == null) return const SizedBox.shrink();

    final point = _pawnLayout.layout.forCell(destinationCell);
    return Positioned(
      key: ValueKey<String>('destination_cell_${destinationCell}_${visual.pawnId}'),
      left: point.x * boardSize.width - cellSize * 0.31,
      top: point.y * boardSize.height - cellSize * 0.31,
      width: cellSize * 0.62,
      height: cellSize * 0.62,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.gold.withValues(alpha: 0.16),
            border: Border.all(color: AppTheme.gold, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.28),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: cellSize * 0.12,
              height: cellSize * 0.12,
              decoration: const BoxDecoration(
                color: AppTheme.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPawnMarker({
    required _PawnVisual visual,
    required Size boardSize,
    required double cellSize,
    required bool isLegal,
  }) {
    final diameter = cellSize * (visual.isStacked ? 0.5 : 0.68);
    final centerX = visual.point.x * boardSize.width +
        visual.stackOffset.dx * cellSize;
    final centerY = visual.point.y * boardSize.height +
        visual.stackOffset.dy * cellSize;

    return AnimatedPositioned(
      key: ValueKey<String>('pawn_marker_${visual.pawnId}'),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: centerX - diameter / 2,
      top: centerY - diameter / 2,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _colors[visual.playerId] ?? AppTheme.cream,
            border: Border.all(
              // Make the current player's legal choices unmistakable on a
              // small phone: a broad gold ring plus a high-contrast halo.
              color: isLegal ? AppTheme.gold : AppTheme.cream,
              width: cellSize * (isLegal ? 0.105 : 0.055),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                offset: Offset(0, cellSize * 0.07),
                blurRadius: cellSize * 0.12,
              ),
              if (isLegal) ...<BoxShadow>[
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.95),
                  blurRadius: cellSize * 0.38,
                  spreadRadius: cellSize * 0.055,
                ),
                BoxShadow(
                  color: AppTheme.cream.withValues(alpha: 0.9),
                  blurRadius: cellSize * 0.12,
                  spreadRadius: cellSize * 0.015,
                ),
              ],
            ],
          ),
          child: Center(
            child: Icon(
              Icons.favorite_rounded,
              color: AppTheme.cream,
              size: diameter * 0.54,
            ),
          ),
        ),
      ),
    );
  }

  static const List<Offset> _stackOffsets = <Offset>[
    Offset.zero,
    Offset(-0.19, -0.19),
    Offset(0.19, -0.19),
    Offset(-0.19, 0.19),
    Offset(0.19, 0.19),
  ];

  List<_PawnVisual> _visuals(List<dynamic> pawns) {
    final result = <_PawnVisual>[];
    final yardSlots = <String, int>{};
    for (final dynamic pawn in pawns) {
      final position = pawn.position as PawnRoutePosition;
      final playerId = pawn.playerId as String;
      final pawnId = pawn.id as String;
      final yardSlot = yardSlots.update(
        playerId,
        (slot) => slot + 1,
        ifAbsent: () => 0,
      );
      final visual = _pawnLayout.resolve(
        playerId: playerId,
        pawnId: pawnId,
        position: position,
        yardSlot: yardSlot,
      );
      result.add(
        _PawnVisual(
          pawnId: pawnId,
          playerId: playerId,
          point: visual.point,
        ),
      );
    }

    return result.map((visual) {
      final occupants = result
          .where(
            (candidate) =>
                candidate.point.x == visual.point.x &&
                candidate.point.y == visual.point.y,
          )
          .toList(growable: false);
      final stackIndex = occupants.indexWhere(
        (candidate) => candidate.pawnId == visual.pawnId,
      );
      final isStacked = occupants.length > 1;
      return _PawnVisual(
        pawnId: visual.pawnId,
        playerId: visual.playerId,
        point: visual.point,
        isStacked: isStacked,
        stackOffset: isStacked
            ? _stackOffsets[stackIndex % _stackOffsets.length]
            : Offset.zero,
      );
    }).toList(growable: false);
  }
}

class _PlayerTurnStrip extends StatelessWidget {
  const _PlayerTurnStrip({
    required this.currentPlayerId,
    required this.pawns,
  });

  final String currentPlayerId;
  final List<dynamic> pawns;

  static const List<String> _playerIds = <String>[
    'orange',
    'green',
    'blue',
    'magenta',
  ];

  static const Map<String, Color> _colors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'TURN ORDER',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            for (final playerId in _playerIds)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: playerId == _playerIds.last ? 0 : 6,
                  ),
                  child: _PlayerTurnTile(
                    playerId: playerId,
                    color: _colors[playerId]!,
                    isCurrent: playerId == currentPlayerId,
                    pawnsOut: pawns.where((dynamic pawn) {
                      final position = pawn.position as PawnRoutePosition;
                      return pawn.playerId == playerId &&
                          position.section != PawnRouteSection.yard;
                    }).length,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlayerTurnTile extends StatelessWidget {
  const _PlayerTurnTile({
    required this.playerId,
    required this.color,
    required this.isCurrent,
    required this.pawnsOut,
  });

  final String playerId;
  final Color color;
  final bool isCurrent;
  final int pawnsOut;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${playerId.toUpperCase()}, ${isCurrent ? 'current turn' : 'waiting'}, $pawnsOut of 4 pawns out',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.13) : AppTheme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? color : AppTheme.gold.withValues(alpha: 0.18),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              playerId.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrent ? color : AppTheme.readableText,
                fontSize: 9,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'OUT $pawnsOut/4',
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PawnVisual {
  const _PawnVisual({
    required this.pawnId,
    required this.playerId,
    required this.point,
    this.isStacked = false,
    this.stackOffset = Offset.zero,
  });

  final String pawnId;
  final String playerId;
  final BoardPoint point;
  final bool isStacked;
  final Offset stackOffset;
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.7)),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.readableText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

