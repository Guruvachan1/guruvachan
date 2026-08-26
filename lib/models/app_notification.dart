class AppNotification {
  final String id;
  final String title;
  final String message;
  final String? eventId;
  final String? createdBy;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    this.message = '',
    this.eventId,
    this.createdBy,
    required this.createdAt,
  });

  bool get hasEventLink => eventId != null && eventId!.isNotEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String? ?? '',
      eventId: json['event_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'event_id': eventId,
    };
  }
}

class NotificationRead {
  final String id;
  final String notificationId;
  final String userId;
  final bool isRead;
  final DateTime? readAt;

  const NotificationRead({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.isRead,
    this.readAt,
  });

  factory NotificationRead.fromJson(Map<String, dynamic> json) {
    return NotificationRead(
      id: json['id'] as String,
      notificationId: json['notification_id'] as String,
      userId: json['user_id'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }
}
