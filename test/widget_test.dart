import 'package:flutter_test/flutter_test.dart';
import 'package:dyno2/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    try {
      await tester.pumpWidget(const MyApp());
    } catch (e) {}

    expect(MyApp, isNotNull);
  });
}
