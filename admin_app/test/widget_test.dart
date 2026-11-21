import 'package:auvyqora_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin login screen renders responsively', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AdminTheme.dark,
        home: const AdminLoginPage(),
      ),
    );

    expect(find.text('AUVYQORA ADMIN'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบผู้ดูแล'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
