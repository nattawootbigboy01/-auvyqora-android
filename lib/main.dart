import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const AuvyqoraApp());

class AuvyqoraApp extends StatelessWidget {
  const AuvyqoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AUVYQORA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      );
}
