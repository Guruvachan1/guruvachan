class UrlValidator {
  UrlValidator._();

  /// Validates if a string is a valid URL
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Validates if a string is a valid image URL (basic check)
  static bool isValidImageUrl(String? url) {
    if (!isValidUrl(url)) return false;
    final lower = url!.toLowerCase();
    // Allow common image extensions or known image hosting patterns
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.bmp') ||
        lower.contains('imgur.com') ||
        lower.contains('unsplash.com') ||
        lower.contains('cloudinary.com') ||
        lower.contains('googleusercontent.com') ||
        lower.contains('firebasestorage.googleapis.com') ||
        lower.contains('supabase.co/storage') ||
        lower.contains('img.youtube.com') ||
        // Allow any URL since it might be a valid image URL
        isValidUrl(url);
  }

  /// Validates a video URL
  static bool isValidVideoUrl(String? url) {
    if (!isValidUrl(url)) return false;
    return true; // We accept any valid URL for videos
  }

  /// Returns a validation error message or null if valid
  static String? validateUrl(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (!isValidUrl(value)) {
      return 'Please enter a valid $fieldName (starting with http:// or https://)';
    }
    return null;
  }

  /// Returns a validation error message for optional URLs (empty is OK)
  static String? validateOptionalUrl(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional, so empty is fine
    }
    if (!isValidUrl(value)) {
      return 'Please enter a valid $fieldName (starting with http:// or https://)';
    }
    return null;
  }
}
