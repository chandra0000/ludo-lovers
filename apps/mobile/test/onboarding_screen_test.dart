import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/onboarding_screen.dart';
import 'package:ludo_lovers/app/app.dart';

void main() {
  testWidgets('onboarding shows the first introduction and skip opens home',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          destinationBuilder: (_) => const AppFoundationScreen(),
        ),
      ),
    );

    expect(find.text('WELCOME TO LUDO LOVERS'), findsOneWidget);
    expect(find.text('PLAY TOGETHER'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_skip_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(find.text('Your next favourite\ngame night starts here.'), findsOneWidget);
  });

  testWidgets('onboarding next advances through the slides to get started',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          destinationBuilder: (_) => const AppFoundationScreen(),
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
    expect(find.text('PLAY • CONNECT • LOVE'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Your next favourite\ngame night starts here.'), findsOneWidget);
  });
}
