import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sign_in_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const SignInScreen();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('บัญชีของฉัน')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.burgundy,
                child: Icon(Icons.person_outline, size: 46, color: AppTheme.gold),
              ),
              const SizedBox(height: 20),
              const Text(
                'บัญชี AUVYQORA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppTheme.gold),
                  title: const Text('อีเมล'),
                  subtitle: Text(user.email ?? 'ไม่พบอีเมล'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    user.emailVerified ? Icons.verified_outlined : Icons.warning_amber_outlined,
                    color: user.emailVerified ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  title: const Text('สถานะอีเมล'),
                  subtitle: Text(user.emailVerified ? 'ยืนยันแล้ว' : 'ยังไม่ได้ยืนยัน'),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('ออกจากระบบ'),
              ),
            ],
          ),
        );
      },
    );
  }
}
