import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 12 Brand Color Themes for Mugundhan Textiles
class AppColorTheme {
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final bool isLight; // true = light primary (needs dark text on it)

  const AppColorTheme({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    this.isLight = false,
  });
}

class AppColorThemes {
  static const List<AppColorTheme> all = [
    // 1. Navy Blue & Red (Original Brand)
    AppColorTheme(
      name: 'Navy Classic',
      emoji: '🔵',
      primary: Color(0xFF1B2A4A),
      primaryDark: Color(0xFF0D1321),
      primaryLight: Color(0xFF2C3E6B),
      accent: Color(0xFFD32F2F),
    ),
    // 2. Royal Purple
    AppColorTheme(
      name: 'Royal Purple',
      emoji: '💜',
      primary: Color(0xFF4A148C),
      primaryDark: Color(0xFF1A0033),
      primaryLight: Color(0xFF7B1FA2),
      accent: Color(0xFFFF6F00),
    ),
    // 3. Forest Green
    AppColorTheme(
      name: 'Forest Green',
      emoji: '🌿',
      primary: Color(0xFF1B5E20),
      primaryDark: Color(0xFF0D2B10),
      primaryLight: Color(0xFF2E7D32),
      accent: Color(0xFFFF8F00),
    ),
    // 4. Ocean Teal
    AppColorTheme(
      name: 'Ocean Teal',
      emoji: '🌊',
      primary: Color(0xFF006064),
      primaryDark: Color(0xFF00363A),
      primaryLight: Color(0xFF00838F),
      accent: Color(0xFFFF5252),
    ),
    // 5. Crimson Red
    AppColorTheme(
      name: 'Crimson Red',
      emoji: '❤️',
      primary: Color(0xFFB71C1C),
      primaryDark: Color(0xFF5F0F0F),
      primaryLight: Color(0xFFD32F2F),
      accent: Color(0xFF1565C0),
    ),
    // 6. Charcoal Black
    AppColorTheme(
      name: 'Charcoal Black',
      emoji: '⚫',
      primary: Color(0xFF212121),
      primaryDark: Color(0xFF0D0D0D),
      primaryLight: Color(0xFF424242),
      accent: Color(0xFFFF9800),
    ),
    // 7. Rose Pink
    AppColorTheme(
      name: 'Rose Pink',
      emoji: '🌸',
      primary: Color(0xFF880E4F),
      primaryDark: Color(0xFF4A0028),
      primaryLight: Color(0xFFAD1457),
      accent: Color(0xFF00BFA5),
    ),
    // 8. Sunset Orange
    AppColorTheme(
      name: 'Sunset Orange',
      emoji: '🌅',
      primary: Color(0xFFBF360C),
      primaryDark: Color(0xFF6E1E06),
      primaryLight: Color(0xFFE64A19),
      accent: Color(0xFF0277BD),
    ),
    // 9. Steel Blue
    AppColorTheme(
      name: 'Steel Blue',
      emoji: '💎',
      primary: Color(0xFF0D47A1),
      primaryDark: Color(0xFF062558),
      primaryLight: Color(0xFF1565C0),
      accent: Color(0xFFFF6D00),
    ),
    // 10. Olive Gold
    AppColorTheme(
      name: 'Olive Gold',
      emoji: '✨',
      primary: Color(0xFF33691E),
      primaryDark: Color(0xFF1A3A0F),
      primaryLight: Color(0xFF558B2F),
      accent: Color(0xFFFFC107),
    ),
    // 11. Deep Indigo
    AppColorTheme(
      name: 'Deep Indigo',
      emoji: '🔮',
      primary: Color(0xFF1A237E),
      primaryDark: Color(0xFF0D1047),
      primaryLight: Color(0xFF283593),
      accent: Color(0xFFFF4081),
    ),
    // 12. Coffee Brown
    AppColorTheme(
      name: 'Coffee Brown',
      emoji: '☕',
      primary: Color(0xFF3E2723),
      primaryDark: Color(0xFF1B1210),
      primaryLight: Color(0xFF5D4037),
      accent: Color(0xFF26A69A),
    ),

    // ── LIGHT / BRIGHT COLORS ─────────────────────────────
    // 13. Sunshine Yellow
    AppColorTheme(
      name: 'Sunshine Yellow',
      emoji: '☀️',
      primary: Color(0xFFFDD835),
      primaryDark: Color(0xFF5C4C00),
      primaryLight: Color(0xFFFFF176),
      accent: Color(0xFF1565C0),
      isLight: true,
    ),
    // 14. Lime Green
    AppColorTheme(
      name: 'Lime Green',
      emoji: '🍀',
      primary: Color(0xFF7CB342),
      primaryDark: Color(0xFF2E5014),
      primaryLight: Color(0xFF9CCC65),
      accent: Color(0xFFE91E63),
      isLight: true,
    ),
    // 15. Sky Blue
    AppColorTheme(
      name: 'Sky Blue',
      emoji: '🩵',
      primary: Color(0xFF29B6F6),
      primaryDark: Color(0xFF0B3D5B),
      primaryLight: Color(0xFF4FC3F7),
      accent: Color(0xFFFF7043),
      isLight: true,
    ),
    // 16. Coral
    AppColorTheme(
      name: 'Coral',
      emoji: '🪸',
      primary: Color(0xFFFF7043),
      primaryDark: Color(0xFF5C2510),
      primaryLight: Color(0xFFFF8A65),
      accent: Color(0xFF26A69A),
      isLight: true,
    ),
    // 17. Lavender
    AppColorTheme(
      name: 'Lavender',
      emoji: '💐',
      primary: Color(0xFFAB47BC),
      primaryDark: Color(0xFF3C1053),
      primaryLight: Color(0xFFCE93D8),
      accent: Color(0xFF66BB6A),
      isLight: true,
    ),
    // 18. Mint Fresh
    AppColorTheme(
      name: 'Mint Fresh',
      emoji: '🌱',
      primary: Color(0xFF26A69A),
      primaryDark: Color(0xFF0D3B36),
      primaryLight: Color(0xFF4DB6AC),
      accent: Color(0xFFEF5350),
      isLight: true,
    ),
    // 19. Peach
    AppColorTheme(
      name: 'Peach',
      emoji: '🍑',
      primary: Color(0xFFFF8A65),
      primaryDark: Color(0xFF5C3020),
      primaryLight: Color(0xFFFFAB91),
      accent: Color(0xFF5C6BC0),
      isLight: true,
    ),
    // 20. Hot Pink
    AppColorTheme(
      name: 'Hot Pink',
      emoji: '💗',
      primary: Color(0xFFEC407A),
      primaryDark: Color(0xFF5C1030),
      primaryLight: Color(0xFFF06292),
      accent: Color(0xFF00BCD4),
      isLight: true,
    ),
    // 21. Turquoise
    AppColorTheme(
      name: 'Turquoise',
      emoji: '🧊',
      primary: Color(0xFF00BCD4),
      primaryDark: Color(0xFF004D56),
      primaryLight: Color(0xFF4DD0E1),
      accent: Color(0xFFFF5722),
      isLight: true,
    ),
    // 22. Amber Gold
    AppColorTheme(
      name: 'Amber Gold',
      emoji: '🥇',
      primary: Color(0xFFFFA000),
      primaryDark: Color(0xFF5C3C00),
      primaryLight: Color(0xFFFFCA28),
      accent: Color(0xFF7B1FA2),
      isLight: true,
    ),
    // 23. Violet
    AppColorTheme(
      name: 'Violet',
      emoji: '🔮',
      primary: Color(0xFF7E57C2),
      primaryDark: Color(0xFF2E1A4A),
      primaryLight: Color(0xFF9575CD),
      accent: Color(0xFFFFB300),
      isLight: true,
    ),
    // 24. Aqua Green
    AppColorTheme(
      name: 'Aqua Green',
      emoji: '🐸',
      primary: Color(0xFF66BB6A),
      primaryDark: Color(0xFF1B4A1E),
      primaryLight: Color(0xFF81C784),
      accent: Color(0xFFE91E63),
      isLight: true,
    ),
  ];
}

