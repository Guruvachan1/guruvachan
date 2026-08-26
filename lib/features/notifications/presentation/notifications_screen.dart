import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/app_notification.dart';
import '../providers/notifications_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final readIdsAsync = ref.watch(readNotificationIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(readNotificationIdsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: notificationsAsync.when(
          loading: () => Skeletonizer(
            enabled: true,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _NotificationTile(
                  notification: AppNotification(
                    id: 'mock',
                    title: 'Loading notification title...',
                    message: 'Loading notification message...',
                    createdAt: DateTime.now(),
                  ),
                  isRead: true,
                );
              },
            ),
          ),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load notifications',
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                title: 'No notifications',
                subtitle: 'You\'re all caught up!',
                icon: Icons.notifications_none_rounded,
              );
            }

            final readIds = readIdsAsync.valueOrNull ?? {};

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = readIds.contains(notification.id);
                return _NotificationTile(
                  notification: notification,
                  isRead: isRead,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final bool isRead;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isRead
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          notification.hasEventLink
              ? Icons.event_rounded
              : Icons.notifications_rounded,
          color: isRead
              ? colorScheme.onSurfaceVariant
              : colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: Text(
        notification.title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormatter.relative(notification.createdAt),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      trailing: isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () async {
        // Mark as read
        if (!isRead) {
          await ref
              .read(notificationsRepositoryProvider)
              .markAsRead(notification.id);
          ref.invalidate(readNotificationIdsProvider);
          ref.invalidate(unreadCountProvider);
        }

        // Navigate to event if linked
        if (notification.hasEventLink && context.mounted) {
          context.push('/event/${notification.eventId}');
        }
      },
    );
  }
}
