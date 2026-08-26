class SupabaseTables {
  SupabaseTables._();

  static const profiles = 'profiles';
  static const homeBanners = 'home_banners';
  static const events = 'events';
  static const eventPhotos = 'event_photos';
  static const eventVideos = 'event_videos';
  static const notifications = 'notifications';
  static const notificationReads = 'notification_reads';
}

class AppConstants {
  AppConstants._();

  static const appName = 'GURU DARSHAN';
  static const appTagline = 'Events & Media';

  // Pagination
  static const defaultPageSize = 20;

  // Animation durations
  static const quickAnimation = Duration(milliseconds: 200);
  static const normalAnimation = Duration(milliseconds: 300);
  static const slowAnimation = Duration(milliseconds: 500);

  // Splash screen delay
  static const splashDuration = Duration(seconds: 2);
}
