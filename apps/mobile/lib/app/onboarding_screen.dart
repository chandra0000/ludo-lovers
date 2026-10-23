import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// First-run introduction for the Ludo Lovers local alpha.
///
/// Account providers are intentionally not presented as working until a real
/// authentication flow is connected.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.destinationBuilder});

  final WidgetBuilder destinationBuilder;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      eyebrow: 'WELCOME TO LUDO LOVERS',
      title: 'PLAY TOGETHER',
      description: 'Classic Ludo with friends, family and players online.',
      icon: Icons.favorite_rounded,
      accent: AppTheme.magenta,
    ),
    _OnboardingSlide(
      eyebrow: 'EVERY MOVE TELLS A STORY',
      title: 'MAKE EVERY MOVE COUNT',
      description: 'Bring your colour to the board, plan your moves, and celebrate every little victory together.',
      icon: Icons.casino_rounded,
      accent: AppTheme.orange,
    ),
    _OnboardingSlide(
      eyebrow: 'MORE THAN A BOARD GAME',
      title: 'PLAY • CONNECT • LOVE',
      description: 'Start with local play today. Online play and accounts will arrive as they become ready.',
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
      MaterialPageRoute<void>(builder: widget.destinationBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/ludo_lovers_logo.jpg',
                      key: const ValueKey('onboarding_logo'),
                      width: 44,
                      height: 44,
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
                          Text(
                            'LUDO LOVERS',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'PLAY • CONNECT • LOVE',
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 10,
                              letterSpacing: 1.1,
                            ),
                          ),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    key: const ValueKey('onboarding_continue_button'),
                    onPressed: _continue,
                    child: Text(
                      _page == _slides.length - 1 ? 'Get Started' : 'Next',
                    ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 570;
          final logoSize = compact ? 126.0 : 158.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                width: logoSize, height: logoSize, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.black,
                  border: Border.all(color: AppTheme.gold, width: 2),
                  boxShadow: <BoxShadow>[BoxShadow(
                    color: slide.accent.withValues(alpha: 0.26), blurRadius: 30, spreadRadius: 2,
                  )],
                ),
                child: ClipOval(child: Image.asset(
                  'assets/images/ludo_lovers_logo.jpg', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(slide.icon, size: 70, color: slide.accent),
                )),
              ),
              SizedBox(height: compact ? 16 : 24),
              Text(slide.title, textAlign: TextAlign.center, style: TextStyle(
                color: const Color(0xFFFFE78A), fontSize: compact ? 26 : 30,
                height: 1.08, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                shadows: const <Shadow>[Shadow(color: Color(0x99FF8928), blurRadius: 16)],
              )),
              const SizedBox(height: 10),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: Text(
                slide.description, textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.readableText, fontSize: compact ? 15 : 17, height: 1.5),
              )),
              SizedBox(height: compact ? 18 : 24),
              _MiniLudoBoard(accent: slide.accent),
              const SizedBox(height: 8),
            ]),
          );
        },
      ),
    );
  }
}

class _MiniLudoBoard extends StatelessWidget {
  const _MiniLudoBoard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const colors = <Color>[Color(0xFF33FF28), Color(0xFF289EFF), Color(0xFFF428FF), Color(0xFFFF8928)];
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF182333), Color(0xFF050506)]),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.65)),
        boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.16), blurRadius: 24, spreadRadius: 1)],
      ),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(alignment: Alignment.center, children: <Widget>[
          Transform.rotate(
            angle: -0.10,
            child: Container(
              width: double.infinity, height: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold, width: 1.5),
                gradient: const LinearGradient(colors: <Color>[Color(0xFF263C56), Color(0xFF10131C)])),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(), crossAxisCount: 7,
                padding: const EdgeInsets.all(8),
                children: List<Widget>.generate(49, (index) {
                  final color = switch (index) {
                    0 || 1 || 7 || 8 => colors[0],
                    5 || 6 || 12 || 13 => colors[1],
                    35 || 36 || 42 || 43 => colors[2],
                    40 || 41 || 47 || 48 => colors[3],
                    _ => const Color(0xFFE9E0C8),
                  };
                  return Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.88),
                    border: Border.all(color: const Color(0xFF10131C).withValues(alpha: 0.55), width: 0.5),
                  ));
                }),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: colors.map((color) => Container(
            width: 28, height: 54,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 12)]),
            child: const Align(alignment: Alignment.topCenter, child: Padding(
              padding: EdgeInsets.only(top: 5), child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFFFF0C4)),
            )),
          )).toList()),
          Container(width: 50, height: 50, decoration: BoxDecoration(
            color: const Color(0xFFFFF4D7), borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppTheme.gold, width: 2),
            boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 12)],
          ), child: const Icon(Icons.casino_rounded, color: Color(0xFF1B1110), size: 36)),
        ]),
      ),
    );
  }
}
