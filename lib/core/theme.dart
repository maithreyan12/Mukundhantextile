import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette ─────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D0D0D); // Deep Black
  static const Color _primaryLight = Color(0xFFEAEAEA); // Off-white
  static const Color _accent = Color(0xFFEAEAEA); // Off-white Primary
  static const Color _accentLight = Color(0xFF2979FF); // Electric Blue (Subtle)
  static const Color _errorColor = Color(0xFFFF4C4C);
  static const Color _successColor = Color(0xFF2ED573);
  static const Color _warningColor = Color(0xFFFF9F43);
  
  static const Color _surfaceDark = Color(0xFF141414);
  static const Color _surfaceLight = Color(0xFFF1F1F1);
  static const Color _cardDark = Color(0xFF1C1C1C);
  static const Color _cardLight = Color(0xFFFFFFFF);
  
  static const Color _textDark = Color(0xFFF5F5F5); // White/Light Grey
  static const Color _textLight = Color(0xFF121212);
  static const Color _subtitleDark = Color(0xFFA0A0A0);
  static const Color _subtitleLight = Color(0xFF6B7280);

  static Color get accent => _accent;
  static Color get error => _errorColor;
  static Color get success => _successColor;
  static Color get warning => _warningColor;

  // ── Border Radius (12-20 as requested) ────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // ── Light Theme ───────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.black,
      secondary: _accentLight,
      onSecondary: Colors.black,
      surface: _surfaceLight,
      onSurface: _textLight,
      error: _errorColor,
      onError: Colors.white,
      outline: const Color(0xFFD1D1D1),
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ── Dark Theme (Streetwear Default) ───────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: _primaryLight,
      onPrimary: Colors.black,
      secondary: _accentLight,
      onSecondary: Colors.black,
      surface: _primaryDark,
      onSurface: _textDark,
      error: _errorColor,
      onError: Colors.white,
      outline: const Color(0xFF222222),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _buildTextTheme(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? _textDark : _textLight,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800, // Bolder for streetwear
          letterSpacing: 1.0,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: isDark ? _cardDark : _cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(
            color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
            width: 1.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black, // Stark contrast
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
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
            : Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: _errorColor),
        ),
        hintStyle: TextStyle(
          color: isDark ? _subtitleDark : _subtitleLight,
          fontSize: 14,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: _accentLight, // Electric Blue Active Tab
        unselectedItemColor: isDark ? _subtitleDark : _subtitleLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1C)
            : Colors.grey.shade100,
        selectedColor: _accent,
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black, // Dark text on selected neon green
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF262626) : Colors.grey.shade200,
        thickness: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? _cardDark : _cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? _surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFF333333),
        contentTextStyle: TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: _accent,
        unselectedLabelColor: isDark ? _subtitleDark : _subtitleLight,
        indicatorColor: _accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final color = isDark ? _textDark : _textLight;
    final subtitle = isDark ? _subtitleDark : _subtitleLight;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtitle,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: subtitle,
      ),
    );
  }
}
