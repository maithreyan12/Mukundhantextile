import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class CartRepository {
  final SupabaseClient _client;

  CartRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Get Cart Items ────────────────────────────────────
  Future<List<CartItem>> getCartItems() async {
    final data = await _client
        .from('cart_items')
        .select('*, products(*, categories(name))')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => CartItem.fromJson(e)).toList();
  }

  // ── Add to Cart ───────────────────────────────────────
  Future<void> addToCart({
    required String productId,
    int quantity = 1,
    Map<String, dynamic>? variant,
  }) async {
    await _client.from('cart_items').upsert(
      {
        'user_id': _userId,
        'product_id': productId,
        'quantity': quantity,
        'variant': variant,
      },
      onConflict: 'user_id, product_id, variant',
    );
  }

  // ── Update Quantity ───────────────────────────────────
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity}).eq('id', cartItemId);
  }

  // ── Remove Item ───────────────────────────────────────
  Future<void> removeItem(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  // ── Clear Cart ────────────────────────────────────────
  Future<void> clearCart() async {
    await _client.from('cart_items').delete().eq('user_id', _userId);
  }

  // ── Cart Count ────────────────────────────────────────
  Future<int> getCartCount() async {
    final data = await _client
        .from('cart_items')
        .select('id')
        .eq('user_id', _userId);
    return (data as List).length;
  }
}
