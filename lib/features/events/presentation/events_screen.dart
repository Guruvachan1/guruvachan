import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/event.dart';
import '../providers/events_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activeEventsProvider);
    final searchQuery = ref.watch(eventsSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              onChanged: (value) =>
                  ref.read(eventsSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () =>
                            ref.read(eventsSearchQueryProvider.notifier).state = '',
                      )
                    : null,
              ),
            ),
          ),
          // Events List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(activeEventsProvider),
              child: eventsAsync.when(
                loading: () => Skeletonizer(
                  enabled: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return _EventListCard(
                        event: Event(
                          id: 'mock',
                          title: 'Loading Event Title...',
                          description: 'Loading description...',
                          eventDate: DateTime.now(),
                          bannerUrl: '',
                          thumbnailUrl: '',
                          isActive: true,
                          isFeatured: false,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                  ),
                ),
                error: (error, _) => AppErrorWidget(
                  message: 'Failed to load events',
                  onRetry: () => ref.invalidate(activeEventsProvider),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No events found',
                      subtitle: 'Check back later for new events',
                      icon: Icons.event_busy_rounded,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _EventListCard(event: events[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  final Event event;

  const _EventListCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/event/${event.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CachedImage(
                  imageUrl: event.thumbnailUrl.isNotEmpty
                      ? event.thumbnailUrl
                      : event.bannerUrl,
                  width: 110,
                  height: 100,
                  fit: BoxFit.cover,
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
                        event.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.short(event.eventDate),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
