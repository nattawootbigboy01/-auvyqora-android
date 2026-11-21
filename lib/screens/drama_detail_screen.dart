import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class DramaDetailScreen extends StatelessWidget {
  const DramaDetailScreen({super.key, required this.drama});
  final Drama drama;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('รายละเอียดละคร')), body: ListView(padding: const EdgeInsets.all(20), children: [
    Container(height: 230, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF76233F), Color(0xFF17121A)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: const Center(child: Icon(Icons.local_movies_outlined, size: 64, color: AppTheme.gold))),
    const SizedBox(height: 18), Text(drama.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    Text(drama.genre, style: const TextStyle(color: AppTheme.gold)), const SizedBox(height: 12), Text(drama.synopsis, style: const TextStyle(height: 1.5, color: Colors.white70)),
    const SizedBox(height: 24), Text('ทั้งหมด ${drama.episodes.length} ตอน', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    ...drama.episodes.map((episode) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppTheme.burgundy, child: Text('${episode.number}')), title: Text(episode.title), subtitle: Text(episode.durationLabel), trailing: const Icon(Icons.play_arrow), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(dramaTitle: drama.title, episodeTitle: episode.title)))))),
  ]));
}
