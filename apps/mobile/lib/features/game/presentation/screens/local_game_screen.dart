import 'package:flutter/material.dart';

import '../controllers/local_game_controller.dart';

/// Development screen for exercising local game state transitions.
/// The rendered board is not connected until board geometry is approved.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late final LocalGameController _controller = LocalGameController();

  static const Map<String, Color> _colors = <String, Color>{
    'orange': Color(0xFFFF8928),
    'green': Color(0xFF33FF28),
    'blue': Color(0xFF289EFF),
    'magenta': Color(0xFFF428FF),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Game Lab'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset game',
            onPressed: _controller.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          final current = state.currentPlayerId;
          final legal = _controller.legalPawnIds.toSet();
          final currentPawns = state.pawns
              .where((pawn) => pawn.playerId == current)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2011),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: const Text(
                  'DEVELOPMENT ONLY — board route is provisional. This screen tests engine transitions; it is not a production-ready playable board.',
                  style: TextStyle(color: Color(0xFFFFF8E1), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Current turn: ${current.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _colors[current],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Players: ${state.players.length} · Pawns: ${state.pawns.length}',
                      ),
                      Text('State version: ${state.version}'),
                      Text(
                        state.completed
                            ? 'Winner: ${state.winnerPlayerId ?? 'Unknown'}'
                            : state.pendingRoll == null
                                ? 'Roll the dice to begin your turn.'
                                : 'Dice result: ${state.pendingRoll}',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              state.completed || state.pendingRoll != null
                                  ? null
                                  : _controller.rollDice,
                          icon: const Icon(Icons.casino_rounded),
                          label: const Text('Roll Dice'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pawns for ${current.toUpperCase()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final pawn in currentPawns)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.favorite_rounded,
                      color: _colors[pawn.playerId],
                    ),
                    title: Text(pawn.id),
                    subtitle: Text(_controller.pawnLabel(pawn)),
                    trailing: legal.contains(pawn.id)
                        ? const Icon(
                            Icons.touch_app_rounded,
                            color: Color(0xFFFFD700),
                          )
                        : const Icon(Icons.lock_outline_rounded),
                    onTap: legal.contains(pawn.id)
                        ? () => _controller.movePawn(pawn.id)
                        : null,
                  ),
                ),
              if (_controller.lastMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Last action: ${_controller.lastMessage!}',
                  style: const TextStyle(color: Color(0xFFB8B8B8)),
                ),
              ],
              if (_controller.lastError != null)
                Text(
                  'Action rejected: ${_controller.lastError!.error.name}',
                  style: const TextStyle(color: Color(0xFFFF3830)),
                ),
              const SizedBox(height: 16),
              const Text(
                'Known limitation: board coordinates, safe-cell mapping and visual pawn positions are not yet approved. Do not use this development screen as evidence that board gameplay is complete.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }
}
