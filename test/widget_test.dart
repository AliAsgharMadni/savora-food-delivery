import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savora/main.dart';

void main() {
  testWidgets('SavoraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SavoraApp(),
      ),
    );
    expect(find.byType(SavoraApp), findsOneWidget);
  });
}
