import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import 'models/user_profile.dart';

abstract class IAuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  Session? get currentSession;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  });

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Future<UserProfile?> fetchProfile(String userId);

  Future<UserProfile> updateProfile(UserProfile profile);
}

class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient? client;

  SupabaseAuthRepository({this.client});

  SupabaseClient get _safeClient {
    final activeClient = client ?? Supabase.instance.client;
    return activeClient;
  }

  @override
  Stream<AuthState> get authStateChanges {
    try {
      return _safeClient.auth.onAuthStateChange;
    } catch (e) {
      debugPrint('Error accessing authStateChange: $e');
      return const Stream<AuthState>.empty();
    }
  }

  @override
  User? get currentUser {
    try {
      return _safeClient.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Session? get currentSession {
    try {
      return _safeClient.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _safeClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim()}
            : null,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure('An unexpected signup error occurred: $e');
    }
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _safeClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure('An unexpected login error occurred: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _safeClient.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _safeClient.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure('Failed to sign out: $e');
    }
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await _safeClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Failed to fetch profile: $e');
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final data = await _safeClient
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Failed to update profile: $e');
    }
  }
}
