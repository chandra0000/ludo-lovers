import 'package:flutter/material.dart';

import '../features/game/presentation/screens/board_preview_screen.dart';
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
      home: const AppFoundationScreen(),
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
                    const SizedBox(height: 28),
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const ValueKey('local_game_lab_button'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LocalGameScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.casino_rounded),
                              label: const Text('Open Local Game Lab'),
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
              'Board preview only: playable turns, accounts and real-time multiplayer are not connected yet. The board route remains provisional.',
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
