import 'package:flutter_test/flutter_test.dart';
import 'package:auvyqora_admin/main.dart';

void main() {
  testWidgets('admin app theme and access denied page render', (tester) async {
    await tester.pumpWidget(const AuvyqoraAdminApp());
    expect(find.text('AUVYQORA ADMIN'), findsOneWidget);
  });
}
