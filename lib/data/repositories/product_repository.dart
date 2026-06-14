import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Fetch Products (paginated) ────────────────────────
  Future<List<Product>> getProducts({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
    double? minPrice,
    double? maxPrice,
  }) async {
    var query = _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    final data = await query
        .order(sortBy, ascending: ascending)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // ── Get Single Product ────────────────────────────────
  Future<Product> getProduct(String id) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('id', id)
        .single();
    return Product.fromJson(data);
  }

  // ── Featured / Best Sellers / New Arrivals ────────────
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('rating', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getNewArrivals({int limit = 10}) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getBestSellers({int limit = 10}) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('review_count', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // ── Admin: All Products ───────────────────────────────
  Future<List<Product>> getAllProducts({
    int page = 0,
    int pageSize = 20,
  }) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // ── Admin: Create Product ─────────────────────────────
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final result =
        await _client.from('products').insert(data).select('*, categories(name)').single();
    return Product.fromJson(result);
  }

  // ── Admin: Update Product ─────────────────────────────
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final result = await _client
        .from('products')
        .update(data)
        .eq('id', id)
        .select('*, categories(name)')
        .single();
    return Product.fromJson(result);
  }

  // ── Admin: Delete Product ─────────────────────────────
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ── Admin: Toggle Active ──────────────────────────────
  Future<void> toggleActive(String id, bool isActive) async {
    await _client.from('products').update({'is_active': isActive}).eq('id', id);
  }

  // ── Low Stock Products ────────────────────────────────
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .lte('stock', threshold)
        .order('stock', ascending: true)
        .limit(20);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }
}
