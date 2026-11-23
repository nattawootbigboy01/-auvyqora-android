import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app_messenger.dart';
import '../theme/app_theme.dart';
import 'sign_in_screen.dart';
import 'favorites_screen.dart';
import 'membership_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget tests and preview environments may intentionally run without Firebase.
    // Do not touch FirebaseAuth.instance until a Firebase app exists.
    if (Firebase.apps.isEmpty) return const SignInScreen();
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
              Card(child: ListTile(leading: const Icon(Icons.favorite_outline, color: AppTheme.gold), title: const Text('รายการโปรด'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FavoritesScreen())))),
              Card(child: ListTile(leading: const Icon(Icons.history, color: AppTheme.gold), title: const Text('ประวัติการรับชม'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const WatchHistoryScreen())))),
              Card(child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined, color: AppTheme.gold),
                title: const Text('สมาชิกไม่มีโฆษณา'),
                subtitle: const Text('ดูสิทธิประโยชน์และสถานะการเปิดให้บริการ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MembershipScreen())),
              )),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showAuthPopup('ออกจากระบบแล้ว');
                  });
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
