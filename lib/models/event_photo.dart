class EventPhoto {
  final String id;
  final String eventId;
  final String imageUrl;
  final String caption;
  final int displayOrder;
  final DateTime createdAt;

  const EventPhoto({
    required this.id,
    required this.eventId,
    required this.imageUrl,
    this.caption = '',
    required this.displayOrder,
    required this.createdAt,
  });

  factory EventPhoto.fromJson(Map<String, dynamic> json) {
    return EventPhoto(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'image_url': imageUrl,
      'caption': caption,
      'display_order': displayOrder,
    };
  }

  EventPhoto copyWith({
    String? imageUrl,
    String? caption,
    int? displayOrder,
  }) {
    return EventPhoto(
      id: id,
      eventId: eventId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
    );
  }
}
