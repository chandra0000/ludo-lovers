import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Premium launch screen. It replaces itself with the app's main menu so the
/// Android back button cannot return users to the splash screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.destinationBuilder,
    this.minimumDuration = const Duration(milliseconds: 2500),
  });

  final WidgetBuilder destinationBuilder;

  /// Kept configurable so the transition can be tested without waiting.
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loaderController;
  late final AnimationController _entranceController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _navigationTimer = Timer(widget.minimumDuration, _openMainMenu);
  }

  void _openMainMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.destinationBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: fade, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _loaderController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.12),
                radius: 1.05,
                colors: <Color>[
                  Color(0xFF30200B),
                  Color(0xFF17100B),
                  AppTheme.black,
                ],
                stops: <double>[0, 0.48, 1],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -70,
            child: _GlowOrb(color: AppTheme.gold.withValues(alpha: 0.12), size: 230),
          ),
          Positioned(
            right: -90,
            bottom: 90,
            child: _GlowOrb(color: AppTheme.magenta.withValues(alpha: 0.08), size: 250),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(flex: 3),
                Expanded(
                  flex: 8,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = MediaQuery.sizeOf(context).width;
                        final logoWidth = (width * 0.78).clamp(220.0, 360.0).toDouble();
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _entranceController,
                            curve: Curves.easeOutBack,
                          ),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _entranceController,
                              curve: Curves.easeOutCubic,
                            ),
                            child: Image.asset(
                              'assets/images/ludo_lovers_logo.jpg',
                              key: const ValueKey('ludo_lovers_splash_logo'),
                              width: logoWidth,
                              height: logoWidth,
                              fit: BoxFit.contain,
                              semanticLabel: 'Ludo Lovers logo',
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: logoWidth,
                                height: logoWidth,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.panel,
                                  border: Border.all(
                                    color: AppTheme.gold.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(alpha: 0.16),
                                      blurRadius: 36,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.favorite_rounded,
                                        color: AppTheme.magenta, size: 68),
                                    SizedBox(height: 14),
                                    Text(
                                      'LUDO LOVERS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.gold,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.2,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'PLAY • CONNECT • LOVE',
                    key: ValueKey('ludo_lovers_splash_tagline'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.cream,
                      fontSize: 12,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: _loaderController,
                  builder: (context, child) {
                    final activeDot = (_loaderController.value * 4).floor() % 4;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(4, (index) {
                        final active = index == activeDot;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: active ? 10 : 7,
                          height: active ? 10 : 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? AppTheme.gold
                                : AppTheme.gold.withValues(alpha: 0.30),
                            boxShadow: active
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : const <BoxShadow>[],
                          ),
                        );
                      }),
                    );
                  },
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'MADE FOR YOUR GAME NIGHT',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: size * 0.55, spreadRadius: size * 0.12),
          ],
        ),
      ),
    );
  }
}
