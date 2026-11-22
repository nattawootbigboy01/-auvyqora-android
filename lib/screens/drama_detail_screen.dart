import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../models/episode.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DramaDetailScreen extends StatelessWidget {
  const DramaDetailScreen({super.key, required this.drama});
  final Drama drama;

  Stream<List<Episode>> _watchEpisodes() {
    if (Firebase.apps.isEmpty || drama.id.startsWith('drama-')) {
      return Stream.value(drama.episodes);
    }
    return FirebaseFirestore.instance
        .collection('dramas')
        .doc(drama.id)
        .collection('episodes')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      final episodes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Episode(
          id: doc.id,
          title: (data['title'] ?? 'ไม่มีชื่อตอน').toString(),
          number: (data['number'] as num?)?.toInt() ?? 0,
          durationLabel: (data['durationLabel'] ?? 'ตอนใหม่').toString(),
          hlsUrl: (data['hlsUrl'] ?? '').toString(),
        );
      }).toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      return episodes;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดละคร')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: drama.posterUrl.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF76233F), Color(0xFF17121A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_movies_outlined, size: 64, color: AppTheme.gold),
                        ),
                      )
                    : Image.network(
                        drama.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.local_movies_outlined, size: 64, color: AppTheme.gold),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(drama.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(drama.genre, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.gold)),
            const SizedBox(height: 12),
            Text(drama.synopsis, style: const TextStyle(height: 1.5, color: Colors.white70)),
            const SizedBox(height: 12),
            _FavoriteControl(drama: drama),
            const SizedBox(height: 24),
            StreamBuilder<List<Episode>>(
              stream: _watchEpisodes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('โหลดตอนของเรื่องนี้ไม่สำเร็จ: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final episodes = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ทั้งหมด ${episodes.length} ตอน',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (episodes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('ยังไม่มีตอนที่เผยแพร่'),
                      ),
                    ...episodes.map(
                      (episode) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.burgundy,
                            child: Text('${episode.number}'),
                          ),
                          title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(episode.durationLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PlayerScreen(
                                dramaId: drama.id,
                                episodeId: episode.id,
                                dramaTitle: drama.title,
                                episodeTitle: episode.title,
                                hlsUrl: episode.hlsUrl,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _FavoriteControl extends StatelessWidget {
  const _FavoriteControl({required this.drama});
  final Drama drama;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified || drama.id.startsWith('drama-')) {
      return const Text('เข้าสู่ระบบและยืนยันอีเมลเพื่อบันทึกรายการโปรด');
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(drama.id);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final saved = snapshot.data?.exists == true;
        return OutlinedButton.icon(
          onPressed: () async {
            try {
              if (saved) {
                await ref.delete();
              } else {
                await ref.set({'dramaId': drama.id, 'createdAt': FieldValue.serverTimestamp()});
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกรายการโปรดไม่สำเร็จ: $error')),
                );
              }
            }
          },
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          label: Text(saved ? 'นำออกจากรายการโปรด' : 'เพิ่มในรายการโปรด'),
        );
      },
    );
  }
}
