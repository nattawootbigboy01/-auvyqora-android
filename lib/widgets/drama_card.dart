import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';

class DramaCard extends StatelessWidget {
  const DramaCard({super.key, required this.drama, required this.onTap});
  final Drama drama;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 148,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 165,
                  width: 148,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF64243C), Color(0xFF211923), Color(0xFF09090D)],
                    ),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: .22)),
                  ),
                  child: drama.posterUrl.isEmpty
                      ? Center(child: Icon(Icons.play_circle_outline, size: 44, color: AppTheme.gold.withValues(alpha: .9)))
                      : Image.network(
                          drama.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.movie_outlined, size: 44, color: AppTheme.gold.withValues(alpha: .9)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 9),
              Text(drama.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(drama.genre, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12)),
            ],
          ),
        ),
      );
}
