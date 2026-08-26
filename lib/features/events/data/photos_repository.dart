import 'package:flutter/foundation.dart';
import '../../../config/supabase_config.dart';
import '../../../models/event_photo.dart';
import '../../../core/constants/app_constants.dart';

class PhotosRepository {
  final _client = SupabaseConfig.client;

  /// Get photos for an event
  Future<List<EventPhoto>> getPhotos(String eventId) async {
    final data = await _client
        .from(SupabaseTables.eventPhotos)
        .select()
        .eq('event_id', eventId)
        .order('display_order', ascending: true);
    return data.map((json) => EventPhoto.fromJson(json)).toList();
  }

  /// Create photo
  Future<EventPhoto> createPhoto(Map<String, dynamic> photoData) async {
    final data = await _client
        .from(SupabaseTables.eventPhotos)
        .insert(photoData)
        .select()
        .single();
    return EventPhoto.fromJson(data);
  }

  /// Update photo
  Future<EventPhoto> updatePhoto(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from(SupabaseTables.eventPhotos)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return EventPhoto.fromJson(data);
  }

  /// Delete photo
  Future<void> deletePhoto(String id) async {
    await _client.from(SupabaseTables.eventPhotos).delete().eq('id', id);
  }
}
