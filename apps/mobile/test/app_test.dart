import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/app/app.dart';

void main() {
  testWidgets('renders the Ludo Lovers foundation screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.text('Play together. Stay connected.'), findsOneWidget);
    expect(
      find.textContaining('Project foundation is being prepared.'),
      findsOneWidget,
    );
  });
}
