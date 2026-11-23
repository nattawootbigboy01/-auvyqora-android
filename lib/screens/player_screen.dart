import 'package:flutter/material.dart';
import '../services/playback_tracker.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.dramaId = '',
    this.episodeId = '',
    this.initialPositionSeconds = 0,
    required this.dramaTitle,
    required this.episodeTitle,
    this.hlsUrl = '',
  });

  final String dramaId;
  final String episodeId;
  final int initialPositionSeconds;
  final String dramaTitle;
  final String episodeTitle;
  final String hlsUrl;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _error;
  late final PlaybackTracker _tracker;
  int _lastPositionBucket = -1;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _tracker = PlaybackTracker(dramaId: widget.dramaId, episodeId: widget.episodeId, dramaTitle: widget.dramaTitle, episodeTitle: widget.episodeTitle);
    final streamUri = Uri.tryParse(widget.hlsUrl);
    if (streamUri != null && streamUri.scheme == 'https' && streamUri.hasAuthority) {
      _initializePlayer(streamUri);
    } else {
      _error = widget.hlsUrl.isEmpty
          ? 'ตอนนี้ยังไม่มีลิงก์วิดีโอ'
          : 'ลิงก์วิดีโอไม่ปลอดภัย ระบบอนุญาตเฉพาะ HTTPS';
    }
  }

  Future<void> _initializePlayer(Uri streamUri) async {
    final controller = VideoPlayerController.networkUrl(streamUri);
    _controller = controller;
    controller.addListener(_onControllerChanged);
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(false);
      if (widget.initialPositionSeconds > 0 && widget.initialPositionSeconds < controller.value.duration.inSeconds) {
        await controller.seekTo(Duration(seconds: widget.initialPositionSeconds));
      }
      setState(() {});
      await controller.play();
      await _tracker.recordView();
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
    // Save a checkpoint every 15 seconds; writes are throttled by PlaybackTracker.
    final seconds = controller.value.position.inSeconds;
    final bucket = seconds ~/ 15;
    if (bucket != _lastPositionBucket) {
      _lastPositionBucket = bucket;
      _tracker.savePosition(seconds);
    }
    // Rebuild controls as playback position and playing state change.
    setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      _tracker.savePosition(controller.value.position.inSeconds);
    }
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
                        tooltip: 'ย้อนกลับ 10 วินาที',
                        onPressed: () => controller.seekTo(
                          Duration(seconds: (controller.value.position.inSeconds - 10).clamp(0, controller.value.duration.inSeconds)),
                        ),
                        icon: const Icon(Icons.replay_10, color: Colors.white70),
                      ),
                      IconButton(
                        tooltip: controller.value.isPlaying ? 'หยุดชั่วคราว' : 'เล่นต่อ',
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
                      IconButton(
                        tooltip: 'ไปข้างหน้า 10 วินาที',
                        onPressed: () => controller.seekTo(
                          Duration(seconds: (controller.value.position.inSeconds + 10).clamp(0, controller.value.duration.inSeconds)),
                        ),
                        icon: const Icon(Icons.forward_10, color: Colors.white70),
                      ),
                      PopupMenuButton<double>(
                        tooltip: 'ความเร็วการเล่น',
                        initialValue: _playbackSpeed,
                        onSelected: (speed) async {
                          await controller.setPlaybackSpeed(speed);
                          if (mounted) setState(() => _playbackSpeed = speed);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 0.75, child: Text('0.75x')),
                          PopupMenuItem(value: 1.0, child: Text('ปกติ 1.0x')),
                          PopupMenuItem(value: 1.25, child: Text('1.25x')),
                          PopupMenuItem(value: 1.5, child: Text('1.5x')),
                          PopupMenuItem(value: 2.0, child: Text('2.0x')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${_playbackSpeed}x',
                              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                        ),
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
