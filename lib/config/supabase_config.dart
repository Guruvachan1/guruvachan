import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  /// Initialize Supabase - call in main() before runApp()
  /// Pass URL and anon key via --dart-define:
  ///   flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('⚠️ WARNING: Supabase URL or Anon Key not provided.');
      debugPrint('Run with: flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Access the Supabase client anywhere
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for auth
  static GoTrueClient get auth => client.auth;

  /// Current user
  static User? get currentUser => auth.currentUser;

  /// Current session
  static Session? get currentSession => auth.currentSession;

  /// Check if user is logged in
  static bool get isLoggedIn => currentSession != null;
}
