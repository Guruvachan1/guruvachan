import 'package:flutter/foundation.dart';
import '../../../config/supabase_config.dart';
import '../../../models/app_notification.dart';
import '../../../core/constants/app_constants.dart';

class NotificationsRepository {
  final _client = SupabaseConfig.client;

  /// Get all notifications
  Future<List<AppNotification>> getNotifications() async {
    final data = await _client
        .from(SupabaseTables.notifications)
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  /// Get read status for current user
  Future<Set<String>> getReadNotificationIds() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return {};

    final data = await _client
        .from(SupabaseTables.notificationReads)
        .select('notification_id')
        .eq('user_id', userId)
        .eq('is_read', true);

    return data.map((json) => json['notification_id'] as String).toSet();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseTables.notificationReads).upsert({
      'notification_id': notificationId,
      'user_id': userId,
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }, onConflict: 'notification_id,user_id');
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return 0;

    final allNotifications = await _client
        .from(SupabaseTables.notifications)
        .select('id');

    final readNotifications = await _client
        .from(SupabaseTables.notificationReads)
        .select('notification_id')
        .eq('user_id', userId)
        .eq('is_read', true);

    final readIds = readNotifications
        .map((json) => json['notification_id'] as String)
        .toSet();

    return allNotifications
        .where((n) => !readIds.contains(n['id'] as String))
        .length;
  }

  /// Create notification (admin only)
  Future<AppNotification> createNotification(Map<String, dynamic> data) async {
    final userId = SupabaseConfig.currentUser?.id;
    data['created_by'] = userId;

    final result = await _client
        .from(SupabaseTables.notifications)
        .insert(data)
        .select()
        .single();
    return AppNotification.fromJson(result);
  }

  /// Delete notification (admin only)
  Future<void> deleteNotification(String id) async {
    await _client.from(SupabaseTables.notifications).delete().eq('id', id);
  }
}
