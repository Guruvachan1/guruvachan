import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/home/presentation/user_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/events/presentation/event_details_screen.dart';
import '../features/events/presentation/widgets/video_player_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/admin/presentation/admin_dashboard.dart';
import '../features/admin/presentation/manage_banners/banners_list_screen.dart';
import '../features/admin/presentation/manage_banners/banner_form_screen.dart';
import '../features/admin/presentation/manage_events/admin_events_list_screen.dart';
import '../features/admin/presentation/manage_events/event_form_screen.dart';
import '../features/admin/presentation/manage_events/manage_event_photos_screen.dart';
import '../features/admin/presentation/manage_events/manage_event_videos_screen.dart';
import '../features/admin/presentation/manage_events/video_form_screen.dart';
import '../features/admin/presentation/manage_notifications/create_notification_screen.dart';
import '../features/admin/presentation/manage_users/users_list_screen.dart';

// Navigation keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // ── Splash ──
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth Routes ──
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── User Shell with Bottom Nav ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Event Details (outside shell for full-screen) ──
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailsScreen(eventId: eventId);
        },
      ),

      // ── Video Player ──
      GoRoute(
        path: '/video-player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VideoPlayerScreen(
            videoUrl: extra['videoUrl'] as String,
            title: extra['title'] as String? ?? '',
          );
        },
      ),

      // ── Edit Profile ──
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ── Admin Routes ──
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/banners',
        builder: (context, state) => const BannersListScreen(),
      ),
      GoRoute(
        path: '/admin/banners/create',
        builder: (context, state) => const BannerFormScreen(),
      ),
      GoRoute(
        path: '/admin/banners/edit/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BannerFormScreen(bannerData: extra);
        },
      ),
      GoRoute(
        path: '/admin/events',
        builder: (context, state) => const AdminEventsListScreen(),
      ),
      GoRoute(
        path: '/admin/events/create',
        builder: (context, state) => const EventFormScreen(),
      ),
      GoRoute(
        path: '/admin/events/edit/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EventFormScreen(eventData: extra);
        },
      ),
      GoRoute(
        path: '/admin/events/:id/photos',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final eventTitle = (state.extra as Map<String, dynamic>?)?['title'] as String? ?? 'Event';
          return ManageEventPhotosScreen(eventId: eventId, eventTitle: eventTitle);
        },
      ),
      GoRoute(
        path: '/admin/events/:id/videos',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final eventTitle = (state.extra as Map<String, dynamic>?)?['title'] as String? ?? 'Event';
          return ManageEventVideosScreen(eventId: eventId, eventTitle: eventTitle);
        },
      ),
      GoRoute(
        path: '/admin/events/:eventId/videos/create',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return VideoFormScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/admin/events/:eventId/videos/edit/:videoId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return VideoFormScreen(eventId: eventId, videoData: extra);
        },
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) => const CreateNotificationScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersListScreen(),
      ),
    ],
  );
});
