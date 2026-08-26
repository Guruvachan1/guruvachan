import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../../../models/home_banner.dart';
import '../../../core/constants/app_constants.dart';

class BannerRepository {
  final _client = SupabaseConfig.client;

  /// Get active banners (for users)
  Future<List<HomeBanner>> getActiveBanners() async {
    final data = await _client
        .from(SupabaseTables.homeBanners)
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return data.map((json) => HomeBanner.fromJson(json)).toList();
  }

  /// Get all banners (for admin)
  Future<List<HomeBanner>> getAllBanners() async {
    final data = await _client
        .from(SupabaseTables.homeBanners)
        .select()
        .order('display_order', ascending: true);
    return data.map((json) => HomeBanner.fromJson(json)).toList();
  }

  /// Create banner
  Future<HomeBanner> createBanner(Map<String, dynamic> bannerData) async {
    final data = await _client
        .from(SupabaseTables.homeBanners)
        .insert(bannerData)
        .select()
        .single();
    return HomeBanner.fromJson(data);
  }

  /// Update banner
  Future<HomeBanner> updateBanner(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from(SupabaseTables.homeBanners)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return HomeBanner.fromJson(data);
  }

  /// Delete banner
  Future<void> deleteBanner(String id) async {
    await _client.from(SupabaseTables.homeBanners).delete().eq('id', id);
  }
}
