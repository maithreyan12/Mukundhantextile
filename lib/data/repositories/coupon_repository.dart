import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon.dart';

class CouponRepository {
  final SupabaseClient _client;

  CouponRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Validate Coupon ───────────────────────────────────
  Future<Coupon?> validateCoupon(String code) async {
    try {
      final data = await _client
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .single();
      final coupon = Coupon.fromJson(data);
      if (!coupon.isValid) return null;
      return coupon;
    } catch (_) {
      return null;
    }
  }

  // ── Get All Coupons (admin) ───────────────────────────
  Future<List<Coupon>> getAllCoupons() async {
    final data = await _client
        .from('coupons')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Coupon.fromJson(e)).toList();
  }

  // ── Create Coupon ─────────────────────────────────────
  Future<Coupon> createCoupon(Map<String, dynamic> data) async {
    data['code'] = (data['code'] as String).toUpperCase();
    final result =
        await _client.from('coupons').insert(data).select().single();
    return Coupon.fromJson(result);
  }

  // ── Update Coupon ─────────────────────────────────────
  Future<Coupon> updateCoupon(String id, Map<String, dynamic> data) async {
    if (data.containsKey('code')) {
      data['code'] = (data['code'] as String).toUpperCase();
    }
    final result = await _client
        .from('coupons')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Coupon.fromJson(result);
  }

  // ── Delete Coupon ─────────────────────────────────────
  Future<void> deleteCoupon(String id) async {
    await _client.from('coupons').delete().eq('id', id);
  }
}
