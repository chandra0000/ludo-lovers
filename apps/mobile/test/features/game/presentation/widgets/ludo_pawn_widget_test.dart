import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/presentation/widgets/ludo_pawn_widget.dart';

void main() {
  Widget host({
    bool eligible = false,
    int stackedCount = 1,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LudoPawnWidget(
            color: const Color(0xFFFF8928),
            label: 'Orange pawn',
            eligible: eligible,
            stackedCount: stackedCount,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  testWidgets('renders accessible pawn and stack-count badge', (tester) async {
    await tester.pumpWidget(host(stackedCount: 3));

    expect(find.byType(LudoPawnWidget), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics &&
            widget.properties.label == 'Orange pawn',
      ),
      findsOneWidget,
    );
  });

  testWidgets('eligible state animates and can be turned off safely', (tester) async {
    await tester.pumpWidget(host(eligible: true));
    await tester.pump(const Duration(milliseconds: 180));

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(eligible: false));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('forwards taps without coupling pawn to game rules', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(onTap: () => tapped = true));

    await tester.tap(find.byType(LudoPawnWidget));
    expect(tapped, isTrue);
  });
}
