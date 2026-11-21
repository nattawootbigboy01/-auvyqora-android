import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_messenger.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AuvyqoraApp());
}

class AuvyqoraApp extends StatelessWidget {
  const AuvyqoraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AUVYQORA',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      );
}
