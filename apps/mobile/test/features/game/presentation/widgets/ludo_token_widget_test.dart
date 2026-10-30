import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/presentation/widgets/ludo_token_widget.dart';

void main() {
  testWidgets('positions a token relative to the supplied board rectangle',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: const <Widget>[
              LudoTokenWidget(
                key: ValueKey<String>('orange-token'),
                gridPosition: GridPos(0, 0),
                tokenColor: Color(0xFFFF8928),
                boardRect: Rect.fromLTWH(30, 30, 240, 240),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ludo token'), findsOneWidget);
    final token = find.byKey(const ValueKey<String>('orange-token'));
    expect(token, findsOneWidget);
    final tokenRect = tester.getRect(find.bySemanticsLabel('Ludo token'));
    // First cell center is (38, 38); the default 14px radius is retained.
    expect(tokenRect.center.dx, closeTo(38, 0.1));
    expect(tokenRect.center.dy, closeTo(38, 0.1));
    expect(tokenRect.width, closeTo(13.44, 0.1));
  });

  testWidgets('scales token diameter down to fit compact board cells',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: const <Widget>[
              LudoTokenWidget(
                gridPosition: GridPos(14, 14),
                tokenColor: Color(0xFF289EFF),
                boardRect: Rect.fromLTWH(0, 0, 90, 90),
                tokenRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );

    final tokenRect = tester.getRect(find.bySemanticsLabel('Ludo token'));
    expect(tokenRect.width, lessThan(12));
    expect(tokenRect.right, lessThanOrEqualTo(90));
    expect(tokenRect.bottom, lessThanOrEqualTo(90));
  });
}
