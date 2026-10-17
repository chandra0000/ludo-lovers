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
        title: const Text('Local Match Preview'),
        actions: <Widget>[
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
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight * 0.45,
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
                      _PlayerTurnStrip(
                        currentPlayerId: current,
                        pawns: state.pawns,
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
  });

  final String pawnId;
  final String playerId;
  final BoardPoint point;
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
