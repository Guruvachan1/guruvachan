import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_notification.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// All notifications
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getNotifications();
});

/// Read notification IDs for current user
final readNotificationIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getReadNotificationIds();
});

/// Unread count
final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});
