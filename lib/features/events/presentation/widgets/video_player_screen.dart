import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ytp;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yti;
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
  ytp.YoutubePlayerController? _mobileController;
  yti.YoutubePlayerController? _webController;
  String? _videoId;
  bool _isYouTube = false;

  @override
  void initState() {
    super.initState();
    _videoId = YouTubeUtils.extractVideoId(widget.videoUrl) ??
        yti.YoutubePlayerController.convertUrlToId(widget.videoUrl);

    if (_videoId != null) {
      _isYouTube = true;
      if (kIsWeb) {
        _webController = yti.YoutubePlayerController(
          params: const yti.YoutubePlayerParams(
            showFullscreenButton: true,
            showControls: true,
            mute: false,
            showVideoAnnotations: false,
            enableJavaScript: true,
            playsInline: true,
            strictRelatedVideos: false,
          ),
        )..loadVideoById(videoId: _videoId!);
      } else {
        _mobileController = ytp.YoutubePlayerController(
          initialVideoId: _videoId!,
          flags: const ytp.YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            showLiveFullscreenButton: true,
            useHybridComposition: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    _webController?.close();
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

    // ── Web Player ──
    if (kIsWeb && _webController != null) {
      return yti.YoutubePlayerScaffold(
        controller: _webController!,
        aspectRatio: 16 / 9,
        builder: (context, player) {
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
                  Container(color: Colors.black, child: player),
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
                        OutlinedButton.icon(
                          onPressed: _openYouTubeApp,
                          icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red),
                          label: const Text('Watch on YouTube'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // ── Mobile Native Player (Android / iOS) ──
    return ytp.YoutubePlayerBuilder(
      player: ytp.YoutubePlayer(
        controller: _mobileController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ytp.ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
            onPressed: _openYouTubeApp,
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title.isNotEmpty ? widget.title : 'YouTube Video'),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Open in YouTube App',
                onPressed: _openYouTubeApp,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Native mobile player with progress indicator & full controls
                Container(
                  color: Colors.black,
                  child: player,
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
      },
    );
  }
}
