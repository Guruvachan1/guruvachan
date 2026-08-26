import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/profile.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Current user profile
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  return ref.watch(profileRepositoryProvider).getCurrentProfile();
});

/// All users (admin only)
final allUsersProvider = FutureProvider<List<Profile>>((ref) async {
  return ref.watch(profileRepositoryProvider).getAllUsers();
});
