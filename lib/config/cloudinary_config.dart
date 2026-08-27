import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

  /// Upload an XFile (from image_picker) to Cloudinary (unsigned).
  /// Works across all platforms (Android APK, iOS, Web/Edge).
  static Future<String> uploadXFile(XFile xFile, {String? folder}) async {
    final bytes = await xFile.readAsBytes();
    final filename = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';
    return uploadBytes(bytes, filename: filename, folder: folder);
  }

  /// Upload raw image bytes to Cloudinary (unsigned).
  /// Fully cross-platform without dart:io dependency.
  static Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'image.jpg',
    String? folder,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary not configured. Pass CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET via --dart-define.',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

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
