import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../data/sample_catalog.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';
import '../widgets/drama_card.dart';
import '../widgets/ad_banner.dart';
import 'account_screen.dart';
import 'drama_detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _search = '';
  String _genre = 'ทั้งหมด';
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDrama(Drama drama) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => DramaDetailScreen(drama: drama)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['AUVYQORA', 'ค้นหาละคร', 'คลังของฉัน', 'บัญชี'];
    return StreamBuilder<List<Drama>>(
      stream: _watchCatalog(),
      builder: (context, snapshot) {
        final dramas = snapshot.data ?? const <Drama>[];
        return Scaffold(
          appBar: _tab == 3 ? null : AppBar(
            title: Text(titles[_tab],
                style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900)),
            centerTitle: _tab != 0,
            actions: [
              if (_tab == 0)
                IconButton(
                  tooltip: 'ค้นหา',
                  onPressed: () => setState(() => _tab = 1),
                  icon: const Icon(Icons.search),
                ),
            ],
          ),
          body: snapshot.hasError
              ? _message('โหลดรายการละครไม่สำเร็จ กรุณาลองใหม่ภายหลัง')
              : !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _buildHome(dramas),
                        _buildSearch(dramas),
                        _buildLibrary(),
                        const AccountScreen(),
                      ],
                    ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_tab == 0) const SafeArea(top: false, child: AdBanner()),
              NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) => setState(() => _tab = index),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'หน้าแรก'),
                  NavigationDestination(icon: Icon(Icons.search), label: 'ค้นหา'),
                  NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'คลังของฉัน'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'บัญชี'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHome(List<Drama> dramas) {
    if (dramas.isEmpty) {
      return _message('ยังไม่มีละครที่เผยแพร่\nละครที่พร้อมรับชมจะแสดงที่นี่');
    }
    final genres = <String>{'ทั้งหมด', ...dramas.map((d) => d.genre).where((g) => g.trim().isNotEmpty)};
    final categoryItems = _genre == 'ทั้งหมด' ? dramas : dramas.where((d) => d.genre == _genre).toList();
    final featured = categoryItems.firstWhere(
      (drama) => drama.isFeatured,
      orElse: () => categoryItems.isNotEmpty ? categoryItems.first : dramas.first,
    );
    final filtered = categoryItems.where((drama) => drama.id != featured.id).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _featuredCard(featured),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            children: [
              const Expanded(child: Text('เลือกแนวที่ชอบ', style: TextStyle(fontWeight: FontWeight.bold))),
              Text('${dramas.length} เรื่อง', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: genres.map((genre) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(genre),
                selected: _genre == genre,
                onSelected: (_) => setState(() => _genre = genre),
              ),
            )).toList(),
          ),
        ),
        if (filtered.isNotEmpty)
          _section(_genre == 'ทั้งหมด' ? 'เลือกชมเรื่องอื่น ๆ' : 'ละครแนว$_genre', filtered, height: 238)
        else
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('ยังไม่มีละครในหมวดนี้', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _featuredCard(Drama drama) {
    return InkWell(
      onTap: () => _openDrama(drama),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 244,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF76233F), Color(0xFF241923), Color(0xFF100D12)],
          ),
          border: Border.all(color: AppTheme.gold.withValues(alpha: .25)),
          image: drama.posterUrl.isEmpty ? null : DecorationImage(
            image: NetworkImage(drama.posterUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .56), BlendMode.darken),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('A UNIVERSE OF STORIES',
                style: TextStyle(color: AppTheme.gold, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(drama.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            if (drama.genre.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(drama.genre, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openDrama(drama),
              icon: const Icon(Icons.play_arrow),
              label: const Text('รับชมเลย'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Drama> dramas, {required double height}) {
    if (dramas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: dramas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => DramaCard(
              drama: dramas[index],
              onTap: () => _openDrama(dramas[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(List<Drama> dramas) {
    final query = _search.trim().toLowerCase();
    final results = dramas.where((drama) {
      final matchesText = query.isEmpty ||
          drama.title.toLowerCase().contains(query) ||
          drama.genre.toLowerCase().contains(query) ||
          drama.synopsis.toLowerCase().contains(query);
      final matchesGenre = _genre == 'ทั้งหมด' || drama.genre == _genre;
      return matchesText && matchesGenre;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อเรื่อง แนวละคร หรือเรื่องย่อ',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.isEmpty ? null : IconButton(
              tooltip: 'ล้างคำค้นหา',
              onPressed: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              icon: const Icon(Icons.close),
            ),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Text(results.isEmpty ? 'ไม่พบละครที่ตรงกับคำค้นหา' : 'พบ ${results.length} เรื่อง',
            style: TextStyle(color: Colors.white.withValues(alpha: .65))),
        const SizedBox(height: 8),
        ...results.map((drama) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 58,
                height: 76,
                child: drama.posterUrl.isEmpty
                    ? const ColoredBox(color: AppTheme.surface, child: Icon(Icons.movie_outlined))
                    : Image.network(drama.posterUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.surface, child: Icon(Icons.movie_outlined))),
              ),
            ),
            title: Text(drama.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(drama.genre, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDrama(drama),
          ),
        )),
      ],
    );
  }

  Widget _buildLibrary() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        const Text('ทุกเรื่องที่คุณบันทึกไว้ รวมอยู่ที่นี่',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        _libraryTile(
          icon: Icons.favorite_border,
          title: 'รายการโปรด',
          subtitle: 'ละครที่บันทึกไว้เพื่อกลับมาดูอีกครั้ง',
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FavoritesScreen())),
        ),
        _libraryTile(
          icon: Icons.history,
          title: 'ประวัติการรับชม',
          subtitle: 'ดูต่อจากตำแหน่งล่าสุดที่คุณหยุดไว้',
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const WatchHistoryScreen())),
        ),
      ],
    );
  }

  Widget _libraryTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        minVerticalPadding: 14,
        leading: CircleAvatar(
          backgroundColor: AppTheme.burgundy.withValues(alpha: .45),
          child: Icon(icon, color: AppTheme.gold),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _message(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter_outlined, size: 56, color: AppTheme.gold),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
        ],
      ),
    ),
  );
}
