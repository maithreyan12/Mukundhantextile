import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewRepository {
  final SupabaseClient _client;

  ReviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Get Product Reviews ───────────────────────────────
  Future<List<Review>> getProductReviews(String productId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  // ── Add Review ────────────────────────────────────────
  Future<void> addReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    await _client.from('reviews').upsert(
      {
        'user_id': _userId,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      },
      onConflict: 'user_id, product_id',
    );
  }

  // ── Get User Review for Product ───────────────────────
  Future<Review?> getUserReview(String productId) async {
    try {
      final data = await _client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .eq('user_id', _userId)
          .single();
      return Review.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── Delete Review ─────────────────────────────────────
  Future<void> deleteReview(String id) async {
    await _client.from('reviews').delete().eq('id', id);
  }
}
