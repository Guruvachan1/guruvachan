import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/cloudinary_config.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../events/providers/events_provider.dart';
import '../../../../models/event_photo.dart';

class ManageEventPhotosScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const ManageEventPhotosScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  ConsumerState<ManageEventPhotosScreen> createState() => _ManageEventPhotosScreenState();
}

class _ManageEventPhotosScreenState extends ConsumerState<ManageEventPhotosScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalCount = 0;

  /// Show bottom sheet to choose camera or gallery
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
              subtitle: const Text('Select multiple photos'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pick multiple images from gallery and upload
  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        await _uploadImages(images);
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  /// Pick single image from camera and upload
  Future<void> _pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        await _uploadImages([image]);
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  /// Upload a list of images to Cloudinary, then save URLs to Supabase
  Future<void> _uploadImages(List<XFile> images) async {
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalCount = images.length;
    });

    int successCount = 0;

    // Get current max display order
    final currentPhotos = ref.read(eventPhotosProvider(widget.eventId)).valueOrNull ?? [];
    int nextOrder = currentPhotos.isEmpty
        ? 0
        : currentPhotos.map((p) => p.displayOrder).reduce((a, b) => a > b ? a : b) + 1;

    for (final xFile in images) {
      try {
        // Upload to Cloudinary
        final imageFile = File(xFile.path);
        final cloudinaryUrl = await CloudinaryConfig.uploadImage(
          imageFile,
          folder: 'guru_darshan/events/${widget.eventId}',
        );

        // Save to Supabase
        await ref.read(photosRepositoryProvider).createPhoto({
          'event_id': widget.eventId,
          'image_url': cloudinaryUrl,
          'caption': '',
          'display_order': nextOrder,
        });

        nextOrder++;
        successCount++;
        setState(() => _uploadedCount = successCount);
      } catch (e) {
        debugPrint('Upload failed for ${xFile.name}: $e');
      }
    }

    setState(() => _isUploading = false);
    ref.invalidate(eventPhotosProvider(widget.eventId));

    if (mounted) {
      final failed = images.length - successCount;
      if (failed > 0) {
        _showError('$successCount uploaded, $failed failed');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount photo${successCount > 1 ? 's' : ''} uploaded!')),
        );
      }
    }
  }

  /// Show edit dialog for caption / display order (no URL field)
  void _showEditDialog(EventPhoto photo) {
    final captionController = TextEditingController(text: photo.caption);
    final orderController = TextEditingController(text: '${photo.displayOrder}');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Photo'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    imageUrl: photo.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: captionController,
                  decoration: const InputDecoration(labelText: 'Caption (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Display Order'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(photosRepositoryProvider).updatePhoto(photo.id, {
                  'caption': captionController.text.trim(),
                  'display_order': int.tryParse(orderController.text) ?? 0,
                });
                ref.invalidate(eventPhotosProvider(widget.eventId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.eventTitle} Photos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _showPickerOptions,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: Column(
        children: [
          // Upload progress bar
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: colorScheme.primaryContainer,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Uploading $_uploadedCount / $_totalCount...',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: _totalCount > 0 ? _uploadedCount / _totalCount : 0,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

          // Photos grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(eventPhotosProvider(widget.eventId)),
              child: photosAsync.when(
                loading: () => const AppLoadingWidget(),
                error: (_, _) => AppErrorWidget(
                  message: 'Failed to load photos',
                  onRetry: () => ref.invalidate(eventPhotosProvider(widget.eventId)),
                ),
                data: (photos) {
                  if (photos.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No photos yet',
                      subtitle: 'Tap + to upload photos from your device',
                      icon: Icons.photo_library_rounded,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () { Navigator.pop(ctx); _showEditDialog(photo); },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await ref.read(photosRepositoryProvider).deletePhoto(photo.id);
                                    ref.invalidate(eventPhotosProvider(widget.eventId));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImage(imageUrl: photo.imageUrl, fit: BoxFit.cover),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
