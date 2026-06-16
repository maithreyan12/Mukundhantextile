import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/browse_settings.dart';

class BrowseSettingsRepository {
  final SupabaseClient _client;
  static const String _settingsId = 'popular_store_settings';

  // Cache settings in memory so we don't have to query Supabase continuously
  BrowseSettings? _cachedSettings;

  BrowseSettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<BrowseSettings> getSettings() async {
    try {
      final data = await _client
          .from('browse_settings')
          .select()
          .eq('id', _settingsId)
          .maybeSingle();

      if (data != null) {
        final settings = BrowseSettings.fromJson(data);
        _cachedSettings = settings;
        return settings;
      } else {
        // Table exists, but no row. Create default row.
        final defaultSettings = const BrowseSettings(id: _settingsId);
        try {
          await _client.from('browse_settings').insert(defaultSettings.toJson());
        } catch (e) {
          debugPrint('⚠️ BrowseSettingsRepository: Failed to insert default row: $e');
        }
        _cachedSettings = defaultSettings;
        return defaultSettings;
      }
    } catch (e) {
      debugPrint('⚠️ BrowseSettingsRepository: Failed to load from database, using fallback defaults. Error: $e');
      // Return cached settings or default fallback settings
      return _cachedSettings ?? const BrowseSettings(id: _settingsId);
    }
  }

  Future<void> updateSettings(BrowseSettings settings) async {
    try {
      await _client.from('browse_settings').upsert(settings.toJson());
      _cachedSettings = settings;
    } catch (e) {
      debugPrint('❌ BrowseSettingsRepository: Failed to save settings to database: $e');
      // Update local cache anyway so it works for the session
      _cachedSettings = settings;
      throw Exception('Database save failed. Make sure the table "browse_settings" exists in your Supabase database. Error: $e');
    }
  }

  /// Helper to check if the database table exists by querying it.
  Future<bool> checkTableExists() async {
    try {
      await _client.from('browse_settings').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
