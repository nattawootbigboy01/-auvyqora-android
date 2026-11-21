import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auvyqora/data/sample_catalog.dart';
import 'package:auvyqora/main.dart';
import 'package:auvyqora/screens/drama_detail_screen.dart';
import 'package:auvyqora/screens/player_screen.dart';
import 'package:auvyqora/screens/sign_in_screen.dart';
import 'package:auvyqora/theme/app_theme.dart';

void useCompactViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('home screen fits a compact phone viewport', (tester) async {
    useCompactViewport(tester);
    await tester.pumpWidget(const AuvyqoraApp());
    await tester.pumpAndSettle();

    expect(find.text('AUVYQORA'), findsOneWidget);
    expect(find.text('ละครแนะนำ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drama detail screen fits a compact phone viewport', (tester) async {
    useCompactViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DramaDetailScreen(drama: sampleCatalog.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เสียงสุดท้าย'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player screen fits long titles on a compact phone', (tester) async {
    useCompactViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const PlayerScreen(
          dramaTitle: 'ชื่อเรื่องที่ยาวมากสำหรับทดสอบการตัดข้อความไม่ให้ล้น',
          episodeTitle: 'ชื่อตอนที่ยาวมากสำหรับทดสอบการจัดวางบนหน้าจอมือถือ',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('พื้นที่เครื่องเล่นวิดีโอ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign in screen fits a compact phone viewport', (tester) async {
    useCompactViewport(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const SignInScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
