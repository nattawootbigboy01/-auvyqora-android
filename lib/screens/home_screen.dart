import 'package:flutter/material.dart';
import 'account_screen.dart';
import '../data/sample_catalog.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';
import '../widgets/drama_card.dart';
import 'drama_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void open(BuildContext context, Drama drama) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DramaDetailScreen(drama: drama)),
      );

  @override
  Widget build(BuildContext context) {
    final featured = sampleCatalog.first;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroTitleSize = (screenWidth * 0.075).clamp(22.0, 30.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUVYQORA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            tooltip: 'บัญชี',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
            ),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'A UNIVERSE OF STORIES',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.gold, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featured.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: heroTitleSize, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SHORT DRAMA. BIG EMOTIONS.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(letterSpacing: 1, fontSize: 10),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => open(context, featured),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('รับชม'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          section(context, 'ละครแนะนำ', sampleCatalog),
          section(context, 'มาใหม่', sampleCatalog.reversed.toList()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF171219),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'หน้าหลัก'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'รายการโปรด'),
          NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติ'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'บัญชี'),
        ],
      ),
    );
  }

  Widget section(BuildContext context, String title, List<Drama> dramas) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final listHeight = (238 * textScale).clamp(238.0, 320.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: dramas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => DramaCard(
              drama: dramas[i],
              onTap: () => open(context, dramas[i]),
            ),
          ),
        ),
      ],
    );
  }
}
