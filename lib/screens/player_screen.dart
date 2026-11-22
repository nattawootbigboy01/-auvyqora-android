import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.dramaTitle,
    required this.episodeTitle,
    this.hlsUrl = '',
  });

  final String dramaTitle;
  final String episodeTitle;
  final String hlsUrl;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.hlsUrl.startsWith('https://') || widget.hlsUrl.startsWith('http://')) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl));
    _controller = controller;
    controller.addListener(_onControllerChanged);
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(false);
      setState(() {});
      await controller.play();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'เปิดวิดีโอไม่ได้ กรุณาตรวจสอบลิงก์สตรีม');
      }
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.hasError) {
      const message = 'เกิดข้อผิดพลาดในการเล่นวิดีโอ กรุณาตรวจสอบลิงก์สตรีม';
      if (_error != message) {
        setState(() => _error = message);
        return;
      }
    }
    // Rebuild controls as playback position and playing state change.
    setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onControllerChanged);
    controller?.dispose();
    super.dispose();
  }

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.dramaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: controller == null
                  ? _placeholder()
                  : controller.value.hasError || _error != null
                      ? Text(_error ?? 'เกิดข้อผิดพลาดในการเล่นวิดีโอ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white))
                      : !controller.value.isInitialized
                          ? const CircularProgressIndicator(color: AppTheme.gold)
                          : AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
            ),
          ),
          if (controller != null && controller.value.isInitialized && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                children: [
                  VideoProgressIndicator(controller, allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.gold,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      )),
                  Row(
                    children: [
                      Text(_time(controller.value.position),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                        icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppTheme.gold, size: 30),
                      ),
                      const Spacer(),
                      Text(_time(controller.value.duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )
          else
            SafeArea(
              top: false,
              child: ListTile(
                title: Text(widget.episodeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  _error ?? (widget.hlsUrl.isEmpty
                      ? 'ตอนนี้ยังไม่มีลิงก์วิดีโอ'
                      : 'กำลังเชื่อมต่อสตรีม'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: const Color(0xFF17121A),
        child: const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ondemand_video_outlined, size: 58, color: AppTheme.gold),
                SizedBox(height: 12),
                Text('พื้นที่เครื่องเล่นวิดีโอ', textAlign: TextAlign.center),
                SizedBox(height: 4),
                Text('รอเชื่อมต่อลิงก์ HLS Streaming', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}
