class HomeBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.actionUrl = '',
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      actionUrl: json['action_url'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  HomeBanner copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    int? displayOrder,
    bool? isActive,
  }) {
    return HomeBanner(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
