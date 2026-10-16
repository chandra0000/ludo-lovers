import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/board/board_coordinate_layout.dart';
import '../../domain/board/board_pawn_layout.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_board_painter.dart';
import '../../domain/board/classic_ludo_pawn_layer.dart';
import '../../domain/engine/ludo_path_movement.dart';
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

  static const Map<String, Color> _colors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Match Preview'),
        actions: <Widget>[
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
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight * 0.57,
            );
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final state = _controller.state;
                final current = state.currentPlayerId;
                final legalIds = _controller.legalPawnIds.toSet();
                final visuals = _visuals(state.pawns);
                final markers = <BoardPawnMarker>[
                  for (final visual in visuals)
                    BoardPawnMarker(
                      // The override is authoritative for this visual marker;
                      // cellId remains a valid fallback for shared-track tests.
                      cellId: 0,
                      pawnId: visual.pawnId,
                      color: _colors[visual.playerId] ?? AppTheme.cream,
                      pointOverride: visual.point,
                      selected: legalIds.contains(visual.pawnId),
                    ),
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2011),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold),
                        ),
                        child: const Text(
                          'PROTOTYPE ONLY · The board route and safe cells are provisional. Test local turns here; do not treat this as release-ready gameplay.',
                          style: TextStyle(
                            color: AppTheme.cream,
                            fontSize: 11,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                  Text(
                                    state.completed
                                        ? 'MATCH COMPLETE'
                                        : '${current.toUpperCase()}’S TURN',
                                    style: TextStyle(
                                      color: _colors[current] ?? AppTheme.cream,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
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
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.panelRaised,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.gold),
                                ),
                                child: Text(
                                  '${state.pendingRoll}',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
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
                                    IgnorePointer(
                                      child: CustomPaint(
                                        painter: ClassicLudoPawnLayer(
                                          layout: _pawnLayout.layout,
                                          pawns: markers,
                                        ),
                                      ),
                                    ),
                                    for (final visual in visuals)
                                      if (legalIds.contains(visual.pawnId))
                                        Positioned(
                                          left: visual.point.x * size.width -
                                              cellSize * 0.48,
                                          top: visual.point.y * size.height -
                                              cellSize * 0.48,
                                          width: cellSize * 0.96,
                                          height: cellSize * 0.96,
                                          child: Semantics(
                                            button: true,
                                            label:
                                                'Move pawn ${visual.pawnId}',
                                            child: GestureDetector(
                                              key: ValueKey<String>(
                                                'legal_pawn_${visual.pawnId}',
                                              ),
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _controller
                                                  .movePawn(visual.pawnId),
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
                        child: ElevatedButton.icon(
                          key: const ValueKey('roll_dice_button'),
                          onPressed: state.completed ||
                                  state.pendingRoll != null
                              ? null
                              : _controller.rollDice,
                          icon: const Icon(Icons.casino_rounded),
                          label: const Text('Roll Dice'),
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
                        Text(
                          _controller.lastMessage!,
                          key: const ValueKey('last_game_action'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 11,
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
    return result;
  }
}

class _PawnVisual {
  const _PawnVisual({
    required this.pawnId,
    required this.playerId,
    required this.point,
  });

  final String pawnId;
  final String playerId;
  final BoardPoint point;
}
