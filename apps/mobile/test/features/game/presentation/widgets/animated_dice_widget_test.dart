import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/presentation/widgets/animated_dice_widget.dart';

void main() {
  Widget host({
    bool enabled = true,
    bool rolling = false,
    VoidCallback? onRoll,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: AnimatedDiceWidget(
              value: 4,
              enabled: enabled,
              rolling: rolling,
              onRoll: onRoll ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  double diceScale(WidgetTester tester) {
    final scaleTransform = tester.widget<Transform>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Transform &&
            widget.transform.getMaxScaleOnAxis() > 1.0001,
      ).first,
    );
    return scaleTransform.transform.getMaxScaleOnAxis();
  }

  testWidgets('gently pulses while enabled and waiting for the player', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 450));

    expect(diceScale(tester), greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stops the idle pulse when disabled', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpWidget(host(enabled: false));
    await tester.pump();

    final transforms = tester.widgetList<Transform>(find.byType(Transform));
    final scale = transforms
        .map((transform) => transform.transform.getMaxScaleOnAxis())
        .reduce((a, b) => a > b ? a : b);
    expect(scale, closeTo(1, 0.0001));
  });

  testWidgets('the complete dice hit area responds to taps', (tester) async {
    var rolls = 0;
    await tester.pumpWidget(host(onRoll: () => rolls++));

    // Tap near the edge of the 100x100 hit box, outside the 54x54 face.
    await tester.tapAt(tester.getTopLeft(find.byType(AnimatedDiceWidget)) +
        const Offset(5, 5));
    expect(rolls, 1);
  });

  testWidgets('rolling state replaces the idle pulse with roll animation', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpWidget(host(rolling: true));
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
  });
}
