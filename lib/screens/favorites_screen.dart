import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/drama.dart';
import 'drama_detail_screen.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบและยืนยันอีเมลก่อนดูรายการโปรด')));
    }
    final favorites = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites');
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: favorites.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('โหลดรายการโปรดไม่สำเร็จ: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('ยังไม่มีละครในรายการโปรด'));
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final saved = snapshot.data!.docs[index];
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('dramas').doc(saved.id).get(),
                builder: (context, dramaSnapshot) {
                  final data = dramaSnapshot.data?.data();
                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                    title: Text((data?['title'] ?? 'ละครที่ไม่พร้อมใช้งาน').toString()),
                    subtitle: Text(data == null ? 'ไม่พบข้อมูลละคร หรือถูกนำออกจากระบบ' : (data['genre'] ?? '').toString()),
                    onTap: data == null || dramaSnapshot.connectionState != ConnectionState.done
                        ? null
                        : () {
                            final drama = Drama(
                              id: saved.id,
                              title: (data['title'] ?? 'ละคร').toString(),
                              synopsis: (data['synopsis'] ?? '').toString(),
                              genre: (data['genre'] ?? '').toString(),
                              episodes: const [],
                              isFeatured: data['isFeatured'] == true,
                              posterUrl: (data['posterUrl'] ?? '').toString(),
                            );
                            Navigator.push(context, MaterialPageRoute<void>(
                              builder: (_) => DramaDetailScreen(drama: drama),
                            ));
                          },
                    trailing: IconButton(
                      tooltip: 'นำออกจากรายการโปรด',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => favorites.doc(saved.id).delete(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});
  String _position(dynamic value) {
    final seconds = value is num ? value.toInt() : 0;
    final minutes = seconds ~/ 60;
    return 'รับชมล่าสุดที่ประมาณ $minutes นาที';
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบและยืนยันอีเมลก่อนดูประวัติ')));
    }
    final history = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('watch_history');
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการรับชม')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: history.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('โหลดประวัติไม่สำเร็จ: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final av = a.data()['updatedAt'], bv = b.data()['updatedAt'];
              if (av is Timestamp && bv is Timestamp) return bv.compareTo(av);
              return 0;
            });
          if (docs.isEmpty) return const Center(child: Text('ยังไม่มีประวัติการรับชม'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index], data = doc.data();
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text((data['dramaTitle'] ?? 'ละคร').toString()),
                subtitle: Text('${(data['episodeTitle'] ?? 'ตอน').toString()} • ${_position(data['lastPositionSeconds'])}'),
                onTap: () async {
                  final dramaId = (data['dramaId'] ?? '').toString();
                  if (dramaId.isEmpty) return;
                  try {
                    final episode = await FirebaseFirestore.instance
                        .collection('dramas').doc(dramaId).collection('episodes').doc(doc.id).get();
                    final episodeData = episode.data();
                    final url = (episodeData?['hlsUrl'] ?? '').toString();
                    if (!episode.exists || episodeData?['status'] != 'published' || !url.startsWith('https://')) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ตอนนี้ไม่พร้อมรับชม หรือไม่มีลิงก์วิดีโอแล้ว')),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    await Navigator.push(context, MaterialPageRoute<void>(
                      builder: (_) => PlayerScreen(
                        dramaId: dramaId,
                        episodeId: doc.id,
                        dramaTitle: (data['dramaTitle'] ?? 'ละคร').toString(),
                        episodeTitle: (data['episodeTitle'] ?? 'ตอน').toString(),
                        hlsUrl: url,
                        initialPositionSeconds: (data['lastPositionSeconds'] as num?)?.toInt() ?? 0,
                      ),
                    ));
                  } catch (error) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เปิดประวัติการรับชมไม่สำเร็จ: $error')),
                    );
                  }
                },
                trailing: IconButton(
                  tooltip: 'ลบประวัติรายการนี้', icon: const Icon(Icons.delete_outline),
                  onPressed: () => history.doc(doc.id).delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
