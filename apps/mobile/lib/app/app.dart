import 'package:flutter/material.dart';

import '../features/game/domain/engine/local_game_factory.dart';
import '../features/game/presentation/screens/local_game_screen.dart';
import 'theme/app_theme.dart';

class LudoLoversApp extends StatelessWidget {
  const LudoLoversApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Lovers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Show the playable mode hub on the first Flutter frame. The previous
      // timed splash delayed interaction for 2.5 seconds and could look like
      // a black-screen hang on slower Android devices during startup.
      home: const GameModeSelectionScreen(),
    );
  }
}

/// Compact launch hub. Onboarding and the separate marketing home screen are
/// intentionally bypassed for this lightweight first release. Two-player
/// colour selection is kept inline so it does not open another screen.
class GameModeSelectionScreen extends StatefulWidget {
  const GameModeSelectionScreen({super.key});

  @override
  State<GameModeSelectionScreen> createState() =>
      _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> {
  static const Map<String, Color> _playerColors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  final List<String> _selectedPlayers = <String>['orange', 'green'];
  bool _twoPlayerSetupVisible = false;

  // Use an immediate opaque route while investigating device-only black
  // frames during gameplay navigation. This removes the default Android
  // route animation as a variable without changing match setup or rendering.
  void _pushMatch(Widget screen, {required String mode}) {
    debugPrint(
      '[LudoLovers][NavigationRequest] mode=$mode '
      'screen=${screen.runtimeType} mounted=$mounted',
    );
    final route = PageRouteBuilder<void>(
      settings: RouteSettings(name: '/gameplay/$mode'),
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        debugPrint(
          '[LudoLovers][GameplayRouteBuild] mode=$mode '
          'screen=${screen.runtimeType}',
        );
        return screen;
      },
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
    Navigator.of(context).push<void>(route).then<void>((_) {
      debugPrint('[LudoLovers][GameplayRoutePopped] mode=$mode');
    });
  }

  void _openMatch({required bool againstAi, required String mode}) {
    debugPrint(
      '[LudoLovers][ModeSelected] mode=$mode againstAi=$againstAi',
    );
    _pushMatch(
      LocalGameScreen(
        selectedPlayerIds: LocalGameFactory.playerIds,
        playAgainstAi: againstAi,
      ),
      mode: mode,
    );
  }

  void _showTwoPlayerSetup() {
    debugPrint('[LudoLovers][ModeSelected] mode=two_player_setup');
    setState(() => _twoPlayerSetupVisible = true);
  }

  void _togglePlayer(String playerId) {
    setState(() {
      if (_selectedPlayers.contains(playerId)) {
        if (_selectedPlayers.length > 1) {
          _selectedPlayers.remove(playerId);
        }
      } else if (_selectedPlayers.length < 2) {
        _selectedPlayers.add(playerId);
      } else {
        _selectedPlayers.removeAt(1);
        _selectedPlayers.add(playerId);
      }
    });
  }

  void _startTwoPlayerMatch() {
    if (_selectedPlayers.length != 2) {
      debugPrint(
        '[LudoLovers][ModeSelectionRejected] mode=two_player '
        'selectedPlayers=${_selectedPlayers.length}',
      );
      return;
    }
    debugPrint(
      '[LudoLovers][ModeSelected] mode=two_player '
      'players=${_selectedPlayers.join(',')}',
    );
    _pushMatch(
      LocalGameScreen(
        selectedPlayerIds: List<String>.of(_selectedPlayers),
      ),
      mode: 'two_player',
    );
  }

  void _startTeamUpMatch() {
    debugPrint('[LudoLovers][ModeSelected] mode=team_up');
    _pushMatch(
      const LocalGameScreen(
        selectedPlayerIds: LocalGameFactory.playerIds,
        gameMode: LocalGameMode.teamUp,
      ),
      mode: 'team_up',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppTheme.black, Color(0xFF1D100C), AppTheme.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.panelRaised,
                          border: Border.all(color: AppTheme.gold, width: 1.4),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.magenta,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'LUDO LOVERS',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'PLAY • CONNECT • LOVE',
                              style: TextStyle(
                                color: AppTheme.readableText,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'CHOOSE YOUR GAME',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.readableText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick a mode and start playing.',
                    style: TextStyle(color: AppTheme.mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: <Widget>[
                      _ModeTile(
                        key: const ValueKey('mode_vs_computer_button'),
                        icon: Icons.smart_toy_rounded,
                        label: 'VS AI',
                        detail: '1 player',
                        accent: AppTheme.magenta,
                        onTap: () => _openMatch(againstAi: true, mode: 'vs_ai'),
                      ),
                      _ModeTile(
                        key: const ValueKey('mode_two_players_button'),
                        icon: Icons.looks_two_rounded,
                        label: '2P',
                        detail: 'Choose colours',
                        accent: AppTheme.green,
                        selected: _twoPlayerSetupVisible,
                        onTap: _showTwoPlayerSetup,
                      ),
                      _ModeTile(
                        key: const ValueKey('mode_four_players_button'),
                        icon: Icons.groups_rounded,
                        label: '4P',
                        detail: 'Four players',
                        accent: AppTheme.blue,
                        onTap: () => _openMatch(againstAi: false, mode: 'four_player'),
                      ),
                      _ModeTile(
                        key: const ValueKey('mode_team_up_button'),
                        icon: null,
                        label: 'TEAM UP',
                        detail: '2 vs 2',
                        accent: AppTheme.gold,
                        customIcon: const _SameColourPawnsIcon(),
                        onTap: _startTeamUpMatch,
                      ),
                    ],
                  ),
                  if (_twoPlayerSetupVisible) ...<Widget>[
                    const SizedBox(height: 18),
                    Container(
                      key: const ValueKey('inline_two_player_setup'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.panel,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.green.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'SELECT TWO COLOURS',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _playerColors.entries.map((entry) {
                              final selected =
                                  _selectedPlayers.contains(entry.key);
                              return FilterChip(
                                key: ValueKey('setup_colour_${entry.key}'),
                                label: Text(entry.key.toUpperCase()),
                                avatar: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: entry.value,
                                ),
                                selected: selected,
                                showCheckmark: true,
                                selectedColor:
                                    entry.value.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: selected
                                      ? entry.value
                                      : Colors.white24,
                                  width: selected ? 1.5 : 1,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? entry.value
                                      : AppTheme.readableText,
                                  fontWeight: FontWeight.w800,
                                ),
                                onSelected: (_) => _togglePlayer(entry.key),
                              );
                            }).toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedPlayers.length == 2
                                ? 'Player 1: ${_selectedPlayers[0].toUpperCase()}  ·  Player 2: ${_selectedPlayers[1].toUpperCase()}'
                                : 'Choose one more colour to continue.',
                            style: const TextStyle(
                              color: AppTheme.readableText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              key: const ValueKey('start_two_player_match_button'),
                              onPressed: _selectedPlayers.length == 2
                                  ? _startTwoPlayerMatch
                                  : null,
                              icon: const Icon(Icons.casino_rounded),
                              label: const Text('START 2P GAME'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Local game modes are available now. Online rooms and connected multiplayer will be added later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.onTap,
    this.selected = false,
    this.customIcon,
  });

  final IconData? icon;
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback onTap;
  final bool selected;
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.48),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 38,
                child: customIcon ??
                    Icon(icon, color: accent, size: 34),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two same-colour pawn silhouettes communicate the paired-team mode.
class _SameColourPawnsIcon extends StatelessWidget {
  const _SameColourPawnsIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 54,
      height: 38,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            left: 7,
            bottom: 1,
            child: _PawnGlyph(color: AppTheme.gold, size: 23),
          ),
          Positioned(
            right: 7,
            bottom: 1,
            child: _PawnGlyph(color: AppTheme.gold, size: 23),
          ),
        ],
      ),
    );
  }
}

class _PawnGlyph extends StatelessWidget {
  const _PawnGlyph({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.72,
              height: size * 0.55,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.28),
                  bottom: Radius.circular(size * 0.12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
