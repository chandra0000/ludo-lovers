import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/board/board_coordinate_layout.dart';
import '../../domain/board/board_pawn_layout.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_board_fixture.dart';
import '../../domain/board/classic_ludo_board_painter.dart';
import '../../domain/engine/local_game_factory.dart';
import '../../domain/engine/ludo_path_movement.dart';
import '../../domain/engine/path_based_local_game_engine.dart';
import '../controllers/local_game_controller.dart';

/// Development-only board-backed local match.
///
/// The local rules engine is connected to the board for end-to-end testing,
/// but the board route and safe-cell IDs remain provisional and are not
/// approved for release or competitive play.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({
    super.key,
    this.controller,
    this.selectedPlayerIds,
    this.playAgainstAi = false,
  });

  /// Optional controller injection for deterministic widget tests.
  final LocalGameController? controller;

  /// Seats chosen on the mode/setup screens. Defaults to four local seats.
  final List<String>? selectedPlayerIds;

  /// When true, Orange is the human seat and the remaining seats use local AI.
  final bool playAgainstAi;

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late final LocalGameController _controller = widget.controller ??
      LocalGameController(
        gameSetup: LocalGameFactory.create(
          allowProvisionalRoutes: true,
          selectedPlayerIds:
              widget.selectedPlayerIds ?? LocalGameFactory.playerIds,
        ),
      );
  late final BoardPawnLayout _pawnLayout = BoardPawnLayout(
    layout: ClassicLudoBoardCoordinateFactory.create(),
  );
  late final _paths = ClassicLudoBoardFixture.create();
  static const LudoPathMovement _movement = LudoPathMovement();

  Timer? _aiTimer;
  Timer? _pawnStepTimer;
  LocalGameState? _lastObservedState;
  final Map<String, BoardPoint> _animatedPawnPoints = <String, BoardPoint>{};
  final Map<String, Set<String>> _capturedPawnVisualsByMover = <String, Set<String>>{};
  final Map<String, Map<String, List<BoardPoint>>> _capturedPawnReturnPointsByMover =
      <String, Map<String, List<BoardPoint>>>{};
  int _pawnAnimationGeneration = 0;
  bool _playAgainstAi = false;
  bool _aiThinking = false;
  bool _soundEnabled = true;
  bool _isPaused = false;
  static const String _humanPlayerId = 'orange';

  static const Map<String, Color> _colors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  @override
  void initState() {
    super.initState();
    _playAgainstAi = widget.playAgainstAi;
    _lastObservedState = _controller.state;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _aiTimer?.cancel();
    _pawnStepTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _playFeedbackSound({bool important = false}) {
    if (!_soundEnabled) return;
    try {
      unawaited(SystemSound.play(
        important ? SystemSoundType.alert : SystemSoundType.click,
      ));
    } on Object {
      // Platform feedback sounds are best-effort; gameplay must not depend on audio.
    }
  }

  void _handleControllerChanged() {
    final previous = _lastObservedState;
    final current = _controller.state;
    _lastObservedState = current;
    final message = _controller.lastMessage ?? '';
    if (message.contains('DiceRolled')) _playFeedbackSound();
    if (message.contains('PawnCaptured') || message.contains('PawnFinished') ||
        message.contains('GameCompleted')) {
      _playFeedbackSound(important: true);
    }
    if (previous == null || !message.contains('PawnMoved')) return;

    final movingPlayerId = previous.currentPlayerId;

    final capturedPawnIds = <String>{};
    for (final oldPawn in previous.pawns) {
      if (oldPawn.playerId == movingPlayerId) continue;
      final newPawn = current.pawns.firstWhere(
        (pawn) => pawn.id == oldPawn.id,
        orElse: () => oldPawn,
      );
      if (oldPawn.position.section != PawnRouteSection.yard &&
          newPawn.position.section == PawnRouteSection.yard) {
        capturedPawnIds.add(oldPawn.id);
      }
    }

    for (final oldPawn in previous.pawns) {
      if (oldPawn.playerId != movingPlayerId) continue;
      final newPawn = current.pawns.firstWhere(
        (pawn) => pawn.id == oldPawn.id,
        orElse: () => oldPawn,
      );
      if (oldPawn.position.section != newPawn.position.section ||
          oldPawn.position.progress != newPawn.position.progress) {
        if (capturedPawnIds.isNotEmpty) {
          _capturedPawnVisualsByMover[oldPawn.id] = capturedPawnIds;
          final previousVisuals = _visuals(previous.pawns);
          final returnPointsByPawn = <String, List<BoardPoint>>{};
          for (final capturedPawnId in capturedPawnIds) {
            final capturedPawn = previous.pawns.firstWhere(
              (pawn) => pawn.id == capturedPawnId,
            );
            final capturedVisual = previousVisuals.firstWhere(
              (visual) => visual.pawnId == capturedPawnId,
            );
            // Keep the captured pawn at the capture cell until the attacker
            // finishes its own route animation. Then animate the captured pawn
            // backwards through every visited track cell before placing it in
            // its correct yard slot.
            _animatedPawnPoints[capturedPawnId] = capturedVisual.point;
            final progress = capturedPawn.position.progress;
            if (progress != null &&
                capturedPawn.position.section == PawnRouteSection.mainTrack) {
              final returnPoints = _movement.positionsBackToYard(
                path: _paths.forPlayer(capturedPawn.playerId),
                fromProgress: progress,
              ).map((position) => _pawnLayout.resolve(
                playerId: capturedPawn.playerId,
                pawnId: capturedPawn.id,
                position: position,
                yardSlot: _yardSlotForPawn(previous.pawns, capturedPawn),
              ).point).toList(growable: false);
              returnPointsByPawn[capturedPawnId] = returnPoints;
            }
          }
          _capturedPawnReturnPointsByMover[oldPawn.id] = returnPointsByPawn;
        }
        _animatePawnAlongRoute(previous, oldPawn, newPawn);
        return;
      }
    }
  }

  void _animatePawnAlongRoute(
    LocalGameState previous,
    LocalPawn oldPawn,
    LocalPawn newPawn,
  ) {
    _pawnStepTimer?.cancel();
    final generation = ++_pawnAnimationGeneration;
    final oldVisual = _visuals(previous.pawns).firstWhere(
      (visual) => visual.pawnId == oldPawn.id,
    );
    final points = <BoardPoint>[];
    final path = _paths.forPlayer(oldPawn.playerId);
    final oldProgress = oldPawn.position.progress;
    final newProgress = newPawn.position.progress;

    if (oldPawn.position.section == PawnRouteSection.yard) {
      final visual = _pawnLayout.resolve(
        playerId: newPawn.playerId,
        pawnId: newPawn.id,
        position: newPawn.position,
        yardSlot: 0,
      );
      points.add(visual.point);
    } else if (oldProgress != null && newProgress != null) {
      // Resolve every intermediate route position from the same pure movement
      // model used by the rules engine. This prevents captures near the branch
      // from visually teleporting the moving pawn into its home lane: it must
      // visit each remaining shared cell, then each home-lane cell in order.
      for (final position in _movement.positionsBetween(
        path: path,
        fromProgress: oldProgress,
        toProgress: newProgress,
      )) {
        points.add(_pawnLayout.resolve(
          playerId: newPawn.playerId,
          pawnId: newPawn.id,
          position: position,
          yardSlot: 0,
        ).point);
      }
    }

    if (points.isEmpty) return;
    setState(() => _animatedPawnPoints[newPawn.id] = oldVisual.point);
    var step = 0;
    void advanceStep() {
      if (!mounted || generation != _pawnAnimationGeneration) return;
      if (_isPaused) {
        _pawnStepTimer = Timer(const Duration(milliseconds: 100), advanceStep);
        return;
      }
      step++;
      if (step >= points.length) {
        setState(() {
          _animatedPawnPoints.remove(newPawn.id);
          _pawnStepTimer = null;
        });
        final returnPoints =
            _capturedPawnReturnPointsByMover.remove(newPawn.id) ??
                <String, List<BoardPoint>>{};
        if (returnPoints.isNotEmpty) {
          _animateCapturedPawnsBackToYard(
            returnPoints.entries.toList(growable: false),
            generation,
          );
        } else {
          setState(() {
            final capturedPawnIds =
                _capturedPawnVisualsByMover.remove(newPawn.id) ?? <String>{};
            for (final capturedPawnId in capturedPawnIds) {
              _animatedPawnPoints.remove(capturedPawnId);
            }
          });
        }
        return;
      }
      setState(() => _animatedPawnPoints[newPawn.id] = points[step]);
      _playFeedbackSound();
      _pawnStepTimer = Timer(const Duration(milliseconds: 320), advanceStep);
    }

    _playFeedbackSound(important: oldPawn.position.section == PawnRouteSection.yard);
    setState(() => _animatedPawnPoints[newPawn.id] = points.first);
    _pawnStepTimer = Timer(const Duration(milliseconds: 320), advanceStep);
  }

  int _yardSlotForPawn(List<LocalPawn> pawns, LocalPawn target) {
    var slot = 0;
    for (final pawn in pawns) {
      if (pawn.playerId != target.playerId) continue;
      if (pawn.id == target.id) return slot;
      slot++;
    }
    return 0;
  }

  void _animateCapturedPawnsBackToYard(
    List<MapEntry<String, List<BoardPoint>>> returns,
    int generation,
  ) {
    var pawnIndex = 0;
    void animateNextPawn() {
      if (!mounted || generation != _pawnAnimationGeneration) return;
      if (_isPaused) {
        _pawnStepTimer = Timer(const Duration(milliseconds: 100), animateNextPawn);
        return;
      }
      if (pawnIndex >= returns.length) {
        setState(() {
          for (final entry in returns) {
            _animatedPawnPoints.remove(entry.key);
          }
          _capturedPawnVisualsByMover.removeWhere(
            (moverId, _) => !_capturedPawnReturnPointsByMover.containsKey(moverId),
          );
        });
        _pawnStepTimer = null;
        return;
      }

      final entry = returns[pawnIndex++];
      final pawnId = entry.key;
      final points = entry.value;
      var step = 0;
      void advanceReturnStep() {
        if (!mounted || generation != _pawnAnimationGeneration) return;
        if (_isPaused) {
          _pawnStepTimer = Timer(const Duration(milliseconds: 100), advanceReturnStep);
          return;
        }
        if (step >= points.length) {
          animateNextPawn();
          return;
        }
        setState(() => _animatedPawnPoints[pawnId] = points[step++]);
        _pawnStepTimer = Timer(
          const Duration(milliseconds: 220),
          advanceReturnStep,
        );
      }

      if (points.isEmpty) {
        animateNextPawn();
        return;
      }
      setState(() => _animatedPawnPoints[pawnId] = points.first);
      step = 1;
      _pawnStepTimer = Timer(
        const Duration(milliseconds: 220),
        advanceReturnStep,
      );
    }

    animateNextPawn();
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
    if (_isPaused || !_playAgainstAi ||
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
          _isPaused ||
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

  void _showLocalActionNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showPlayerSetup() async {
    final currentPlayers = _controller.state.players;
    final selectedPlayers = <String>[
      if (currentPlayers.length == 2) ...currentPlayers else ...<String>['orange', 'green'],
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.panel,
          title: const Text('Two-player local match'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Choose two different pawn colours. Players take turns on this device.',
                style: TextStyle(color: AppTheme.readableText),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LocalGameFactory.playerIds.map((playerId) {
                  final selected = selectedPlayers.contains(playerId);
                  final color = _colors[playerId] ?? AppTheme.cream;
                  return ChoiceChip(
                    key: ValueKey('player_colour_$playerId'),
                    label: Text(playerId.toUpperCase()),
                    selected: selected,
                    avatar: CircleAvatar(backgroundColor: color, radius: 8),
                    selectedColor: color.withValues(alpha: 0.22),
                    side: BorderSide(
                      color: selected ? color : Colors.white24,
                      width: selected ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? color : AppTheme.readableText,
                      fontWeight: FontWeight.w800,
                    ),
                    onSelected: (_) {
                      setDialogState(() {
                        if (selected) {
                          selectedPlayers.remove(playerId);
                        } else if (selectedPlayers.length < 2) {
                          selectedPlayers.add(playerId);
                        }
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 10),
              Text(
                selectedPlayers.length == 2
                    ? 'Player 1: ${selectedPlayers[0].toUpperCase()} · Player 2: ${selectedPlayers[1].toUpperCase()}'
                    : 'Select exactly two colours (${selectedPlayers.length}/2 selected).',
                key: const ValueKey('selected_player_colours_summary'),
                style: const TextStyle(
                  color: AppTheme.readableText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('start_two_player_match_button'),
              onPressed: selectedPlayers.length != 2
                  ? null
                  : () {
                      _aiTimer?.cancel();
                      _aiTimer = null;
                      _aiThinking = false;
                      _pawnStepTimer?.cancel();
                      _pawnStepTimer = null;
                      _pawnAnimationGeneration++;
                      _animatedPawnPoints.clear();
                      _playAgainstAi = false;
                      _controller.configurePlayers(
                        List<String>.of(selectedPlayers),
                      );
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Start match'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestart() async {
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Restart this match?'),
        content: const Text(
          'The current local match will be reset and all pawn progress will be lost.',
          style: TextStyle(color: AppTheme.readableText),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey('cancel_restart_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep playing'),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_restart_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restart match'),
          ),
        ],
      ),
    );
    if (shouldRestart == true && mounted) {
      _controller.reset();
      _showLocalActionNotice('A new local match has started.');
    }
  }

  Future<void> _confirmLeave() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Leave this match?'),
        content: const Text(
          'Your current local match will end. You can start a new match from the home screen.',
          style: TextStyle(color: AppTheme.readableText),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey('cancel_leave_match_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay in match'),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_leave_match_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave match'),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) {
      _aiTimer?.cancel();
      _aiTimer = null;
      _pawnStepTimer?.cancel();
      _pawnStepTimer = null;
      _pawnAnimationGeneration++;
      Navigator.of(context).pop();
    }
  }

  Future<void> _showPauseMenu() async {
    if (_isPaused || !mounted) return;
    setState(() => _isPaused = true);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('match_paused_dialog'),
        backgroundColor: AppTheme.panel,
        title: const Text('Match paused'),
        content: const Text(
          'Take a break. Your local match and pawn positions will be kept.',
          style: TextStyle(color: AppTheme.readableText),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey('resume_match_button'),
            onPressed: () => Navigator.of(dialogContext).pop('resume'),
            child: const Text('Resume match'),
          ),
          TextButton(
            key: const ValueKey('pause_restart_match_button'),
            onPressed: () => Navigator.of(dialogContext).pop('restart'),
            child: const Text('Restart match'),
          ),
          TextButton(
            key: const ValueKey('pause_leave_match_button'),
            onPressed: () => Navigator.of(dialogContext).pop('leave'),
            child: const Text('Leave match'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _isPaused = false);
    if (choice == 'restart') {
      await _confirmRestart();
    } else if (choice == 'leave') {
      await _confirmLeave();
    } else {
      _scheduleAiTurn(_controller.state);
    }
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
            key: const ValueKey('player_setup_button'),
            tooltip: 'Choose two player colours',
            onPressed: _showPlayerSetup,
            icon: const Icon(Icons.people_alt_rounded),
          ),
          IconButton(
            key: const ValueKey('toggle_ai_button'),
            tooltip: _playAgainstAi ? 'Disable AI opponents' : 'Play against AI',
            onPressed: _controller.state.players.length == 4 &&
                    _controller.state.players.every(
                      (playerId) => LocalGameFactory.playerIds.contains(playerId),
                    )
                ? _toggleAiMode
                : null,
            color: _playAgainstAi ? AppTheme.gold : null,
            icon: const Icon(Icons.smart_toy_rounded),
          ),
          IconButton(
            key: const ValueKey('toggle_sound_button'),
            tooltip: _soundEnabled ? 'Mute sound effects' : 'Enable sound effects',
            onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
            color: _soundEnabled ? AppTheme.gold : null,
            icon: Icon(_soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          ),
          IconButton(
            key: const ValueKey('pause_match_button'),
            tooltip: 'Pause match',
            onPressed: _showPauseMenu,
            icon: const Icon(Icons.pause_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'How to play',
            onPressed: _showRules,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            key: const ValueKey('leave_match_button'),
            tooltip: 'Leave match',
            onPressed: _confirmLeave,
            icon: const Icon(Icons.exit_to_app_rounded),
          ),
          IconButton(
            key: const ValueKey('restart_match_button'),
            tooltip: 'Restart match',
            onPressed: _confirmRestart,
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
              constraints.maxHeight * 0.78,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              width: 8,
                              height: 34,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Compact seat strip inspired by the premium match-bar
                      // direction. Labels stay truthful: this is local play,
                      // not a claim that these seats are connected online.
                      Container(
                        key: const ValueKey('local_match_player_strip'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          children: state.players.map((playerId) {
                            final playerColor =
                                _colors[playerId] ?? AppTheme.cream;
                            final isCurrent = playerId == current;
                            final isHuman = _playAgainstAi && playerId == _humanPlayerId;
                            final isAiSeat = _playAgainstAi && !isHuman;
                            final seatLabel = _playAgainstAi
                                ? (isHuman ? 'YOU' : 'AI')
                                : 'LOCAL';
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? playerColor.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCurrent
                                          ? playerColor
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: isCurrent ? 1.2 : 0.7,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: playerColor,
                                        child: Icon(
                                          isAiSeat
                                              ? Icons.smart_toy_rounded
                                              : Icons.person_rounded,
                                          size: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        playerId.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: playerColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        seatLabel,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? playerColor
                                              : AppTheme.readableText,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
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
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          for (final player in <({String id, String name, String title, IconData avatar})>[
                            (id: 'orange', name: 'You', title: 'YOU', avatar: Icons.person_rounded),
                            (id: 'green', name: 'Green', title: _playAgainstAi ? 'BOT' : 'GREEN', avatar: _playAgainstAi ? Icons.smart_toy_rounded : Icons.person_outline_rounded),
                            (id: 'blue', name: 'Blue', title: _playAgainstAi ? 'BOT' : 'BLUE', avatar: _playAgainstAi ? Icons.smart_toy_rounded : Icons.person_outline_rounded),
                            (id: 'magenta', name: 'Magenta', title: _playAgainstAi ? 'BOT' : 'MAGENTA', avatar: _playAgainstAi ? Icons.smart_toy_rounded : Icons.person_outline_rounded),
                          ])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: player.id == 'magenta' ? 0 : 6,
                                ),
                                child: _MatchPlayerCard(
                                  key: ValueKey('match_player_${player.id}'),
                                  title: player.title,
                                  name: player.name,
                                  color: _colors[player.id]!,
                                  avatar: player.avatar,
                                  isActive: current == player.id,
                                  pawnsOut: state.pawns.where((pawn) =>
                                    pawn.playerId == player.id &&
                                    pawn.position.section != PawnRouteSection.yard).length,
                                ),
                              ),
                            ),
                        ],
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
                      const SizedBox(height: 4),
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
                                    // Keep the static board artwork on its own
                                    // layer while pawns and destination markers animate.
                                    const RepaintBoundary(
                                      child: CustomPaint(
                                        painter: ClassicLudoBoardPainter(),
                                      ),
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
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                        child: Row(
                          children: <Widget>[
                            _RoundActionButton(
                              icon: Icons.chat_bubble_rounded,
                              label: 'Chat',
                              color: AppTheme.gold,
                              onPressed: () => _showLocalActionNotice('Chat will be available in online rooms.'),
                            ),
                            const Spacer(),
                            Semantics(
                              key: const ValueKey('roll_dice_button_semantics'),
                              button: true,
                              enabled: !state.completed &&
                                  !isAiTurn &&
                                  state.pendingRoll == null,
                              label: state.completed
                                  ? 'Dice unavailable. Match complete.'
                                  : isAiTurn
                                      ? 'Dice unavailable. AI opponent turn.'
                                      : state.pendingRoll != null
                                          ? 'Dice result ${state.pendingRoll}. Select a highlighted pawn.'
                                          : 'Roll dice',
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
                                child: ElevatedButton(
                                  key: const ValueKey('roll_dice_button'),
                                  onPressed: state.completed || isAiTurn || state.pendingRoll != null
                                      ? null
                                      : () => _controller.rollDice(expectedVersion: state.version),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    disabledForegroundColor: const Color(0xFF3B2600),
                                    foregroundColor: const Color(0xFF3B2600),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(78, 78),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 78,
                                    height: 78,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: <Color>[Color(0xFFFFF0A6), Color(0xFFFFC928), Color(0xFFB97808)],
                                      ),
                                      border: Border.all(color: const Color(0xFFFFF4C4), width: 1.5),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(color: AppTheme.gold.withValues(alpha: 0.42), blurRadius: 24, spreadRadius: 1),
                                        BoxShadow(color: AppTheme.gold.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 260),
                                        child: (state.pendingRoll == null
                                                ? const Icon(
                                                    Icons.casino_rounded,
                                                    key: ValueKey('dice_idle'),
                                                    size: 44,
                                                    color: Color(0xFF3B2600),
                                                  )
                                                : Container(
                                                    key: ValueKey<String>(
                                                      'dice_result_${state.pendingRoll}',
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Semantics(
                                                      key: const ValueKey(
                                                        'dice_result_semantics',
                                                      ),
                                                      label:
                                                          'Dice result: ${state.pendingRoll}',
                                                      liveRegion: true,
                                                      excludeSemantics: true,
                                                      child: Text(
                                                        '${state.pendingRoll}',
                                                        style: const TextStyle(
                                                          color: Color(0xFF3B2600),
                                                          fontSize: 36,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                  ))
                                            ,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _RoundActionButton(
                              icon: Icons.emoji_emotions_rounded,
                              label: 'React',
                              color: AppTheme.magenta,
                              onPressed: () => _showLocalActionNotice('Reactions will be available in online rooms.'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.completed ? 'PLAY AGAIN' : isAiTurn ? 'OPPONENT’S TURN' : 'YOUR TURN',
                        key: const ValueKey('match_turn_caption'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: state.completed ? AppTheme.gold : (_colors[current] ?? AppTheme.gold), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4),
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
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.15,
              colors: <Color>[
                Color.lerp(_colors[visual.playerId] ?? AppTheme.cream, Colors.white, 0.48)!,
                _colors[visual.playerId] ?? AppTheme.cream,
                Color.lerp(_colors[visual.playerId] ?? AppTheme.cream, Colors.black, 0.34)!,
              ],
              stops: const <double>[0, 0.48, 1],
            ),
            border: Border.all(
              color: isLegal ? AppTheme.gold : AppTheme.cream.withValues(alpha: 0.9),
              width: cellSize * (isLegal ? 0.105 : 0.055),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.52),
                offset: Offset(0, cellSize * 0.10),
                blurRadius: cellSize * 0.14,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.28),
                offset: Offset(-cellSize * 0.035, -cellSize * 0.035),
                blurRadius: cellSize * 0.045,
              ),
              if (isLegal)
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.88),
                  blurRadius: cellSize * 0.34,
                  spreadRadius: cellSize * 0.045,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.favorite_rounded,
              color: AppTheme.cream,
              shadows: const <Shadow>[
                Shadow(color: Colors.black38, offset: Offset(0, 1.5), blurRadius: 2),
              ],
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
          point: _animatedPawnPoints[pawnId] ?? visual.point,
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

class _MatchPlayerCard extends StatelessWidget {
  const _MatchPlayerCard({
    super.key,
    required this.title,
    required this.name,
    required this.color,
    required this.avatar,
    required this.isActive,
    required this.pawnsOut,
  });

  final String title;
  final String name;
  final Color color;
  final IconData avatar;
  final bool isActive;
  final int pawnsOut;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: isActive ? 0.22 : 0.09),
            AppTheme.panel,
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.95 : 0.32),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 10),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.42),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 7),
              ],
            ),
            child: Icon(avatar, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              letterSpacing: 0.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'OUT $pawnsOut/4',
            maxLines: 1,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.label, required this.color, required this.onPressed});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: color.withValues(alpha: 0.65)),
                  boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12)],
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppTheme.mutedText, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
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

