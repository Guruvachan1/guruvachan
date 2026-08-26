import 'package:flutter/foundation.dart';
import '../../../config/supabase_config.dart';
import '../../../models/event_video.dart';
import '../../../core/constants/app_constants.dart';

class VideosRepository {
  final _client = SupabaseConfig.client;

  /// Get videos for an event
  Future<List<EventVideo>> getVideos(String eventId) async {
    final data = await _client
        .from(SupabaseTables.eventVideos)
        .select()
        .eq('event_id', eventId)
        .order('display_order', ascending: true);
    return data.map((json) => EventVideo.fromJson(json)).toList();
  }

  /// Create video
  Future<EventVideo> createVideo(Map<String, dynamic> videoData) async {
    final data = await _client
        .from(SupabaseTables.eventVideos)
        .insert(videoData)
        .select()
        .single();
    return EventVideo.fromJson(data);
  }

  /// Update video
  Future<EventVideo> updateVideo(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from(SupabaseTables.eventVideos)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return EventVideo.fromJson(data);
  }

  /// Delete video
  Future<void> deleteVideo(String id) async {
    await _client.from(SupabaseTables.eventVideos).delete().eq('id', id);
  }
}
