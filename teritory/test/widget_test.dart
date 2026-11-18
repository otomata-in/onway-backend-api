import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/main.dart';

void main() {
  testWidgets('TeritoryApp smoke test', (WidgetTester tester) async {
    // `main()` supplies the ProviderScope, so the test must too.
    await tester.pumpWidget(const ProviderScope(child: TeritoryApp()));
    expect(find.byType(TeritoryApp), findsOneWidget);
  });
}
