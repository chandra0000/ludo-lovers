import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/splash_screen.dart';

void main() {
  testWidgets('shows the branded splash then replaces it with the lobby', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          minimumDuration: const Duration(milliseconds: 2500),
          destinationBuilder: (_) => const Scaffold(
            body: Center(child: Text('Main Menu')),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ludo_lovers_splash_logo')), findsOneWidget);
    expect(find.text('PLAY • CONNECT • LOVE'), findsOneWidget);
    expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
    expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    expect(find.text('Main Menu'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2499));
    expect(find.text('Main Menu'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Main Menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('ludo_lovers_splash_logo')), findsNothing);
    expect(Navigator.of(tester.element(find.text('Main Menu'))).canPop(), isFalse);
  });
}
