import 'package:flutter_test/flutter_test.dart';
import 'package:secure_browser/main.dart';

void main() {
  testWidgets('SecureBrowserApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureBrowserApp());
    expect(find.byType(SecureBrowserApp), findsOneWidget);
  });
}