/// State for theme management
class ThemeState {
  final ThemeMode themeMode;
  final int colorIndex;

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.colorIndex = 0,
  });

  AppColorTheme get colorTheme => AppColorThemes.all[colorIndex];

  ThemeState copyWith({ThemeMode? themeMode, int? colorIndex}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState()) {
    _loadThemeFromSupabase();
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Load the global theme from Supabase app_settings table
  Future<void> _loadThemeFromSupabase() async {
    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('key', 'app_theme')
          .maybeSingle();

      if (response != null) {
        final value = response['value'] as Map<String, dynamic>;
        final modeIndex = value['theme_mode'] as int? ?? 2;
        final colorIndex = value['color_index'] as int? ?? 0;
        final mode = ThemeMode.values[modeIndex.clamp(0, 2)];
        final safeColorIndex = colorIndex.clamp(0, AppColorThemes.all.length - 1);
        emit(ThemeState(themeMode: mode, colorIndex: safeColorIndex));
      }
    } catch (e) {
      // If table doesn't exist or error, use defaults
      debugPrint('⚠️ Theme load error (using defaults): $e');
    }
  }

  /// Save theme to Supabase (admin only)
  Future<void> _saveToSupabase() async {
    try {
      await _client.from('app_settings').upsert({
        'key': 'app_theme',
        'value': {
          'theme_mode': state.themeMode.index,
          'color_index': state.colorIndex,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      debugPrint('⚠️ Theme save error: $e');
    }
  }

  /// Set theme mode (admin only)
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _saveToSupabase();
  }

  /// Set color theme (admin only)
  Future<void> setColorTheme(int index) async {
    if (index < 0 || index >= AppColorThemes.all.length) return;
    emit(state.copyWith(colorIndex: index));
    await _saveToSupabase();
  }

  /// Toggle between light and dark
  void toggleTheme() {
    setThemeMode(
      state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  /// Refresh theme from server (called when non-admin user opens app)
  Future<void> refreshFromServer() async {
    await _loadThemeFromSupabase();
  }
}
