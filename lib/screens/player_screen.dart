import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.dramaTitle, required this.episodeTitle});

  final String dramaTitle;
  final String episodeTitle;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(dramaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF17121A),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ondemand_video_outlined, size: 58, color: AppTheme.gold),
                        SizedBox(height: 12),
                        Text('พื้นที่เครื่องเล่นวิดีโอ', textAlign: TextAlign.center),
                        SizedBox(height: 4),
                        Text('รอเชื่อมต่อ HLS Streaming', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: ListTile(
                title: Text(episodeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: const Text(
                  'ตัวเล่นนี้ยังเป็นหน้าจอเตรียมระบบสตรีมมิง',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
}
