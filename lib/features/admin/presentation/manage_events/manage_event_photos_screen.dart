import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/utils/url_validator.dart';
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
  void _showPhotoDialog({EventPhoto? photo}) {
    final urlController = TextEditingController(text: photo?.imageUrl ?? '');
    final orderController = TextEditingController(text: '${photo?.displayOrder ?? 0}');
    final captionController = TextEditingController(text: photo?.caption ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(photo != null ? 'Edit Photo' : 'Add Photo'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL',
                    hintText: 'https://example.com/photo.jpg',
                  ),
                  validator: (v) => UrlValidator.validateUrl(v, fieldName: 'Photo URL'),
                ),
                const SizedBox(height: 12),
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
              if (!formKey.currentState!.validate()) return;
              try {
                final data = {
                  'event_id': widget.eventId,
                  'image_url': urlController.text.trim(),
                  'caption': captionController.text.trim(),
                  'display_order': int.tryParse(orderController.text) ?? 0,
                };
                if (photo != null) {
                  await ref.read(photosRepositoryProvider).updatePhoto(photo.id, data);
                } else {
                  await ref.read(photosRepositoryProvider).createPhoto(data);
                }
                ref.invalidate(eventPhotosProvider(widget.eventId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(photo != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.eventTitle} Photos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPhotoDialog(),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(eventPhotosProvider(widget.eventId)),
        child: photosAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (_, __) => AppErrorWidget(
            message: 'Failed to load photos',
            onRetry: () => ref.invalidate(eventPhotosProvider(widget.eventId)),
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return const EmptyStateWidget(
                title: 'No photos yet',
                subtitle: 'Add photos to this event',
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
                            onTap: () { Navigator.pop(ctx); _showPhotoDialog(photo: photo); },
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
    );
  }
}
