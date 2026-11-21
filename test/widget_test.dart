import 'package:flutter_test/flutter_test.dart';
import 'package:auvyqora/main.dart';

void main() {
  testWidgets('home screen shows AUVYQORA branding', (tester) async {
    await tester.pumpWidget(const AuvyqoraApp());
    expect(find.text('AUVYQORA'), findsOneWidget);
    expect(find.text('ละครแนะนำ'), findsOneWidget);
  });
}
