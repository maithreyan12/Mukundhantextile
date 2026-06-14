import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

// ── Context Extensions ─────────────────────────────────
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Dynamic primary color from selected theme
  Color get primaryColor => colorScheme.primary;
  /// Dynamic accent/secondary color from selected theme
  Color get accentColor => colorScheme.secondary;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2ED573),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── String Extensions ──────────────────────────────────
extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');
}

// ── Num Extensions ─────────────────────────────────────
extension NumExtensions on num {
  String get toCurrency =>
      '${AppConstants.currency}${NumberFormat('#,##0.00').format(this)}';

  String get toCurrencyCompact =>
      '${AppConstants.currency}${NumberFormat.compact().format(this)}';
}

// ── DateTime Extensions ────────────────────────────────
extension DateTimeExtensions on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedWithTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
