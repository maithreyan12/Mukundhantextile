import 'package:flutter/material.dart';
import 'theme_cubit.dart';

class AppTheme {
  AppTheme._();

  // ── Functional Colors ──────────────────────────────────
  static const Color _errorColor = Color(0xFFFF4C4C);
  static const Color _successColor = Color(0xFF2ED573);
  static const Color _warningColor = Color(0xFFFF9F43);

  static Color get error => _errorColor;
  static Color get success => _successColor;
  static Color get warning => _warningColor;

  // ── Border Radius ──────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // ── Generate Light Theme from Color ────────────────────
  static ThemeData lightTheme(AppColorTheme ct) {
    final onPrimary = ct.isLight ? const Color(0xFF1A1A1A) : Colors.white;
    final colorScheme = ColorScheme.light(
      primary: ct.primary,
      onPrimary: onPrimary,
      secondary: ct.accent,
      onSecondary: Colors.white,
      tertiary: ct.primaryLight,
      surface: const Color(0xFFF5F7FA),
      onSurface: const Color(0xFF1A1A1A),
      error: _errorColor,
      onError: Colors.white,
      outline: const Color(0xFFCDD5E0),
    );
    return _buildTheme(colorScheme, Brightness.light, ct);
  }

  // ── Generate Dark Theme from Color ─────────────────────
  static ThemeData darkTheme(AppColorTheme ct) {
    final onPrimaryDark = _brightenColor(ct.primary, 0.6);
    final colorScheme = ColorScheme.dark(
      primary: onPrimaryDark,
      onPrimary: Colors.white,
      secondary: ct.accent,
      onSecondary: Colors.white,
      tertiary: ct.primaryLight,
      surface: ct.primaryDark,
      onSurface: const Color(0xFFF5F5F5),
      error: _errorColor,
      onError: Colors.white,
      outline: Color.lerp(ct.primaryDark, Colors.white, 0.15)!,
    );
    return _buildTheme(colorScheme, Brightness.dark, ct);
  }

  /// Brighten a color for dark mode readability
  static Color _brightenColor(Color c, double amount) {
    return Color.lerp(c, Colors.white, amount)!;
  }

  static ThemeData _buildTheme(ColorScheme cs, Brightness brightness, AppColorTheme ct) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _buildTextTheme(isDark, ct);
    final cardColor = isDark
        ? Color.lerp(ct.primaryDark, Colors.white, 0.08)!
        : Colors.white;
    final subtitleColor = isDark
        ? const Color(0xFF8E99A4)
        : const Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: cs.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? ct.primaryDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : ct.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(
            color: isDark
                ? Color.lerp(ct.primaryDark, Colors.white, 0.1)!
                : const Color(0xFFE5EAF0),
            width: 1.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // Elevated Buttons — Premium pill shape
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ct.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: ct.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 15,
          ),
        ),
      ),

      // Outlined Buttons — Premium pill shape
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : ct.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          side: BorderSide(
            color: isDark ? cs.primary.withValues(alpha: 0.5) : ct.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 14,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? cs.primary : ct.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF0F3F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: _errorColor),
        ),
        hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? ct.primaryDark : Colors.white,
        selectedItemColor: isDark ? cs.primary : ct.primary,
        unselectedItemColor: subtitleColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? cardColor : Color.lerp(ct.primary, Colors.white, 0.92)!,
        selectedColor: ct.primary,
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: BorderSide(color: cs.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark
            ? Color.lerp(ct.primaryDark, Colors.white, 0.1)!
            : const Color(0xFFE5EAF0),
        thickness: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? ct.primaryDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ct.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? cs.primary : ct.primary,
        unselectedLabelColor: subtitleColor,
        indicatorColor: isDark ? cs.primary : ct.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ct.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark, AppColorTheme ct) {
    // Light mode: always dark text for readability
    // Dark mode: always light text for readability
    final color = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtitle = isDark
        ? const Color(0xFF8E99A4)
        : const Color(0xFF6B7280);

    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subtitle),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitle),
    );
  }
}
