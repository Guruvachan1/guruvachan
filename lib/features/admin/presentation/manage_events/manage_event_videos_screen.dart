import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../events/providers/events_provider.dart';
import '../../../../models/event_video.dart';

class ManageEventVideosScreen extends ConsumerWidget {
  final String eventId;
  final String eventTitle;

  const ManageEventVideosScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(eventVideosProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: Text('$eventTitle Videos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/events/$eventId/videos/create');
          ref.invalidate(eventVideosProvider(eventId));
        },
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Add Video'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(eventVideosProvider(eventId)),
        child: videosAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (_, __) => AppErrorWidget(
            message: 'Failed to load videos',
            onRetry: () => ref.invalidate(eventVideosProvider(eventId)),
          ),
          data: (videos) {
            if (videos.isEmpty) {
              return const EmptyStateWidget(
                title: 'No videos yet',
                subtitle: 'Add videos to this event',
                icon: Icons.videocam_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                String thumb = video.thumbnailUrl;
                if (thumb.isEmpty) {
                  final ytId = YouTubeUtils.extractVideoId(video.videoUrl);
                  if (ytId != null) thumb = YouTubeUtils.getThumbnailUrl(ytId);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(imageUrl: thumb, width: 100, height: 60, fit: BoxFit.cover),
                    ),
                    title: Text(video.title, style: Theme.of(context).textTheme.titleSmall),
                    subtitle: Text(video.videoType.displayName, style: Theme.of(context).textTheme.bodySmall),
                    trailing: PopupMenuButton(
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await context.push(
                            '/admin/events/$eventId/videos/edit/${video.id}',
                            extra: video.toJson()..['id'] = video.id,
                          );
                          ref.invalidate(eventVideosProvider(eventId));
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Video'),
                              content: const Text('Are you sure?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(videosRepositoryProvider).deleteVideo(video.id);
                            ref.invalidate(eventVideosProvider(eventId));
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
