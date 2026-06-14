import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';

class BannerRepository {
  final SupabaseClient _client;

  BannerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Get Active Banners ────────────────────────────────
  Future<List<BannerModel>> getActiveBanners() async {
    final data = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (data as List).map((e) => BannerModel.fromJson(e)).toList();
  }

  // ── Get All Banners (admin) ───────────────────────────
  Future<List<BannerModel>> getAllBanners() async {
    final data = await _client
        .from('banners')
        .select()
        .order('sort_order', ascending: true);
    return (data as List).map((e) => BannerModel.fromJson(e)).toList();
  }

  // ── Create Banner ─────────────────────────────────────
  Future<BannerModel> createBanner(Map<String, dynamic> data) async {
    final result =
        await _client.from('banners').insert(data).select().single();
    return BannerModel.fromJson(result);
  }

  // ── Update Banner ─────────────────────────────────────
  Future<BannerModel> updateBanner(
      String id, Map<String, dynamic> data) async {
    final result = await _client
        .from('banners')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return BannerModel.fromJson(result);
  }

  // ── Delete Banner ─────────────────────────────────────
  Future<void> deleteBanner(String id) async {
    await _client.from('banners').delete().eq('id', id);
  }
}
