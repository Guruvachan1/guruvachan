enum VideoType {
  youtube,
  youtubeUnlisted,
  publicVideo;

  String get dbValue {
    switch (this) {
      case VideoType.youtube:
        return 'youtube';
      case VideoType.youtubeUnlisted:
        return 'youtube_unlisted';
      case VideoType.publicVideo:
        return 'public_video';
    }
  }

  String get displayName {
    switch (this) {
      case VideoType.youtube:
        return 'YouTube';
      case VideoType.youtubeUnlisted:
        return 'YouTube (Unlisted)';
      case VideoType.publicVideo:
        return 'Public Video';
    }
  }

  static VideoType fromString(String value) {
    switch (value) {
      case 'youtube':
        return VideoType.youtube;
      case 'youtube_unlisted':
        return VideoType.youtubeUnlisted;
      case 'public_video':
        return VideoType.publicVideo;
      default:
        return VideoType.youtube;
    }
  }
}

class EventVideo {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final String videoUrl;
  final VideoType videoType;
  final String thumbnailUrl;
  final int displayOrder;
  final DateTime createdAt;

  const EventVideo({
    required this.id,
    required this.eventId,
    required this.title,
    this.description = '',
    required this.videoUrl,
    required this.videoType,
    this.thumbnailUrl = '',
    required this.displayOrder,
    required this.createdAt,
  });

  factory EventVideo.fromJson(Map<String, dynamic> json) {
    return EventVideo(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['video_url'] as String,
      videoType: VideoType.fromString(json['video_type'] as String? ?? 'youtube'),
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'video_type': videoType.dbValue,
      'thumbnail_url': thumbnailUrl,
      'display_order': displayOrder,
    };
  }

  EventVideo copyWith({
    String? title,
    String? description,
    String? videoUrl,
    VideoType? videoType,
    String? thumbnailUrl,
    int? displayOrder,
  }) {
    return EventVideo(
      id: id,
      eventId: eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      videoType: videoType ?? this.videoType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
    );
  }
}
