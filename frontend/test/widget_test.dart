import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SawitKuApp());
    expect(find.text('SawitKu'), findsAny);
  });
}
