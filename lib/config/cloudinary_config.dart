import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary configuration and upload service.
///
/// Pass credentials via --dart-define:
///   flutter run \
///     --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
///     --dart-define=CLOUDINARY_UPLOAD_PRESET=xxx
class CloudinaryConfig {
  CloudinaryConfig._();

  static const _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  static bool get isConfigured =>
      _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload a single image file to Cloudinary (unsigned).
  /// Returns the secure URL on success, throws on failure.
  static Future<String> uploadImage(File imageFile, {String? folder}) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary not configured. Pass CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET via --dart-define.',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String;
      debugPrint('✅ Cloudinary upload success: $secureUrl');
      return secureUrl;
    } else {
      debugPrint('❌ Cloudinary upload failed: ${response.statusCode} ${response.body}');
      throw Exception('Cloudinary upload failed (${response.statusCode})');
    }
  }
}
