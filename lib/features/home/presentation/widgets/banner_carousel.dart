import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../providers/home_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BannerCarousel extends ConsumerWidget {
  const BannerCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);

    return bannersAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        child: CarouselSlider.builder(
          itemCount: 3,
          itemBuilder: (context, index, _) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const Card(
              margin: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: 200,
              ),
            ),
          ),
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        if (banners.length == 1) {
          return _buildSingleBanner(context, banners.first);
        }

        return _buildCarousel(context, banners);
      },
    );
  }

  Widget _buildSingleBanner(BuildContext context, dynamic banner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _handleBannerTap(context, banner.actionUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CachedImage(
                imageUrl: banner.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              if (banner.title.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildOverlay(context, banner.title, banner.subtitle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, List banners) {
    return CarouselSlider.builder(
      itemCount: banners.length,
      itemBuilder: (context, index, realIndex) {
        final banner = banners[index];
        return GestureDetector(
          onTap: () => _handleBannerTap(context, banner.actionUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedImage(
                  imageUrl: banner.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (banner.title.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildOverlay(context, banner.title, banner.subtitle),
                  ),
              ],
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 200,
        viewportFraction: 0.9,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 600),
        autoPlayCurve: Curves.easeInOutCubic,
        enlargeFactor: 0.2,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  void _handleBannerTap(BuildContext context, String? actionUrl) {
    if (actionUrl != null && actionUrl.isNotEmpty) {
      launchUrl(Uri.parse(actionUrl), mode: LaunchMode.externalApplication);
    }
  }
}
