import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

void main() {
  testWidgets('renders the Ludo Lovers foundation screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.text('Play together. Stay connected.'), findsOneWidget);
    expect(find.text('Preview Ludo Board'), findsOneWidget);
  });

  testWidgets('opens the board preview', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    await tester.tap(find.byKey(const ValueKey('preview_board_button')));
    await tester.pumpAndSettle();

    expect(find.text('Classic Board'), findsOneWidget);
    expect(find.textContaining('Preview only: legal moves'), findsOneWidget);
    expect(find.textContaining('Tap a sample pawn'), findsOneWidget);

    final board = tester.getRect(find.byKey(const ValueKey('interactive_board')));
    // The keyed square includes an 8 px decorative inset around the board.
    const inset = 8.0;
    final boardWidth = board.width - inset * 2;
    final boardHeight = board.height - inset * 2;
    await tester.tapAt(Offset(
      board.left + inset + boardWidth * (1.5 / 15),
      board.top + inset + boardHeight * (6.5 / 15),
    ));
    await tester.pump();
    expect(find.text('Sample pawn selected on cell 0.'), findsOneWidget);
  });
}
