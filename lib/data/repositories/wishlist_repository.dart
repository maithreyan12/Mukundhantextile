import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class WishlistRepository {
  final SupabaseClient _client;

  WishlistRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Get Wishlist ──────────────────────────────────────
  Future<List<Product>> getWishlist() async {
    final data = await _client
        .from('wishlist')
        .select('product_id, products(*, categories(name))')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (data as List)
        .where((e) => e['products'] != null)
        .map((e) => Product.fromJson(e['products'] as Map<String, dynamic>))
        .toList();
  }

  // ── Add to Wishlist ───────────────────────────────────
  Future<void> addToWishlist(String productId) async {
    await _client.from('wishlist').upsert(
      {'user_id': _userId, 'product_id': productId},
      onConflict: 'user_id, product_id',
    );
  }

  // ── Remove from Wishlist ──────────────────────────────
  Future<void> removeFromWishlist(String productId) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', productId);
  }

  // ── Check if in Wishlist ──────────────────────────────
  Future<bool> isInWishlist(String productId) async {
    final data = await _client
        .from('wishlist')
        .select('id')
        .eq('user_id', _userId)
        .eq('product_id', productId);
    return (data as List).isNotEmpty;
  }

  // ── Get Wishlist IDs ──────────────────────────────────
  Future<Set<String>> getWishlistIds() async {
    final data = await _client
        .from('wishlist')
        .select('product_id')
        .eq('user_id', _userId);
    return (data as List)
        .map((e) => e['product_id'] as String)
        .toSet();
  }
}
