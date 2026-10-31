import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/onboarding_screen.dart';

Widget _laterDestination() => const Scaffold(
      body: Center(child: Text('Future onboarding destination')),
    );

void main() {
  testWidgets('onboarding remains preserved but is not in the launch flow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          destinationBuilder: (_) => _laterDestination(),
        ),
      ),
    );

    expect(find.text('PLAY TOGETHER'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_skip_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(find.text('Future onboarding destination'), findsOneWidget);
  });

  testWidgets('onboarding slides remain available for later reactivation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          destinationBuilder: (_) => _laterDestination(),
        ),
      ),
    );

    final next = find.byKey(const ValueKey('onboarding_continue_button'));
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('MAKE EVERY MOVE COUNT'), findsOneWidget);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('PLAY • CONNECT • LOVE'), findsNWidgets(2));
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Future onboarding destination'), findsOneWidget);
  });
}
