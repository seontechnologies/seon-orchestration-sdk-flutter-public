import 'package:flutter_test/flutter_test.dart';

import 'package:seon_orchestration_flutter_example/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeonExampleApp());
    expect(find.text('Configuration'), findsOneWidget);
  });
}
