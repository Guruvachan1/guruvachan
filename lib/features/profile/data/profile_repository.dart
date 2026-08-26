import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../../../models/profile.dart';
import '../../../core/constants/app_constants.dart';

class ProfileRepository {
  final _client = SupabaseConfig.client;

  /// Get current user profile
  Future<Profile?> getCurrentProfile() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  /// Update profile
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final data = await _client
        .from(SupabaseTables.profiles)
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    return Profile.fromJson(data);
  }

  /// Get all users (admin only)
  Future<List<Profile>> getAllUsers() async {
    final data = await _client
        .from(SupabaseTables.profiles)
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => Profile.fromJson(json)).toList();
  }

  /// Change password
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
