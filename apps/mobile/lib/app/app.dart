import 'package:flutter/material.dart';

import '../features/game/presentation/screens/board_preview_screen.dart';
import '../features/game/presentation/screens/local_game_screen.dart';
import '../features/game/domain/engine/local_game_factory.dart';
import 'theme/app_theme.dart';
import 'splash_screen.dart';

class LudoLoversApp extends StatelessWidget {
  const LudoLoversApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Lovers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashScreen(
        destinationBuilder: (_) => const AppFoundationScreen(),
      ),
    );
  }
}

class AppFoundationScreen extends StatelessWidget {
  const AppFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppTheme.black,
              Color(0xFF1D100C),
              AppTheme.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.panelRaised,
                            border: Border.all(color: AppTheme.gold, width: 1.5),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.18),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppTheme.magenta,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'LUDO LOVERS',
                                style: TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'PLAY • CONNECT • LOVE',
                                style: TextStyle(
                                  color: AppTheme.readableText,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Profile preview',
                          onPressed: () => _showComingSoon(context, 'Profile'),
                          icon: const Icon(Icons.account_circle_outlined),
                          color: AppTheme.readableText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.sizeOf(context).width;
                            final logoWidth = (screenWidth - 48).clamp(180.0, 340.0);
                            return Image.asset(
                              'assets/images/ludo_lovers_logo.jpg',
                              key: const ValueKey('ludo_lovers_home_logo'),
                              width: logoWidth,
                              height: logoWidth * 0.9,
                              fit: BoxFit.contain,
                              semanticLabel: 'Ludo Lovers — Play and Win',
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: logoWidth,
                                height: logoWidth * 0.9,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.panel,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.gold),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.favorite_rounded,
                                        color: AppTheme.magenta, size: 54),
                                    SizedBox(height: 8),
                                    Text('LUDO LOVERS',
                                        style: TextStyle(
                                          color: AppTheme.gold,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        )),
                                    Text('PLAY • CONNECT • LOVE',
                                        style: TextStyle(
                                          color: AppTheme.readableText,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.65),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppTheme.panelRaised,
                            AppTheme.panel,
                            AppTheme.black,
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              _StatusPill(
                                icon: Icons.auto_awesome,
                                label: 'MADE FOR TOGETHERNESS',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your next favourite\ngame night starts here.',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.readableText,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bring your people together for a little friendly competition.',
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              key: const ValueKey('local_game_lab_button'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GameModeSelectionScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.play_circle_fill_rounded),
                              label: const Text('Play Now · Choose a Mode'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const ValueKey('preview_board_button'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BoardPreviewScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.grid_view_rounded),
                              label: const Text('Explore the Board'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'THE LUDO LOVERS EXPERIENCE',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: <Widget>[
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.people_alt_rounded,
                            title: 'Play together',
                            subtitle: 'Friends & private rooms',
                            accent: AppTheme.green,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.favorite_rounded,
                            title: 'Love Mode',
                            subtitle: 'A little more heart',
                            accent: AppTheme.magenta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _FoundationNotice(),
                    const SizedBox(height: 12),
                    const Text(
                      'EARLY FOUNDATION • MORE FEATURES ARE IN DEVELOPMENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is planned and is not available yet.')),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppTheme.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accent, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.readableText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundationNotice extends StatelessWidget {
  const _FoundationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.65)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: AppTheme.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A local match prototype is available for testing turns and pawn moves. The board route and safe-cell mapping remain provisional; accounts and multiplayer are not connected yet.',
              style: TextStyle(
                color: AppTheme.readableText,
                height: 1.45,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main game-mode hub. Each option opens a deliberate setup flow rather
/// than dropping players directly into a four-seat development match.
class GameModeSelectionScreen extends StatelessWidget {
  const GameModeSelectionScreen({super.key});

  void _openMatch(BuildContext context, {required bool againstAi}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalGameScreen(
          selectedPlayerIds: LocalGameFactory.playerIds,
          playAgainstAi: againstAi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose how to play')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppTheme.black, Color(0xFF1D100C), AppTheme.black],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: <Widget>[
              const Text(
                'YOUR GAME. YOUR PEOPLE.',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 11,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick your way to play',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.readableText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a quick practice match or bring everyone around one phone.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.45),
              ),
              const SizedBox(height: 22),
              _GameModeCard(
                key: const ValueKey('mode_vs_computer_button'),
                icon: Icons.smart_toy_rounded,
                accent: AppTheme.magenta,
                title: 'Play vs Computer',
                subtitle: 'You against three AI opponents',
                detail: 'Great for a solo game. AI moves are handled locally.',
                actionLabel: 'Play vs AI',
                onTap: () => _openMatch(context, againstAi: true),
              ),
              const SizedBox(height: 12),
              _GameModeCard(
                key: const ValueKey('mode_two_players_button'),
                icon: Icons.people_alt_rounded,
                accent: AppTheme.green,
                title: '2 Players',
                subtitle: 'Two people · one device',
                detail: 'Choose two different pawn colours before starting.',
                actionLabel: 'Set up 2-player game',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TwoPlayerSetupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _GameModeCard(
                key: const ValueKey('mode_four_players_button'),
                icon: Icons.groups_rounded,
                accent: AppTheme.blue,
                title: '4 Players',
                subtitle: 'Four people · one device',
                detail: 'Orange, Green, Blue and Magenta take turns locally.',
                actionLabel: 'Start 4-player game',
                onTap: () => _openMatch(context, againstAi: false),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.gold, size: 19),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'These are local prototype modes. Online rooms and connected multiplayer are not available yet, and the board route is still provisional.',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seat-colour selection for a two-person local game.
class TwoPlayerSetupScreen extends StatefulWidget {
  const TwoPlayerSetupScreen({super.key});

  @override
  State<TwoPlayerSetupScreen> createState() => _TwoPlayerSetupScreenState();
}

class _TwoPlayerSetupScreenState extends State<TwoPlayerSetupScreen> {
  final List<String> _selectedPlayers = <String>['orange', 'green'];

  static const Map<String, Color> _colors = <String, Color>{
    'orange': AppTheme.orange,
    'green': AppTheme.green,
    'blue': AppTheme.blue,
    'magenta': AppTheme.magenta,
  };

  void _togglePlayer(String playerId) {
    setState(() {
      if (_selectedPlayers.contains(playerId)) {
        _selectedPlayers.remove(playerId);
      } else if (_selectedPlayers.length < 2) {
        _selectedPlayers.add(playerId);
      } else {
        _selectedPlayers.removeAt(1);
        _selectedPlayers.add(playerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up 2 players')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const Icon(Icons.palette_rounded, color: AppTheme.gold, size: 40),
            const SizedBox(height: 14),
            Text(
              'Choose your colours',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.readableText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select two colours. Players will take turns on this device.',
              style: TextStyle(color: AppTheme.mutedText, height: 1.45),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.entries.map((entry) {
                final selected = _selectedPlayers.contains(entry.key);
                return FilterChip(
                  key: ValueKey('setup_colour_${entry.key}'),
                  label: Text(entry.key.toUpperCase()),
                  avatar: CircleAvatar(
                    radius: 9,
                    backgroundColor: entry.value,
                  ),
                  selected: selected,
                  showCheckmark: true,
                  selectedColor: entry.value.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: selected ? entry.value : Colors.white24,
                    width: selected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? entry.value : AppTheme.readableText,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => _togglePlayer(entry.key),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                _selectedPlayers.length == 2
                    ? 'Player 1: ${_selectedPlayers[0].toUpperCase()}  ·  Player 2: ${_selectedPlayers[1].toUpperCase()}'
                    : 'Choose one more colour to continue.',
                style: const TextStyle(
                  color: AppTheme.readableText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey('start_two_player_match_button'),
                onPressed: _selectedPlayers.length != 2
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LocalGameScreen(
                              selectedPlayerIds:
                                  List<String>.of(_selectedPlayers),
                            ),
                          ),
                        ),
                icon: const Icon(Icons.casino_rounded),
                label: const Text('Start 2-player game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(
                      color: AppTheme.readableText,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    )),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(detail, style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            height: 1.4,
          )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
