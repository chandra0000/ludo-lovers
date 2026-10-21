import 'package:flutter/material.dart';

import 'app.dart';
import 'theme/app_theme.dart';

/// First-run introduction for the Ludo Lovers local alpha.
///
/// Account providers are intentionally not presented as working until a real
/// authentication flow is connected.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      eyebrow: 'WELCOME TO YOUR GAME NIGHT',
      title: 'Play your way.\nStay connected.',
      description:
          'A fresh take on Ludo made for friendly competition, shared laughs, and the people you love.',
      icon: Icons.favorite_rounded,
      accent: AppTheme.magenta,
    ),
    _OnboardingSlide(
      eyebrow: 'EVERY MOVE TELLS A STORY',
      title: 'Make every\nturn count.',
      description:
          'Bring your colour to the board, plan your moves, and celebrate every little victory together.',
      icon: Icons.casino_rounded,
      accent: AppTheme.orange,
    ),
    _OnboardingSlide(
      eyebrow: 'MORE THAN A BOARD GAME',
      title: 'Play • Connect\n• Love.',
      description:
          'Start with local play today. Friends, private rooms, and online features will arrive as they become ready.',
      icon: Icons.people_alt_rounded,
      accent: AppTheme.gold,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _enterApp();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppFoundationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppTheme.black, Color(0xFF1D100C), AppTheme.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/ludo_lovers_logo.jpg',
                      key: const ValueKey('onboarding_logo'),
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.magenta,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('LUDO LOVERS', style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          )),
                          SizedBox(height: 3),
                          Text('PLAY • CONNECT • LOVE', style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          )),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('onboarding_skip_button'),
                      onPressed: _enterApp,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) {
                      final item = _slides[index];
                      return _OnboardingPage(slide: item);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(_slides.length, (index) {
                    final selected = index == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: selected ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.gold : AppTheme.panelRaised,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    key: const ValueKey('onboarding_continue_button'),
                    onPressed: _continue,
                    child: Text(_page == _slides.length - 1
                        ? 'Get Started'
                        : 'Next'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'LOCAL ALPHA • ONLINE ACCOUNTS ARE NOT CONNECTED',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedText,
                        letterSpacing: 0.7,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 204,
              height: 204,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.panel,
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.65)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: slide.accent.withValues(alpha: 0.16),
                    blurRadius: 42,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.accent.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Icon(slide.icon, size: 76, color: slide.accent),
                  Positioned(
                    right: 27,
                    top: 34,
                    child: Icon(Icons.auto_awesome, color: AppTheme.gold, size: 25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Text(
              slide.eyebrow,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.readableText,
                fontSize: 34,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
