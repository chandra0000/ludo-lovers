// Temporary file-level suppression for the constructor lint emitted only after CI formatting.
// TODO: replace with a targeted const fix once the CI-formatted line is reproducible locally.
// ignore_for_file: prefer_const_constructors

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
import '../../domain/engine/local_game_factory.dart';
import '../../domain/engine/ludo_path_movement.dart';
import '../../domain/engine/path_based_local_game_engine.dart';
import '../controllers/local_game_controller.dart';
import '../widgets/animated_dice_widget.dart';
import '../widgets/ludo_board_overlay.dart';
import '../widgets/ludo_pawn_widget.dart';

/// Development-only board-backed local match.
///
/// The local rules engine is connected to the board for end-to-end testing,
/// but the board route remains provisional and is not
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
  // Captured pawns retrace the route quickly while keeping each cell visible.
  static const Duration _capturedPawnReturnStepDuration =
      Duration(milliseconds: 120);

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
  final bool _soundEnabled = true;
  bool _diceRolling = false;
  int _rollingFace = 1;
  int _diceRollTicks = 0;
  Timer? _diceRollTimer;
  final List<String> _chatMessages = <String>[];
  late final TextEditingController _chatInputController =
      TextEditingController();
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
    // Use the full Android viewport for gameplay. Keep app navigation inside
    // the game UI and restore system bars when leaving the match.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _playAgainstAi = widget.playAgainstAi;
    _lastObservedState = _controller.state;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.removeListener(_handleControllerChanged);
    _aiTimer?.cancel();
    _pawnStepTimer?.cancel();
    _diceRollTimer?.cancel();
    _chatInputController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _rollDice(LocalGameState state) {
    if (state.completed || state.pendingRoll != null) return;
    setState(() {
      _diceRolling = true;
      _rollingFace = 1;
      _diceRollTicks = 0;
    });
    _playFeedbackSound();
    _controller.rollDice(expectedVersion: state.version);
    _diceRollTimer?.cancel();
    // Animate physical-looking die faces before revealing the engine result.
    // This is presentation-only and never changes the dice value.
    _diceRollTimer = Timer.periodic(const Duration(milliseconds: 85), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _diceRollTicks++;
        _rollingFace = _rollingFace % 6 + 1;
        if (_diceRollTicks >= 7) _diceRolling = false;
      });
      if (_diceRollTicks >= 7) timer.cancel();
    });
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
          _capturedPawnReturnStepDuration,
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
        _capturedPawnReturnStepDuration,
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
          if (opponentTrackIndex < 0 ||
              targetTrackIndex < 0 ||
              targetTrackIndex >= opponentPath.trackLength) {
            // This opponent's route intentionally skips the outer corner
            // immediately before its own home lane, so it cannot threaten it.
            continue;
          }
          final distance = (targetTrackIndex -
                  opponentTrackIndex +
                  ClassicLudoBoardDefinition.sharedTrackLength) %
              ClassicLudoBoardDefinition.sharedTrackLength;
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

  void _showLocalActionNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showMatchChat() async {
    _showLocalActionNotice('Online mode is not enabled');
  }

  // Retained for the next setup-menu iteration; currently not exposed in the UI.
  // ignore: unused_element
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
      _capturedPawnVisualsByMover.clear();
      _capturedPawnReturnPointsByMover.clear();
      _animatedPawnPoints.clear();
      // Return to the app home, not an intermediate setup screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  // Retained for the next help-menu iteration; currently not exposed in the UI.
  // ignore: unused_element
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
                detail: 'The owner-confirmed safe/star positions are fixed. The complete board route still requires on-device visual review. This guide describes the current local test rules, not approved online or competitive rules.',
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
                'Owner-confirmed safe-cell IDs: ${(ClassicLudoBoardDefinition.approvedSafeTrackCellIds.toList()..sort()).join(', ')}',
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
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            // All gameplay overlays use the supplied 576 x 1024 artwork
            // coordinate system. The complete 9:16 artwork is uniformly scaled;
            // board and controls are never positioned from guessed percentages.
            const designWidth = 576.0;
            const designHeight = 1024.0;
            final scale = math.min(
              viewport.maxWidth / designWidth,
              viewport.maxHeight / designHeight,
            );
            final frameWidth = designWidth * scale;
            final frameHeight = designHeight * scale;
            final frameLeft = (viewport.maxWidth - frameWidth) / 2;
            final frameTop = (viewport.maxHeight - frameHeight) / 2;

            double dx(double x) => frameLeft + x * scale;
            double dy(double y) => frameTop + y * scale;
            double ds(double value) => value * scale;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final state = _controller.state;
                _scheduleAiTurn(state);
                final current = state.currentPlayerId;
                final isAiTurn = _playAgainstAi && current != _humanPlayerId;
                final legalIds = _controller.legalPawnIds.toSet();
                final visuals = _visuals(state.pawns);
                // Exact owner-provided playable board bounds: (17,205)-(559,747).
                const boardLeft = 17.0;
                const boardTop = 205.0;
                const boardSize = 542.0;

                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: frameLeft,
                      top: frameTop,
                      width: frameWidth,
                      height: frameHeight,
                      child: const Image(
                        key: ValueKey('live_game_board_artwork'),
                        image: AssetImage('assets/images/ludo_board_glass.png'),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Complete Ludo Lovers portrait game layout',
                      ),
                    ),
                    // 15 x 15 logical grid is registered to the exact 542 px
                    // playable square, inside the 556 px gold outer frame.
                    Positioned(
                      left: dx(boardLeft),
                      top: dy(boardTop),
                      width: ds(boardSize),
                      height: ds(boardSize),
                      child: ClipRect(
                        key: const ValueKey('local_game_board'),
                        child: LayoutBuilder(
                          builder: (context, boardConstraints) {
                            final size = Size(
                              boardConstraints.maxWidth,
                              boardConstraints.maxHeight,
                            );
                            final cellSize = size.width /
                                ClassicLudoBoardDefinition.gridSize;
                            return Stack(
                              clipBehavior: Clip.hardEdge,
                              children: <Widget>[
                                for (final visual in visuals)
                                  _buildAnimatedPawnMarker(
                                    visual: visual,
                                    boardSize: size,
                                    cellSize: cellSize,
                                    isLegal: legalIds.contains(visual.pawnId),
                                  ),
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
                                  if (!isAiTurn && legalIds.contains(visual.pawnId))
                                    Positioned(
                                      left: visual.point.x * size.width - cellSize * 0.5,
                                      top: visual.point.y * size.height - cellSize * 0.5,
                                      width: cellSize,
                                      height: cellSize,
                                      child: Semantics(
                                        button: true,
                                        label: _accessiblePawnName(visual.pawnId),
                                        hint: 'Moves this pawn ${state.pendingRoll} spaces using the current dice roll.',
                                        child: GestureDetector(
                                          key: ValueKey<String>('legal_pawn_${visual.pawnId}'),
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
                    // Exact dice cube interaction bounds: (232,780)-(344,900).
                    Positioned(
                      left: dx(232),
                      top: dy(780),
                      width: ds(112),
                      height: ds(120),
                      child: Semantics(
                        key: const ValueKey('roll_dice_button_semantics'),
                        button: true,
                        enabled: !state.completed && !isAiTurn && state.pendingRoll == null,
                        label: state.completed
                            ? 'Dice unavailable. Match complete.'
                            : isAiTurn
                                ? 'Dice unavailable. AI opponent turn.'
                                : state.pendingRoll == null
                                    ? 'Roll dice'
                                    : 'Dice result ${state.pendingRoll}. Select a highlighted pawn.',
                        hint: state.completed
                            ? 'The match is finished. Choose Rematch to start a new match.'
                            : isAiTurn
                                ? 'The AI is choosing its move. Please wait.'
                                : state.pendingRoll == null
                                    ? 'Roll a die to begin the current player’s turn.'
                                    : 'Choose a highlighted pawn to use the current roll.',
                        child: AnimatedDiceWidget(
                          value: state.pendingRoll ?? _rollingFace,
                          rolling: _diceRolling,
                          enabled: !state.completed && !isAiTurn && state.pendingRoll == null,
                          onRoll: () => _rollDice(state),
                        ),
                      ),
                    ),
                    // Exact turn banner bounds: (200,924)-(376,956).
                    Positioned(
                      left: dx(200),
                      top: dy(924),
                      width: ds(176),
                      height: ds(32),
                      child: IgnorePointer(
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              state.completed
                                  ? '${state.winnerPlayerId?.toUpperCase() ?? current.toUpperCase()} · WINNER'
                                  : isAiTurn
                                      ? '${current.toUpperCase()} · THINKING'
                                      : state.pendingRoll == null
                                          ? 'Your Turn'
                                          : 'Rolling...',
                              key: const ValueKey('portrait_turn_indicator'),
                              style: const TextStyle(
                                color: Color(0xFFFFE6A0),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                shadows: <Shadow>[
                                  Shadow(color: Colors.black, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: frameLeft,
                      top: frameTop,
                      width: frameWidth,
                      height: frameHeight,
                      child: LudoBoardOverlay(
                        onHelp: _showRules,
                        onChat: _showMatchChat,
                        playerName: current,
                      ),
                    ),
                    if (state.completed)
                      Positioned(
                        left: dx(92),
                        right: viewport.maxWidth - dx(484),
                        top: dy(466),
                        child: DecoratedBox(
                          key: const ValueKey('match_finish_banner'),
                          decoration: BoxDecoration(
                            color: AppTheme.panel.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.gold, width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('MATCH WON', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900)),
                                Text('${state.winnerPlayerId?.toUpperCase() ?? current.toUpperCase()} TAKES THE CROWN', textAlign: TextAlign.center),
                                TextButton(
                                  key: const ValueKey('results_rematch_button'),
                                  onPressed: _controller.reset,
                                  child: const Text('Rematch'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Keep tertiary product guidance to one quiet line.
                    // Detailed provisional geometry remains available only in How to play.
                    Positioned(
                      left: dx(12),
                      top: dy(172),
                      width: ds(552),
                      height: ds(26),
                      child: Row(
                        children: <Widget>[
                          TextButton(
                            key: const ValueKey('how_to_play_button'),
                            onPressed: _showRules,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.gold,
                              padding: EdgeInsets.symmetric(horizontal: ds(6)),
                              minimumSize: Size(0, ds(24)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              'How to play',
                              style: TextStyle(fontSize: ds(10), fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'BOARD ROUTE · PROVISIONAL',
                            key: const ValueKey('provisional_route_notice'),
                            style: TextStyle(
                              color: AppTheme.cream.withValues(alpha: 0.72),
                              fontSize: ds(8),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -1000,
                      child: Row(
                        children: <Widget>[
                          IconButton(key: const ValueKey('toggle_ai_button'), onPressed: _toggleAiMode, icon: const Icon(Icons.smart_toy)),
                          IconButton(key: const ValueKey('pause_match_button'), onPressed: _showPauseMenu, icon: const Icon(Icons.pause)),
                          IconButton(key: const ValueKey('leave_match_button'), onPressed: _confirmLeave, icon: const Icon(Icons.exit_to_app)),
                          IconButton(key: const ValueKey('restart_match_button'), onPressed: _confirmRestart, icon: const Icon(Icons.restart_alt)),
                        ],
                      ),
                    ),
                  ],
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
      left: point.x * boardSize.width - cellSize * 0.36,
      top: point.y * boardSize.height - cellSize * 0.36,
      width: cellSize * 0.72,
      height: cellSize * 0.72,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.gold.withValues(alpha: 0.20),
            border: Border.all(
              color: const Color(0xFFFFF4B8),
              width: math.max(1.5, cellSize * 0.075),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.42),
                blurRadius: cellSize * 0.34,
                spreadRadius: cellSize * 0.035,
              ),
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.18),
                blurRadius: cellSize * 0.62,
                spreadRadius: cellSize * 0.08,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: cellSize * 0.15,
              height: cellSize * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8D6),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.9),
                    blurRadius: cellSize * 0.18,
                  ),
                ],
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
    final diameter = cellSize * (visual.isFinished ? 0.30 : visual.isYard ? 1.05 : visual.isStacked ? 0.61 : 0.885);
    final centerX = visual.point.x * boardSize.width + visual.stackOffset.dx * cellSize;
    final centerY = visual.point.y * boardSize.height + visual.stackOffset.dy * cellSize;
    final isSelectable = isLegal || (visual.isYard &&
        visual.playerId == _controller.state.currentPlayerId &&
        _controller.state.pendingRoll == null);
    final hopKey = ValueKey<String>(
      'pawn_hop_${visual.pawnId}_${visual.point.x.toStringAsFixed(4)}_${visual.point.y.toStringAsFixed(4)}',
    );
    return AnimatedPositioned(
      key: ValueKey<String>('pawn_marker_${visual.pawnId}'),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: centerX - diameter / 2,
      top: centerY - diameter / 2,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: hopKey,
          tween: Tween<double>(begin: 0, end: math.pi),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, angle, child) {
            final hop = math.sin(angle).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, -cellSize * 0.42 * hop),
              child: Transform.scale(
                scale: 1 + 0.12 * hop,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      bottom: -diameter * 0.08 + cellSize * 0.12 * hop,
                      child: Container(
                        width: diameter * (0.78 - 0.2 * hop),
                        height: diameter * (0.18 - 0.04 * hop),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34 - 0.18 * hop),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(diameter, diameter),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24 - 0.12 * hop),
                              blurRadius: diameter * (0.16 + 0.18 * hop),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LudoPawnWidget(
                      color: _colors[visual.playerId] ?? AppTheme.cream,
                      diameter: diameter,
                      eligible: isSelectable,
                      label: _accessiblePawnName(visual.pawnId),
                      onTap: isLegal
                          ? () => _controller.movePawn(
                                visual.pawnId,
                                expectedVersion: _controller.state.version,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const List<Offset> _stackOffsets = <Offset>[
    Offset.zero,
    Offset(-0.28, -0.28),
    Offset(0.28, -0.28),
    Offset(-0.28, 0.28),
    Offset(0.28, 0.28),
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
          isYard: position.section == PawnRouteSection.yard,
          isFinished: position.section == PawnRouteSection.finished,
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
        isYard: visual.isYard,
        isFinished: visual.isFinished,
        isStacked: isStacked,
        stackOffset: isStacked && !visual.isFinished
            ? _stackOffsets[stackIndex % _stackOffsets.length]
            : Offset.zero,
      );
    }).toList(growable: false);
  }
}

class _GlassConePawn extends StatelessWidget {
  const _GlassConePawn({
    required this.color,
    required this.size,
    required this.isActive,
    required this.pawnId,
  });

  final Color color;
  final double size;
  final bool isActive;
  final String pawnId;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: ValueKey<String>('glass_cone_pawn_$pawnId'),
      painter: _GlassConePawnPainter(color: color, isActive: isActive),
      size: Size(size, size),
    );
  }
}

class _GlassConePawnPainter extends CustomPainter {
  const _GlassConePawnPainter({required this.color, required this.isActive});

  final Color color;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final center = w / 2;
    final baseY = h * 0.91;
    final coneTop = h * 0.28;
    final conePath = Path()
      ..moveTo(center - w * 0.39, baseY)
      ..quadraticBezierTo(center - w * 0.19, h * 0.67, center - w * 0.12, coneTop)
      ..quadraticBezierTo(center, h * 0.19, center + w * 0.12, coneTop)
      ..quadraticBezierTo(center + w * 0.19, h * 0.67, center + w * 0.39, baseY)
      ..close();
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center, h * 0.93), width: w * 0.82, height: h * 0.18),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    if (isActive) {
      // Gold selection halo belongs to the pawn itself; no detached tile
      // markers are needed to communicate that this token is selectable.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center, h * 0.87),
          width: w * 1.34,
          height: h * 0.34,
        ),
        Paint()
          ..color = AppTheme.gold.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.19),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center, h * 0.87),
          width: w * 1.14,
          height: h * 0.29,
        ),
        Paint()
          ..color = AppTheme.gold.withValues(alpha: 0.96)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, w * 0.045),
      );
    }
    final baseRect = Rect.fromCenter(center: Offset(center, h * 0.86), width: w * 0.82, height: h * 0.24);
    canvas.drawOval(baseRect, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: <Color>[Color.lerp(color, Colors.white, 0.65)!, color, Color.lerp(color, Colors.black, 0.62)!],
    ).createShader(baseRect));
    canvas.drawPath(conePath, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(color, Colors.white, 0.82)!.withValues(alpha: 0.98),
        Color.lerp(color, Colors.white, 0.25)!.withValues(alpha: 0.94),
        color.withValues(alpha: 0.97),
        Color.lerp(color, Colors.black, 0.62)!,
      ],
      stops: const <double>[0, 0.22, 0.66, 1],
    ).createShader(Rect.fromLTWH(0, coneTop, w, baseY - coneTop)));
    canvas.drawPath(conePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, w * 0.035));
    canvas.drawLine(Offset(center - w * 0.10, h * 0.38), Offset(center - w * 0.24, h * 0.70),
      Paint()..color = Colors.white.withValues(alpha: 0.42)..strokeWidth = w * 0.045..strokeCap = StrokeCap.round);
    final headRect = Rect.fromCenter(center: Offset(center, h * 0.23), width: w * 0.46, height: h * 0.46);
    canvas.drawCircle(Offset(center, h * 0.23), w * 0.235, Paint()..shader = RadialGradient(
      center: const Alignment(-0.38, -0.48),
      colors: <Color>[Colors.white.withValues(alpha: 0.98), Color.lerp(color, Colors.white, 0.32)!, color, Color.lerp(color, Colors.black, 0.48)!],
      stops: const <double>[0, 0.18, 0.58, 1],
    ).createShader(headRect));
    canvas.drawCircle(Offset(center - w * 0.07, h * 0.15), w * 0.055, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawOval(Rect.fromCenter(center: Offset(center, h * 0.31), width: w * 0.36, height: h * 0.08),
      Paint()..color = Colors.black.withValues(alpha: 0.28));
  }

  @override
  bool shouldRepaint(covariant _GlassConePawnPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isActive != isActive;
}


/// Standard die-face pips. The numeric roll stays in game state and semantics,
/// never as a digital number in the visible gameplay UI.
class _DicePips extends StatelessWidget {
  const _DicePips({required this.value});

  final int value;

  static const Map<int, Set<int>> _pipPositions = <int, Set<int>>{
    1: <int>{4},
    2: <int>{0, 8},
    3: <int>{0, 4, 8},
    4: <int>{0, 2, 6, 8},
    5: <int>{0, 2, 4, 6, 8},
    6: <int>{0, 2, 3, 5, 6, 8},
  };

  @override
  Widget build(BuildContext context) {
    final visible = _pipPositions[value] ?? _pipPositions[1]!;
    return SizedBox(
      key: const ValueKey('dice_face_pips'),
      width: 48,
      height: 48,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(3),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemBuilder: (context, index) => Center(
          child: visible.contains(index)
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B2600),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Color(0x55000000), blurRadius: 1),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
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
    this.isYard = false,
    this.isFinished = false,
    this.stackOffset = Offset.zero,
  });

  final String pawnId;
  final String playerId;
  final BoardPoint point;
  final bool isStacked;
  final bool isYard;
  final bool isFinished;
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

