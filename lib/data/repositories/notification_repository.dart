import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Get Notifications ─────────────────────────────────
  Future<List<NotificationModel>> getNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  // ── Mark as Read ──────────────────────────────────────
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id', id);
  }

  // ── Mark All as Read ──────────────────────────────────
  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }

  // ── Unread Count ──────────────────────────────────────
  Future<int> getUnreadCount() async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', _userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  // ── Admin: Create Notification ────────────────────────
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
    });
  }
}
