import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../../models/event_video.dart';

class VideoCard extends StatelessWidget {
  final EventVideo video;

  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Try to get YouTube thumbnail if not provided
    String thumbnailUrl = video.thumbnailUrl;
    if (thumbnailUrl.isEmpty) {
      final ytId = YouTubeUtils.extractVideoId(video.videoUrl);
      if (ytId != null) {
        thumbnailUrl = YouTubeUtils.getThumbnailUrl(ytId);
      }
    }

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/video-player', extra: {
            'videoUrl': video.videoUrl,
            'title': video.title,
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedImage(
                    imageUrl: thumbnailUrl,
                    width: 140,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.videoType.displayName,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
