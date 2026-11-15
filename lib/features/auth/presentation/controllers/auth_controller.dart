import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../data/auth_repository.dart';
import 'auth_state_provider.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository, ref: ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final IAuthRepository repository;
  final Ref ref;

  AuthController({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(userProfileProvider);
      return true;
    } on AuthFailure catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Login failed: $e', StackTrace.current);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(userProfileProvider);
      return response.session != null || response.user != null;
    } on AuthFailure catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Sign up failed: $e', StackTrace.current);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await repository.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
      return true;
    } on AuthFailure catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(
        'Password reset failed: $e',
        StackTrace.current,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await repository.signOut();
      state = const AsyncValue.data(null);
      ref.invalidate(userProfileProvider);
    } on AuthFailure catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Sign out failed: $e', StackTrace.current);
    }
  }
}
