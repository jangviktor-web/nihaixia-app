import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NiHaishaApp());
    expect(find.text('辨证'), findsOneWidget);
  });
}
