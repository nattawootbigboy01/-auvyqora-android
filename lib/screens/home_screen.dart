import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../data/sample_catalog.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';
import '../widgets/drama_card.dart';
import 'account_screen.dart';
import 'drama_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Stream<List<Drama>> _watchCatalog() {
    if (Firebase.apps.isEmpty) return Stream.value(sampleCatalog);
    return FirebaseFirestore.instance
        .collection('dramas')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      final dramas = snapshot.docs.map((doc) {
        final data = doc.data();
        return Drama(
          id: doc.id,
          title: (data['title'] ?? 'ไม่มีชื่อเรื่อง').toString(),
          genre: (data['genre'] ?? 'ไม่ระบุแนว').toString(),
          synopsis: (data['synopsis'] ?? '').toString(),
          posterUrl: (data['posterUrl'] ?? '').toString(),
          isFeatured: data['isFeatured'] == true,
          episodes: const [],
        );
      }).toList();
      dramas.sort((a, b) {
        if (a.isFeatured == b.isFeatured) return a.title.compareTo(b.title);
        return a.isFeatured ? -1 : 1;
      });
      return dramas;
    });
  }

  void _openDrama(BuildContext context, Drama drama) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => DramaDetailScreen(drama: drama)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('AUVYQORA',
              style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              tooltip: 'บัญชี',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        body: StreamBuilder<List<Drama>>(
          stream: _watchCatalog(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('โหลดรายการละครไม่สำเร็จ\n${snapshot.error}',
                      textAlign: TextAlign.center),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final dramas = snapshot.data!;
            if (dramas.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.movie_filter_outlined, size: 58, color: AppTheme.gold),
                      SizedBox(height: 14),
                      Text('ยังไม่มีซีรีส์ที่เผยแพร่',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('ซีรีส์ที่ผู้ดูแลเผยแพร่จะแสดงที่หน้านี้',
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            final featured = dramas.firstWhere(
              (drama) => drama.isFeatured,
              orElse: () => dramas.first,
            );
            final newest = dramas.where((drama) => drama.id != featured.id).toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 224),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF76233F), Color(0xFF241923), Color(0xFF100D12)],
                      ),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: .3)),
                      image: featured.posterUrl.isEmpty
                          ? null
                          : DecorationImage(
                              image: NetworkImage(featured.posterUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: .58),
                                BlendMode.darken,
                              ),
                            ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('A UNIVERSE OF STORIES',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppTheme.gold, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(featured.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: (MediaQuery.sizeOf(context).width * .075).clamp(22.0, 30.0), fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text('SHORT DRAMA. BIG EMOTIONS.',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(letterSpacing: 1, fontSize: 10)),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => _openDrama(context, featured),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('รับชม'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _section(context, 'ละครแนะนำ', dramas.where((d) => d.isFeatured).toList().isEmpty ? dramas : dramas.where((d) => d.isFeatured).toList()),
                if (newest.isNotEmpty) _section(context, 'เรื่องอื่น ๆ', newest),
              ],
            );
          },
        ),
      );

  Widget _section(BuildContext context, String title, List<Drama> dramas) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final listHeight = (238 * textScale).clamp(238.0, 320.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: dramas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => DramaCard(
              drama: dramas[index],
              onTap: () => _openDrama(context, dramas[index]),
            ),
          ),
        ),
      ],
    );
  }
}
