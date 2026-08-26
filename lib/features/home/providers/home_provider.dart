import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/home_banner.dart';
import '../data/banner_repository.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository();
});

/// Active banners for user home screen
final activeBannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  return ref.watch(bannerRepositoryProvider).getActiveBanners();
});

/// All banners for admin management
final allBannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  return ref.watch(bannerRepositoryProvider).getAllBanners();
});
