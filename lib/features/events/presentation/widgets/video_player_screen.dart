import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
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
          origin: 'https://www.youtube.com',
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

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.videoUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
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
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Video'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title.isNotEmpty ? widget.title : 'YouTube Video'),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Open in YouTube',
                onPressed: _openExternal,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Embedded Player ──
                Container(
                  color: Colors.black,
                  child: player,
                ),

                // ── Timeline & Quick Controls Toolbar ──
                StreamBuilder<YoutubeVideoState>(
                  stream: _controller.videoStateStream,
                  builder: (context, snapshot) {
                    final videoState = snapshot.data;
                    final position = videoState?.position ?? Duration.zero;
                    final duration = _controller.value.metaData.duration;
                    final isPlaying = _controller.value.playerState == PlayerState.playing;

                    final maxSeconds = duration.inSeconds.toDouble();
                    final currentSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds > 0 ? maxSeconds : 0.0);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Column(
                        children: [
                          // Seek slider & time display
                          Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: currentSeconds,
                                    max: maxSeconds > 0 ? maxSeconds : 1.0,
                                    onChanged: maxSeconds > 0
                                        ? (val) {
                                            _controller.seekTo(
                                              seconds: val,
                                              allowSeekAhead: true,
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                          // Control Buttons: -10s | Play/Pause | +10s | Mute | Fullscreen
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded),
                                tooltip: 'Rewind 10s',
                                onPressed: () {
                                  final target = (currentSeconds - 10).clamp(0.0, maxSeconds);
                                  _controller.seekTo(seconds: target, allowSeekAhead: true);
                                },
                              ),
                              IconButton.filled(
                                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                iconSize: 28,
                                tooltip: isPlaying ? 'Pause' : 'Play',
                                onPressed: () {
                                  if (isPlaying) {
                                    _controller.pauseVideo();
                                  } else {
                                    _controller.playVideo();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded),
                                tooltip: 'Forward 10s',
                                onPressed: () {
                                  final target = (currentSeconds + 10).clamp(0.0, maxSeconds);
                                  _controller.seekTo(seconds: target, allowSeekAhead: true);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen_rounded),
                                tooltip: 'Fullscreen',
                                onPressed: () => _controller.enterFullScreen(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ── Video Details Section ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title.isNotEmpty) ...[
                        Text(
                          widget.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _openExternal,
                        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red),
                        label: const Text('Watch on YouTube App'),
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
