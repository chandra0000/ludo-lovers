import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Presentation-only dice tumble. [value] is always supplied by authoritative game state.
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  final math.Random _random = math.Random();
  double _rotation = 0;
  int _displayFace = 1;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _displayFace = widget.value.clamp(1, 6).toInt();
  }

  @override
  void didUpdateWidget(covariant AnimatedDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) _animateRoll();
    if (!widget.rolling && oldWidget.rolling) {
      _displayFace = widget.value.clamp(1, 6).toInt();
      _locked = false;
    }
  }

  Future<void> _animateRoll() async {
    _locked = true;
    _controller.reset();
    _controller.addListener(_tumble);
    await _controller.forward();
    if (!mounted) return;
    _controller.removeListener(_tumble);
    setState(() {
      _displayFace = widget.value.clamp(1, 6).toInt();
      _rotation = 0;
      _locked = false;
    });
  }

  void _tumble() {
    if (!mounted) return;
    setState(() {
      _rotation = (_random.nextDouble() - 0.5) * 0.5;
      if (_controller.value < 0.78) _displayFace = _random.nextInt(6) + 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled && !_locked,
      label: widget.rolling
          ? 'Rolling dice'
          : 'Dice face $_displayFace. Roll dice',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('roll_dice_button'),
          onTap: widget.enabled && !_locked ? widget.onRoll : null,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.expand(
            child: Center(
              key: const ValueKey('animated_dice_widget'),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final pulse = widget.rolling
                      ? 0.9 + 0.25 * math.sin(math.pi * _controller.value)
                      : 1.0;
                  return Transform.rotate(
                    angle: widget.rolling ? _rotation : 0,
                    child: Transform.scale(
                      scale: pulse,
                      child: _DiceFace(
                        value: widget.rolling ? _displayFace : widget.value,
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

  @override
  Widget build(BuildContext context) {
    const positions = <int, List<Alignment>>{
      1: [Alignment.center],
      2: [Alignment.topRight, Alignment.bottomLeft],
      3: [Alignment.topRight, Alignment.center, Alignment.bottomLeft],
      4: [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight],
      5: [Alignment.topLeft, Alignment.topRight, Alignment.center, Alignment.bottomLeft, Alignment.bottomRight],
      6: [Alignment.topLeft, Alignment.topRight, Alignment.centerLeft, Alignment.centerRight, Alignment.bottomLeft, Alignment.bottomRight],
    };
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold, width: 2),
        boxShadow: [BoxShadow(color: AppTheme.black.withValues(alpha: 0.75), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Stack(
        children: [
          for (final alignment in positions[value.clamp(1, 6).toInt()]!)
            Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppTheme.panel, shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
