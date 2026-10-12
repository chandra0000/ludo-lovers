import 'package:flutter/material.dart';

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
              Color(0xFF080B0B),
              Color(0xFF24122A),
              Color(0xFF080B0B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.favorite_rounded,
                    size: 72,
                    color: Color(0xFFF428FF),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'LUDO LOVERS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFFFF8928),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.4,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Play together. Stay connected.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFFFF8E1),
                        ),
                  ),
                  const SizedBox(height: 28),
                  const _FoundationNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoundationNotice extends StatelessWidget {
  const _FoundationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17191B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF289EFF).withValues(alpha: 0.7)),
      ),
      child: const Text(
        'Project foundation is being prepared. Game modes and multiplayer will be added after the local game engine is validated.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFF8E1),
          height: 1.45,
        ),
      ),
    );
  }
}
