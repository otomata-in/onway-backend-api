import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/main.dart';

void main() {
  testWidgets('TeritoryApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TeritoryApp());
    expect(find.byType(TeritoryApp), findsOneWidget);
  });
}
