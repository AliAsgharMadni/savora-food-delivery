import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_profile.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  // Watch auth state changes to keep currentUser updated
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(authRepositoryProvider);
  return repository.fetchProfile(user.id);
});

