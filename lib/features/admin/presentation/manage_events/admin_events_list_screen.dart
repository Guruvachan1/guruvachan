import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../events/providers/events_provider.dart';
import '../../../../models/event.dart';

class AdminEventsListScreen extends ConsumerWidget {
  const AdminEventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(adminEventsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/events/create');
          ref.invalidate(adminEventsProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Event'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminEventsProvider),
        child: eventsAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load events',
            onRetry: () => ref.invalidate(adminEventsProvider),
          ),
          data: (events) {
            if (events.isEmpty) {
              return const EmptyStateWidget(
                title: 'No events yet',
                subtitle: 'Create your first event',
                icon: Icons.event_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImage(
                            imageUrl: event.thumbnailUrl.isNotEmpty
                                ? event.thumbnailUrl
                                : event.bannerUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(event.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(DateFormatter.short(event.eventDate), style: textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatusChip(label: event.isActive ? 'Active' : 'Inactive', isActive: event.isActive),
                                if (event.isFeatured) ...[
                                  const SizedBox(width: 6),
                                  _StatusChip(label: 'Featured', isActive: true, color: Colors.amber),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'photos', child: Text('Photos')),
                            const PopupMenuItem(value: 'videos', child: Text('Videos')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await context.push(
                                  '/admin/events/edit/${event.id}',
                                  extra: event.toJson()..['id'] = event.id,
                                );
                                ref.invalidate(adminEventsProvider);
                                break;
                              case 'photos':
                                await context.push(
                                  '/admin/events/${event.id}/photos',
                                  extra: {'title': event.title},
                                );
                                break;
                              case 'videos':
                                await context.push(
                                  '/admin/events/${event.id}/videos',
                                  extra: {'title': event.title},
                                );
                                break;
                              case 'delete':
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: const Text('This will also delete all photos and videos. Continue?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref.read(eventsRepositoryProvider).deleteEvent(event.id);
                                  ref.invalidate(adminEventsProvider);
                                }
                                break;
                            }
                          },
                        ),
                      ),
                    ],
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

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;

  const _StatusChip({required this.label, required this.isActive, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isActive ? Colors.green : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w500),
      ),
    );
  }
}
