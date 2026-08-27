import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/cloudinary_config.dart';
import '../utils/url_validator.dart';
import 'cached_image.dart';

/// A reusable image input field that supports:
/// 1. Direct device gallery / camera picking + auto-upload to Cloudinary
/// 2. Direct manual URL entry or paste
/// 3. Live image preview with remove/change actions
class ImagePickerField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? folder;
  final bool isRequired;
  final double previewHeight;
  final double? previewWidth;
  final BoxFit previewFit;
  final VoidCallback? onChanged;

  const ImagePickerField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.folder,
    this.isRequired = false,
    this.previewHeight = 140,
    this.previewWidth,
    this.previewFit = BoxFit.cover,
    this.onChanged,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);

      final url = await CloudinaryConfig.uploadXFile(
        picked,
        folder: widget.folder ?? 'guru_darshan/uploads',
      );

      if (!mounted) return;
      widget.controller.text = url;
      setState(() => _isUploading = false);
      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = UrlValidator.isValidUrl(widget.controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? 'https://... or upload from device',
            suffixIcon: _isUploading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.add_a_photo_rounded),
                    tooltip: 'Upload from device',
                    onPressed: _showPickerOptions,
                  ),
          ),
          validator: (v) {
            if (widget.isRequired) {
              return UrlValidator.validateUrl(v, fieldName: widget.label);
            }
            return UrlValidator.validateOptionalUrl(v, fieldName: widget.label);
          },
          onChanged: (_) {
            setState(() {});
            widget.onChanged?.call();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _showPickerOptions,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: Text(_isUploading ? 'Uploading...' : 'Pick / Upload Image'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (hasValidUrl) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  widget.controller.clear();
                  setState(() {});
                  widget.onChanged?.call();
                },
                icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.red),
                label: const Text('Clear', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
        if (hasValidUrl) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedImage(
              imageUrl: widget.controller.text.trim(),
              height: widget.previewHeight,
              width: widget.previewWidth ?? double.infinity,
              fit: widget.previewFit,
            ),
          ),
        ],
      ],
    );
  }
}
