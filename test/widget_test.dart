import 'package:flutter_test/flutter_test.dart';

import 'package:secura/main.dart';

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username / Phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
