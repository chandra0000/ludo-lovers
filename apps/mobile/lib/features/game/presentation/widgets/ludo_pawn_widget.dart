import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Layered 2.5D token. Game rules and legal-move selection stay outside this widget.
class LudoPawnWidget extends StatefulWidget {
  const LudoPawnWidget({
    super.key,
    required this.color,
    required this.label,
    this.diameter = 32,
    this.eligible = false,
    this.stackedCount = 1,
    this.onTap,
  });

  final Color color;
  final String label;
  final double diameter;
  final bool eligible;
  final int stackedCount;
  final VoidCallback? onTap;

  @override
  State<LudoPawnWidget> createState() => _LudoPawnWidgetState();
}

class _LudoPawnWidgetState extends State<LudoPawnWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.eligible) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LudoPawnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eligible && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.eligible && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.diameter;
    return Semantics(
      button: widget.onTap != null,
      label: widget.label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: AppTheme.black.withValues(alpha: 0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: Center(
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, child) => Transform.scale(
                  scale: widget.eligible ? 1 + 0.12 * _breath.value : 1,
                  child: child,
                ),
                child: SizedBox(
                  width: visual,
                  height: visual,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Soft ground shadow gives the pawn a lifted, grounded feel.
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: visual * 0.72,
                          height: visual * 0.18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.black.withValues(alpha: 0.55),
                                blurRadius: visual * 0.25,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Eligible pawns receive a restrained colour-matched glow.
                      if (widget.eligible)
                        Container(
                          width: visual * 1.15,
                          height: visual * 1.15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.55),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      // Glossy radial body with a clear rim and directional highlight.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.4, -0.5),
                            radius: 0.95,
                            colors: [
                              Color.lerp(widget.color, AppTheme.cream, 0.5)!,
                              widget.color,
                              Color.lerp(widget.color, AppTheme.black, 0.45)!,
                            ],
                          ),
                          border: Border.all(
                            color: widget.eligible
                                ? AppTheme.gold
                                : AppTheme.cream.withValues(alpha: 0.85),
                            width: widget.eligible ? 2.2 : 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.black.withValues(alpha: 0.5),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: visual * 0.28,
                            height: visual * 0.22,
                            margin: EdgeInsets.only(bottom: visual * 0.2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(visual),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.cream.withValues(alpha: 0.95),
                                  AppTheme.cream.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.stackedCount > 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.panel,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.gold),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                '×${widget.stackedCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
