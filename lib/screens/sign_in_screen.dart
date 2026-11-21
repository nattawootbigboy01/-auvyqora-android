import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Text(
              'ยินดีต้อนรับสู่ AUVYQORA',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('หน้าจอนี้เตรียมไว้สำหรับเชื่อม Firebase Authentication ในเฟสถัดไป'),
            SizedBox(height: 24),
            TextField(decoration: InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder())),
            SizedBox(height: 14),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'รหัสผ่าน', border: OutlineInputBorder())),
            SizedBox(height: 20),
            Text('ระบบเข้าสู่ระบบยังไม่เปิดใช้งานในรุ่น Foundation'),
          ],
        ),
      );
}
