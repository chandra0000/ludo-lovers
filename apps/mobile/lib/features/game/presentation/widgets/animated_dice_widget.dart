import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Presentation-only dice tumble. The final face is always read from game
/// state; this widget never generates or changes a gameplay dice result.
class AnimatedDiceWidget extends StatefulWidget {
  const AnimatedDiceWidget({
    super.key,
    required this.value,
    required this.rolling,
    required this.enabled,
    required this.onRoll,
  });

  final int value;
  final bool rolling;
  final bool enabled;
  final VoidCallback onRoll;

  @override
  State<AnimatedDiceWidget> createState() => _AnimatedDiceWidgetState();
}

class _AnimatedDiceWidgetState extends State<AnimatedDiceWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _turnPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    lowerBound: 0,
    upperBound: 1,
  );
  final math.Random _random = math.Random();
  Timer? _faceTimer;
  int _displayFace = 1;
  bool _locked = false;
  double _rotationPhase = 0;

  static final Animatable<double> _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.9, end: 1.15)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 34,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.15, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 66,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _displayFace = widget.value.clamp(1, 6).toInt();
    if (widget.rolling) {
      _animateRoll();
    } else {
      _syncTurnPulse();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _turnPulseController.stop();
      _animateRoll();
    } else if (!widget.rolling && oldWidget.rolling) {
      _faceTimer?.cancel();
      _displayFace = widget.value.clamp(1, 6).toInt();
      _syncTurnPulse();
    } else if (!widget.rolling && widget.value != oldWidget.value) {
      _displayFace = widget.value.clamp(1, 6).toInt();
    }
    if (!widget.rolling && widget.enabled != oldWidget.enabled) {
      _syncTurnPulse();
    }
  }

  void _syncTurnPulse() {
    if (!mounted) return;
    if (widget.enabled && !widget.rolling && !_locked) {
      if (!_turnPulseController.isAnimating) {
        _turnPulseController.repeat(reverse: true);
      }
    } else {
      _turnPulseController.stop();
      _turnPulseController.value = 0;
    }
  }

  void _handleTap() {
    if (!widget.enabled || _locked || widget.rolling) return;
    // Lock synchronously, before invoking the parent callback, so a second
    // pointer event in the same frame cannot consume another dice value.
    _turnPulseController.stop();
    setState(() => _locked = true);
    widget.onRoll();
  }

  Future<void> _animateRoll() async {
    _locked = true;
    _rotationPhase = _random.nextDouble() * math.pi * 2;
    _faceTimer?.cancel();
    _turnPulseController.stop();
    _controller.reset();
    _faceTimer = Timer.periodic(
      const Duration(milliseconds: 58),
      (timer) {
        if (!mounted || !_controller.isAnimating) {
          timer.cancel();
          return;
        }
        if (_controller.value < 0.82) {
          setState(() => _displayFace = _random.nextInt(6) + 1);
        }
      },
    );

    try {
      await _controller.forward();
    } finally {
      _faceTimer?.cancel();
      if (mounted) {
        setState(() {
          _displayFace = widget.value.clamp(1, 6).toInt();
          _locked = false;
          _rotationPhase = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    _controller.dispose();
    _turnPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRoll = widget.enabled && !_locked && !widget.rolling;
    return Semantics(
      button: true,
      enabled: canRoll,
      label: widget.rolling
          ? 'Rolling dice'
          : 'Dice face ${widget.value.clamp(1, 6)}. Roll dice',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('roll_dice_button'),
          onTap: canRoll ? _handleTap : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.expand(
            child: Center(
              key: const ValueKey('animated_dice_widget'),
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[
                  _controller,
                  _turnPulseController,
                ]),
                builder: (context, _) {
                  final progress = _controller.value;
                  final rotation = widget.rolling
                      ? math.sin(progress * math.pi * 12 + _rotationPhase) *
                          0.25 *
                          (1 - progress)
                      : 0.0;
                  final scale = widget.rolling
                      ? _scale.transform(progress)
                      : (widget.enabled && !_locked
                          ? 1.0 + 0.04 * _turnPulseController.value
                          : 1.0);
                  return Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: <BoxShadow>[
                            if (canRoll)
                              BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.28),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            BoxShadow(
                              color: AppTheme.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _DiceFace(
                          value: widget.rolling
                              ? _displayFace
                              : widget.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value});

  final int value;

  static const Map<int, List<Alignment>> _positions =
      <int, List<Alignment>>{
    1: <Alignment>[Alignment.center],
    2: <Alignment>[Alignment.topRight, Alignment.bottomLeft],
    3: <Alignment>[
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
    ],
    4: <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final face = value.clamp(1, 6).toInt();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Colors.white, AppTheme.cream],
        ),
      ),
      child: Stack(
        children: <Widget>[
          for (final alignment in _positions[face]!)
            Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.panel,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
