import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Get All Users (admin) ─────────────────────────────
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => UserProfile.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) {
        return const <UserProfile>[];
      }
      rethrow;
    }
  }

  // ── Get User Profile ──────────────────────────────────
  Future<UserProfile> getUser(String id) async {
    try {
      final data = await _client.from('profiles').select().eq('id', id).single();
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) {
        return UserProfile(
          id: id,
          name: 'User',
          email: '',
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  // ── Ban / Unban User ──────────────────────────────────
  Future<void> toggleBan(String userId, bool ban) async {
    try {
      await _client
          .from('profiles')
          .update({'is_banned': ban}).eq('id', userId);
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) return;
      rethrow;
    }
  }

  // ── User Count ────────────────────────────────────────
  Future<int> getUserCount() async {
    try {
      final data = await _client.from('profiles').select('id');
      return (data as List).length;
    } on PostgrestException catch (e) {
      if (_isMissingProfilesTableError(e)) return 0;
      rethrow;
    }
  }

  bool _isMissingProfilesTableError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42P01' ||
        message.contains('public.profiles') ||
        message.contains('could not find the table');
  }
}
