import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../models/event_photo.dart';
import '../../../models/event_video.dart';
import '../data/events_repository.dart';
import '../data/photos_repository.dart';
import '../data/videos_repository.dart';

// ── Repositories ──
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository();
});

final photosRepositoryProvider = Provider<PhotosRepository>((ref) {
  return PhotosRepository();
});

final videosRepositoryProvider = Provider<VideosRepository>((ref) {
  return VideosRepository();
});

// ── Search query state ──
final eventsSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Active events for users ──
final activeEventsProvider = FutureProvider<List<Event>>((ref) async {
  final query = ref.watch(eventsSearchQueryProvider);
  return ref.watch(eventsRepositoryProvider).getActiveEvents(
    searchQuery: query.isEmpty ? null : query,
  );
});

// ── Featured events ──
final featuredEventsProvider = FutureProvider<List<Event>>((ref) async {
  return ref.watch(eventsRepositoryProvider).getFeaturedEvents();
});

// ── Single event ──
final eventDetailProvider = FutureProvider.family<Event, String>((ref, id) async {
  return ref.watch(eventsRepositoryProvider).getEvent(id);
});

// ── All events for admin ──
final adminEventsProvider = FutureProvider<List<Event>>((ref) async {
  final query = ref.watch(eventsSearchQueryProvider);
  return ref.watch(eventsRepositoryProvider).getAllEvents(
    searchQuery: query.isEmpty ? null : query,
  );
});

// ── Photos for an event ──
final eventPhotosProvider = FutureProvider.family<List<EventPhoto>, String>((ref, eventId) async {
  return ref.watch(photosRepositoryProvider).getPhotos(eventId);
});

// ── Videos for an event ──
final eventVideosProvider = FutureProvider.family<List<EventVideo>, String>((ref, eventId) async {
  return ref.watch(videosRepositoryProvider).getVideos(eventId);
});
