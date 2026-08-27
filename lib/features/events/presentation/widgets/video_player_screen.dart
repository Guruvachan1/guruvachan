import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/utils/youtube_utils.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title = '',
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  String? _videoId;
  bool _isYouTube = false;

  @override
  void initState() {
    super.initState();
    _videoId = YouTubeUtils.extractVideoId(widget.videoUrl) ??
        YoutubePlayerController.convertUrlToId(widget.videoUrl);

    if (_videoId != null) {
      _isYouTube = true;
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
          mute: false,
          showVideoAnnotations: false,
          enableJavaScript: true,
          playsInline: true,
          strictRelatedVideos: false,
        ),
      )..loadVideoById(videoId: _videoId!);
    }
  }

  @override
  void dispose() {
    if (_isYouTube) {
      _controller.close();
    }
    super.dispose();
  }

  Future<void> _openYouTubeApp() async {
    if (_videoId == null) return;
    final appUri = Uri.parse('vnd.youtube:$_videoId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching YouTube: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_isYouTube || _videoId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title.isNotEmpty ? widget.title : 'Video')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title.isNotEmpty ? widget.title : 'External Video',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This video can be played in an external app or browser.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openYouTubeApp,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Video'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.isNotEmpty ? widget.title : 'YouTube Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in YouTube',
            onPressed: _openYouTubeApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded YouTube Player (v6.x)
            YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title.isNotEmpty) ...[
                    Text(
                      widget.title,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openYouTubeApp,
                        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red),
                        label: const Text('Watch on YouTube App'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
