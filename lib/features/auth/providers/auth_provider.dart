import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../../../models/profile.dart';
import '../data/auth_repository.dart';

// ── Repository Provider ──
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth State Provider ──
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current User Provider ──
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.currentUser;
});

// ── User Profile Provider ──
final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getProfile(user.id);
});

// ── User Role Provider ──
final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.role ?? UserRole.user;
});

// ── Is Admin Provider ──
final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == UserRole.admin;
});

// ── Auth Notifier for actions ──
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(email: email, password: password);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userRoleProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signUp(email: email, password: password, fullName: fullName);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  String? getErrorMessage() {
    return state.whenOrNull(
      error: (error, _) {
        if (error is AuthException) {
          return error.message;
        }
        return error.toString();
      },
    );
  }
}
