import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address.dart';

class AddressRepository {
  final SupabaseClient _client;

  AddressRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Get User Addresses ────────────────────────────────
  Future<List<Address>> getAddresses() async {
    final data = await _client
        .from('addresses')
        .select()
        .eq('user_id', _userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Address.fromJson(e)).toList();
  }

  // ── Add Address ───────────────────────────────────────
  Future<Address> addAddress(Map<String, dynamic> data) async {
    data['user_id'] = _userId;

    // If this is set as default, unset others
    if (data['is_default'] == true) {
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', _userId);
    }

    final result =
        await _client.from('addresses').insert(data).select().single();
    return Address.fromJson(result);
  }

  // ── Update Address ────────────────────────────────────
  Future<Address> updateAddress(
      String id, Map<String, dynamic> data) async {
    if (data['is_default'] == true) {
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', _userId);
    }

    final result = await _client
        .from('addresses')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Address.fromJson(result);
  }

  // ── Delete Address ────────────────────────────────────
  Future<void> deleteAddress(String id) async {
    await _client.from('addresses').delete().eq('id', id);
  }

  // ── Get Default Address ───────────────────────────────
  Future<Address?> getDefaultAddress() async {
    try {
      final data = await _client
          .from('addresses')
          .select()
          .eq('user_id', _userId)
          .eq('is_default', true)
          .single();
      return Address.fromJson(data);
    } catch (_) {
      // Try getting any address
      try {
        final data = await _client
            .from('addresses')
            .select()
            .eq('user_id', _userId)
            .limit(1)
            .single();
        return Address.fromJson(data);
      } catch (_) {
        return null;
      }
    }
  }
}
