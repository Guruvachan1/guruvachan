class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String bannerUrl;
  final String thumbnailUrl;
  final bool isFeatured;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description = '',
    required this.eventDate,
    this.bannerUrl = '',
    this.thumbnailUrl = '',
    required this.isFeatured,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      eventDate: DateTime.parse(json['event_date'] as String),
      bannerUrl: json['banner_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String().split('T').first,
      'banner_url': bannerUrl,
      'thumbnail_url': thumbnailUrl,
      'is_featured': isFeatured,
      'is_active': isActive,
    };
  }

  Event copyWith({
    String? title,
    String? description,
    DateTime? eventDate,
    String? bannerUrl,
    String? thumbnailUrl,
    bool? isFeatured,
    bool? isActive,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
