import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client;
  static const String _authRedirectUrl = 'com.mukundhantextile.app://login-callback/';

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Session Stream ────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  // ── Sign Up ───────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
      emailRedirectTo: _authRedirectUrl,
    );

    // Wait briefly for the trigger to create the profile
    await Future.delayed(const Duration(milliseconds: 500));

    // Ensure profile exists (fallback if trigger failed)
    if (response.user != null) {
      await _ensureProfileExists(
        userId: response.user!.id,
        email: email,
        name: name,
      );
    }

    return response;
  }

  // ── Sign In ───────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure profile exists for users who signed up before migration
    if (response.user != null) {
      await _ensureProfileExists(
        userId: response.user!.id,
        email: email,
      );
    }

    return response;
  }

  // ── Phone OTP Sign In ─────────────────────────────────
  Future<void> signInWithOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    if (response.user != null) {
      await _ensureProfileExists(
        userId: response.user!.id,
        phone: phone,
      );
    }
    return response;
  }

  // ── Google Sign In ────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      // 1. For native mobile platforms, try native Google Sign In first
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
        final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

        if (webClientId != null && webClientId.isNotEmpty) {
          try {
            // Initialize GoogleSignIn.instance
            await GoogleSignIn.instance.initialize(
              clientId: (iosClientId == null || iosClientId.isEmpty) ? null : iosClientId,
              serverClientId: webClientId,
            );

            // Authenticate (trigger Google Account Picker / Credential Manager)
            final googleUser = await GoogleSignIn.instance.authenticate();
            final googleAuth = googleUser.authentication;
            final idToken = googleAuth.idToken;
            if (idToken == null) {
              throw 'No ID Token found.';
            }

            final response = await _client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
            );

            if (response.user != null) {
              await _ensureProfileExists(
                userId: response.user!.id,
                email: response.user!.email ?? '',
                name: response.user!.userMetadata?['name'] as String? ?? '',
              );
              return true;
            }
            return false;
          } catch (nativeError) {
            // Native sign-in failed (nonce mismatch, missing config, etc.)
            // Fall back to browser-based OAuth flow
            debugPrint('Native Google Sign In failed: $nativeError — falling back to OAuth browser flow.');
          }
        }

        // Fallback: Use Supabase's browser-based OAuth for mobile
        // Use inAppBrowserView so the auth callback returns to the app
        final success = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: _authRedirectUrl,
          authScreenLaunchMode: LaunchMode.inAppBrowserView,
        );
        return success;
      }

      // 2. Web: Use Supabase's built-in OAuth flow (redirects current page)
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      return success;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  // ── Forgot Password ──────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Resend Email Confirmation ─────────────────────────
  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  // ── Get Profile ───────────────────────────────────────
  Future<UserProfile?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      debugPrint('🔍 getProfile: Fetching profile for $userId');
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('🔍 getProfile: Raw data = $data');

      if (data == null) {
        debugPrint('⚠️ getProfile: No profile found, creating one...');
        // Profile doesn't exist — create it now
        await _ensureProfileExists(
          userId: userId,
          email: currentUser?.email ?? '',
          name: currentUser?.userMetadata?['name'] as String? ?? '',
        );
        // Try fetching again
        final retryData = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        debugPrint('🔍 getProfile: Retry data = $retryData');
        if (retryData != null) {
          return UserProfile.fromJson(retryData);
        }
        return _fallbackProfile(userId);
      }

      return UserProfile.fromJson(data);
    } on PostgrestException catch (e, stack) {
      debugPrint('❌ getProfile error: $e');
      debugPrint('❌ getProfile stack: $stack');
      if (_isMissingProfilesTableError(e)) {
        debugPrint('⚠️ getProfile: profiles table missing, using auth fallback');
        return _fallbackProfile(userId);
      }

      // If profile fetch fails, try to create it
      await _ensureProfileExists(
        userId: userId,
        email: currentUser?.email ?? '',
        name: currentUser?.userMetadata?['name'] as String? ?? '',
      );
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ getProfile error: $e');
      debugPrint('❌ getProfile stack: $stack');
      return _fallbackProfile(userId);
    }
  }

  // ── Update Profile ────────────────────────────────────
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _client.from('profiles').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) {
        debugPrint('⚠️ updateProfile skipped: profiles table missing');
        return;
      }
      if (e.message.contains('is_phone_verified') || e.message.contains('is_email_verified') || e.code == 'PGRST204') {
        final cleanUpdates = Map<String, dynamic>.from(updates)
          ..remove('is_phone_verified')
          ..remove('is_email_verified');
        if (cleanUpdates.isNotEmpty) {
          await _client.from('profiles').update(cleanUpdates).eq('id', userId);
          return;
        }
      }
      rethrow;
    }
  }

  // ── Verify Old Password ───────────────────────────────
  Future<bool> verifyOldPassword(String oldPassword) async {
    final email = currentUser?.email;
    if (email == null) return false;
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Check if Phone Number is Unique ──────────────────
  Future<bool> checkPhoneUnique(String phone) async {
    final userId = currentUserId;
    if (userId == null) return true;
    
    final cleanedPhone = phone.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (cleanedPhone.isEmpty) return true;

    try {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('phone', cleanedPhone)
          .neq('id', userId)
          .maybeSingle();

      return data == null;
    } catch (e) {
      debugPrint('Check phone unique error: $e');
      return true;
    }
  }

  // ── Ensure Profile Exists (Fallback) ──────────────────
  Future<void> _ensureProfileExists({
    required String userId,
    String email = '',
    String name = '',
    String? phone,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final isAdminUser = normalizedEmail == AppConstants.adminEmail;
      // Check if profile already exists
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      final actualPhone = phone ?? currentUser?.phone;

      if (existing == null) {
        // Create the profile
        try {
          await _client.from('profiles').insert({
            'id': userId,
            'name': name.isEmpty ? (actualPhone ?? 'User') : name,
            'email': email,
            'phone': actualPhone,
            'is_phone_verified': true,
            'role': isAdminUser ? 'admin' : 'customer',
          });
        } on PostgrestException catch (insertErr) {
          if (insertErr.message.contains('is_phone_verified') || insertErr.code == 'PGRST204') {
            await _client.from('profiles').insert({
              'id': userId,
              'name': name.isEmpty ? (actualPhone ?? 'User') : name,
              'email': email,
              'phone': actualPhone,
              'role': isAdminUser ? 'admin' : 'customer',
            });
          } else {
            rethrow;
          }
        }
      } else {
        try {
          await _client.from('profiles').update({
            'phone': ?actualPhone,
            'is_phone_verified': true,
          }).eq('id', userId);
        } on PostgrestException catch (updateErr) {
          if (updateErr.message.contains('is_phone_verified') || updateErr.code == 'PGRST204') {
            await _client.from('profiles').update({
              'phone': ?actualPhone,
            }).eq('id', userId);
          } else {
            rethrow;
          }
        }
        if (isAdminUser) {
          await _client.from('profiles').update({'role': 'admin'}).eq('id', userId);
        }
      }
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) {
        debugPrint('⚠️ ensureProfileExists skipped: profiles table missing');
        return;
      }
      print('ensureProfileExists fallback: $e');
    }
  }

  bool _isMissingProfilesTableError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42P01' ||
        message.contains('public.profiles') ||
        message.contains('could not find the table');
  }

  UserProfile _fallbackProfile(String userId) {
    final user = currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['name'] ?? metadata['full_name'] ?? '')
        .toString()
        .trim();

    return UserProfile(
      id: userId,
      name: name.isEmpty ? (user?.email ?? 'User') : name,
      email: user?.email ?? '',
      avatarUrl: metadata['avatar_url']?.toString(),
      createdAt: DateTime.now(),
    );
  }
}
