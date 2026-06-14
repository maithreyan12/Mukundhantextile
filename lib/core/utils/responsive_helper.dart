import 'package:flutter/material.dart';

/// Responsive breakpoints and helpers for desktop/tablet/mobile layouts.
class Responsive {
  Responsive._();

  // ── Breakpoints ───────────────────────────────────────
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1280;

  // ── Max Content Widths ────────────────────────────────
  static const double maxContentWidth = 1400;
  static const double maxFormWidth = 480;
  static const double maxDetailWidth = 1200;

  // ── Device Type Checks ────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Returns true for tablet and desktop
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  // ── Grid Column Counts ────────────────────────────────
  /// Product grid columns: 2 mobile, 3 tablet, 4-5 desktop
  static int productGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 5;
    if (w >= tabletBreakpoint) return 4;
    if (w >= mobileBreakpoint) return 3;
    return 2;
  }

  /// Product grid cross-axis extent based on screen width
  static double productGridMaxExtent(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 280;
    if (w >= tabletBreakpoint) return 260;
    if (w >= mobileBreakpoint) return 240;
    return 220;
  }

  /// Horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 48;
    if (w >= tabletBreakpoint) return 32;
    if (w >= mobileBreakpoint) return 24;
    return 16;
  }

  /// Returns a responsive value based on current screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }
}
