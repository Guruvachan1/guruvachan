class YouTubeUtils {
  YouTubeUtils._();

  /// All supported YouTube URL patterns
  static final List<RegExp> _patterns = [
    // Standard watch URLs with any query parameter order
    RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})'),
    // Short URLs (youtu.be/xxx)
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    // Embed URLs
    RegExp(r'youtube(?:-nocookie)?\.com/embed/([a-zA-Z0-9_-]{11})'),
    // Shorts URLs
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    // Live stream URLs
    RegExp(r'youtube\.com/live/([a-zA-Z0-9_-]{11})'),
    // Direct 11-char ID
    RegExp(r'^([a-zA-Z0-9_-]{11})$'),
  ];

  /// Extracts video ID from any YouTube URL format
  static String? extractVideoId(String url) {
    if (url.trim().isEmpty) return null;
    final cleanUrl = url.trim();
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Checks if a URL is a YouTube URL
  static bool isYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }

  /// Generates a thumbnail URL from a YouTube video ID
  static String getThumbnailUrl(String videoId, {ThumbnailQuality quality = ThumbnailQuality.high}) {
    switch (quality) {
      case ThumbnailQuality.defaultQuality:
        return 'https://img.youtube.com/vi/$videoId/default.jpg';
      case ThumbnailQuality.medium:
        return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
      case ThumbnailQuality.high:
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      case ThumbnailQuality.standard:
        return 'https://img.youtube.com/vi/$videoId/sddefault.jpg';
      case ThumbnailQuality.maxRes:
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
  }

  /// Gets a thumbnail URL from a YouTube video URL
  static String? getThumbnailFromUrl(String url, {ThumbnailQuality quality = ThumbnailQuality.high}) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    return getThumbnailUrl(videoId, quality: quality);
  }

  /// Detects if a YouTube URL might be unlisted
  /// Note: Can't definitively determine from URL alone, but we keep the type for metadata
  static String detectVideoType(String url) {
    if (isYouTubeUrl(url)) {
      return 'youtube';
    }
    return 'public_video';
  }
}

enum ThumbnailQuality {
  defaultQuality,
  medium,
  high,
  standard,
  maxRes,
}
