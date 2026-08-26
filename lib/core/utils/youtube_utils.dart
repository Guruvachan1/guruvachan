class YouTubeUtils {
  YouTubeUtils._();

  /// All supported YouTube URL patterns
  static final List<RegExp> _patterns = [
    // Standard watch URLs
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    // Short URLs
    RegExp(r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]{11})'),
    // Embed URLs
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    // Nocookie embed URLs
    RegExp(r'(?:https?://)?(?:www\.)?youtube-nocookie\.com/embed/([a-zA-Z0-9_-]{11})'),
    // Shorts URLs
    RegExp(r'(?:https?://)?(?:www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    // Mobile URLs
    RegExp(r'(?:https?://)?m\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
  ];

  /// Extracts video ID from any YouTube URL format
  static String? extractVideoId(String url) {
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(url);
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
