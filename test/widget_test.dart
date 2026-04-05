import 'package:flutter_test/flutter_test.dart';

import 'package:hear_rate_detector/app/app.dart';

void main() {
  testWidgets('Home page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HeartRateApp());
    expect(find.text('Start heart rate capturing'), findsOneWidget);
  });
}
