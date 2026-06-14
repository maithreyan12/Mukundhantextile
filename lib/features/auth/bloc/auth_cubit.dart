import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepo;
  StreamSubscription<dynamic>? _authSub;
  bool _isSigningIn = false;

  AuthCubit({AuthRepository? authRepository})
      : _authRepo = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    _init();
  }

  void _init() {
    final user = _authRepo.currentUser;
    if (user != null) {
      _loadProfile();
    } else {
      emit(AuthUnauthenticated());
    }

    _authSub = _authRepo.authStateChanges.listen((data) {
      if (_isSigningIn) return;

      if (data.session != null) {
        _loadProfile();
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      var profile = await _authRepo.getProfile();

      if (profile == null && _authRepo.currentUser != null) {
        await Future.delayed(const Duration(milliseconds: 1000));
        profile = await _authRepo.getProfile();
      }

      if (profile != null) {
        if (profile.isBanned) {
          await _authRepo.signOut();
          emit(const AuthError('Your account has been suspended.'));
          return;
        }
        debugPrint('✅ AuthCubit: Profile loaded for ${profile.name}');
        emit(AuthAuthenticated(profile));
      } else {
        debugPrint('⚠️ AuthCubit: Profile is null');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('❌ AuthCubit._loadProfile error: $e');
      emit(AuthError('Failed to load profile: $e'));
    }
  }

  // ── Sign Up ───────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isSigningIn = true;
    emit(AuthLoading());
    try {
      final response = await _authRepo.signUp(
        email: email,
        password: password,
        name: name,
      );

      // Check if email confirmation is required
      // When confirmation is needed, Supabase returns a user but no session
      if (response.session == null && response.user != null) {
        debugPrint('📧 AuthCubit: Email confirmation required for $email');
        emit(AuthEmailConfirmationRequired(email));
      } else {
        await _loadProfile();
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      debugPrint('❌ AuthCubit.signUp error: $e');
      emit(AuthError(e.toString()));
    } finally {
      _isSigningIn = false;
    }
  }

  // ── Sign In ───────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isSigningIn = true;
    emit(AuthLoading());
    try {
      await _authRepo.signIn(email: email, password: password);
      await _loadProfile();
    } on AuthException catch (e) {
      // Supabase returns "Invalid login credentials" for both wrong password
      // AND unconfirmed email — provide a better message
      String message = e.message;
      if (message.toLowerCase().contains('invalid login credentials')) {
        message = 'Invalid email or password. If you just signed up, '
            'please check your email to confirm your account first.';
      }
      emit(AuthError(message));
    } catch (e) {
      debugPrint('❌ AuthCubit.signIn error: $e');
      emit(AuthError(e.toString()));
    } finally {
      _isSigningIn = false;
    }
  }

  // ── Google Sign In ────────────────────────────────────
  Future<void> signInWithGoogle() async {
    _isSigningIn = true;
    emit(AuthLoading());
    try {
      final success = await _authRepo.signInWithGoogle();
      if (success && _authRepo.currentUser != null) {
        // Native flow completed — load profile now
        await _loadProfile();
      } else if (!success) {
        // User cancelled or OAuth popup closed
        emit(AuthUnauthenticated());
      }
      // For web OAuth, the page redirects and reloads,
      // so the auth listener in _init() handles the session.
    } catch (e) {
      debugPrint('❌ AuthCubit.signInWithGoogle error: $e');
      emit(AuthError(e.toString()));
    } finally {
      _isSigningIn = false;
    }
  }

  // ── Reset Password ────────────────────────────────────
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authRepo.resetPassword(email);
      emit(AuthPasswordResetSent());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ── Resend Confirmation Email ─────────────────────────
  Future<void> resendConfirmation(String email) async {
    emit(AuthLoading());
    try {
      await _authRepo.resendConfirmation(email);
      emit(AuthEmailConfirmationRequired(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ── Update Profile ────────────────────────────────────
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      await _authRepo.updateProfile(updates);
      await _loadProfile();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _authRepo.signOut();
    emit(AuthUnauthenticated());
  }

  // ── Refresh Profile ───────────────────────────────────
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
