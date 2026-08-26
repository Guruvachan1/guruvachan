import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../models/event_video.dart';
import '../../../events/providers/events_provider.dart';

class VideoFormScreen extends ConsumerStatefulWidget {
  final String eventId;
  final Map<String, dynamic>? videoData;

  const VideoFormScreen({super.key, required this.eventId, this.videoData});

  @override
  ConsumerState<VideoFormScreen> createState() => _VideoFormScreenState();
}

class _VideoFormScreenState extends ConsumerState<VideoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _thumbnailUrlController;
  late final TextEditingController _orderController;
  late VideoType _videoType;
  bool _isLoading = false;
  bool get _isEditing => widget.videoData != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.videoData?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.videoData?['description'] ?? '');
    _videoUrlController = TextEditingController(text: widget.videoData?['video_url'] ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.videoData?['thumbnail_url'] ?? '');
    _orderController = TextEditingController(text: '${widget.videoData?['display_order'] ?? 0}');
    _videoType = VideoType.fromString(widget.videoData?['video_type'] ?? 'youtube');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _detectVideoType() {
    final url = _videoUrlController.text.trim();
    if (YouTubeUtils.isYouTubeUrl(url)) {
      setState(() => _videoType = VideoType.youtube);
      // Auto-fill thumbnail if empty
      if (_thumbnailUrlController.text.isEmpty) {
        final thumb = YouTubeUtils.getThumbnailFromUrl(url);
        if (thumb != null) _thumbnailUrlController.text = thumb;
      }
    } else if (url.isNotEmpty) {
      setState(() => _videoType = VideoType.publicVideo);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'event_id': widget.eventId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'video_url': _videoUrlController.text.trim(),
        'video_type': _videoType.dbValue,
        'thumbnail_url': _thumbnailUrlController.text.trim(),
        'display_order': int.tryParse(_orderController.text) ?? 0,
      };

      if (_isEditing) {
        await ref.read(videosRepositoryProvider).updateVideo(widget.videoData!['id'], data);
      } else {
        await ref.read(videosRepositoryProvider).createVideo(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video ${_isEditing ? "updated" : "added"}!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Video' : 'Add Video')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Video Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://youtube.com/watch?v=...',
                ),
                validator: (v) => UrlValidator.validateUrl(v, fieldName: 'Video URL'),
                onChanged: (_) => _detectVideoType(),
              ),
              const SizedBox(height: 16),
              // Video Type
              DropdownButtonFormField<VideoType>(
                value: _videoType,
                decoration: const InputDecoration(labelText: 'Video Type'),
                items: VideoType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.displayName));
                }).toList(),
                onChanged: (v) => setState(() => _videoType = v ?? VideoType.youtube),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL (optional)',
                  hintText: 'Auto-generated for YouTube',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (UrlValidator.isValidUrl(_thumbnailUrlController.text)) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(imageUrl: _thumbnailUrlController.text.trim(), height: 100, width: double.infinity),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Order'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'UPDATE VIDEO' : 'SAVE VIDEO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
