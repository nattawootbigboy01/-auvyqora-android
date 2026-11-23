import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมาชิกไม่มีโฆษณา')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF76233F), Color(0xFF211923)],
              ),
              border: Border.all(color: AppTheme.gold.withValues(alpha: .3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_outlined, color: AppTheme.gold, size: 36),
                SizedBox(height: 16),
                Text('รับชมได้อย่างต่อเนื่อง', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('สมัครสมาชิกเพื่อรับชมละครโดยไม่มีโฆษณาคั่น เมื่อแพ็กเกจเปิดให้บริการ'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('สิทธิประโยชน์ที่วางแผนไว้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _Benefit(icon: Icons.block, title: 'ไม่มีโฆษณาคั่น', subtitle: 'รับชมละครได้ต่อเนื่อง'),
          const _Benefit(icon: Icons.play_circle_outline, title: 'ประสบการณ์รับชมที่ลื่นไหล', subtitle: 'ไม่ถูกรบกวนระหว่างดูตอน'),
          const _Benefit(icon: Icons.verified_user_outlined, title: 'จัดการสมาชิกได้', subtitle: 'ตรวจสอบสถานะและวันหมดอายุในบัญชี'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.gold),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ระบบสมาชิกและการชำระเงินยังอยู่ระหว่างพัฒนา ขณะนี้ยังไม่มีการเรียกเก็บเงิน และยังไม่สามารถเปิดสิทธิ์ไม่มีโฆษณาได้',
                    style: TextStyle(height: 1.45, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: AppTheme.burgundy.withValues(alpha: .45),
      child: Icon(icon, color: AppTheme.gold),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
  );
}
