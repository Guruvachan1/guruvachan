import 'package:flutter/material.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../models/event_photo.dart';
import 'photo_viewer.dart';

class PhotoGallery extends StatelessWidget {
  final List<EventPhoto> photos;

  const PhotoGallery({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhotoViewer(
                    photos: photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'photo_${photos[index].id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: photos[index].imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
