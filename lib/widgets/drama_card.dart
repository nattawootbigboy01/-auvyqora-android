import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';

class DramaCard extends StatelessWidget {
  const DramaCard({super.key, required this.drama, required this.onTap});
  final Drama drama;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: SizedBox(width: 148, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 190, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF64243C), Color(0xFF211923), Color(0xFF09090D)]), border: Border.all(color: AppTheme.gold.withValues(alpha: .22))), child: Center(child: Icon(Icons.play_circle_outline, size: 44, color: AppTheme.gold.withValues(alpha: .9)))),
      const SizedBox(height: 9), Text(drama.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(drama.genre, style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12)),
    ])),
  );
}
