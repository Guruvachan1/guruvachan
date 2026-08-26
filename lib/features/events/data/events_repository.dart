import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../../../models/event.dart';
import '../../../core/constants/app_constants.dart';

class EventsRepository {
  final _client = SupabaseConfig.client;

  /// Get active events (for users)
  Future<List<Event>> getActiveEvents({String? searchQuery}) async {
    var query = _client
        .from(SupabaseTables.events)
        .select()
        .eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    final data = await query.order('event_date', ascending: false);
    return data.map((json) => Event.fromJson(json)).toList();
  }

  /// Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    final data = await _client
        .from(SupabaseTables.events)
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('event_date', ascending: false)
        .limit(10);
    return data.map((json) => Event.fromJson(json)).toList();
  }

  /// Get single event by ID
  Future<Event> getEvent(String id) async {
    final data = await _client
        .from(SupabaseTables.events)
        .select()
        .eq('id', id)
        .single();
    return Event.fromJson(data);
  }

  /// Get all events (for admin)
  Future<List<Event>> getAllEvents({String? searchQuery}) async {
    var query = _client.from(SupabaseTables.events).select();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((json) => Event.fromJson(json)).toList();
  }

  /// Create event
  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    final userId = SupabaseConfig.currentUser?.id;
    eventData['created_by'] = userId;

    final data = await _client
        .from(SupabaseTables.events)
        .insert(eventData)
        .select()
        .single();
    return Event.fromJson(data);
  }

  /// Update event
  Future<Event> updateEvent(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from(SupabaseTables.events)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Event.fromJson(data);
  }

  /// Delete event
  Future<void> deleteEvent(String id) async {
    await _client.from(SupabaseTables.events).delete().eq('id', id);
  }
}
