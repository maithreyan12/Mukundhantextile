import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Get Active Categories ─────────────────────────────
  Future<List<Category>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  // ── Get All Categories (admin) ────────────────────────
  Future<List<Category>> getAllCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  // ── Create Category ───────────────────────────────────
  Future<Category> createCategory(Map<String, dynamic> data) async {
    final result =
        await _client.from('categories').insert(data).select().single();
    return Category.fromJson(result);
  }

  // ── Update Category ───────────────────────────────────
  Future<Category> updateCategory(
      String id, Map<String, dynamic> data) async {
    final result = await _client
        .from('categories')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Category.fromJson(result);
  }

  // ── Delete Category ───────────────────────────────────
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
