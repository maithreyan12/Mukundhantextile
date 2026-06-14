import 'package:supabase_flutter/supabase_flutter.dart';

class Helpers {
  Helpers._();

  /// Get the authenticated Supabase client
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Get current user ID or null
  static String? get currentUserId => supabase.auth.currentUser?.id;

  /// Build a public URL for a storage file
  static String storageUrl(String bucket, String path) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Get order status label
  static String orderStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get order status step index (for stepper/timeline)
  static int orderStatusIndex(String status) {
    const statuses = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
    ];
    final i = statuses.indexOf(status);
    return i >= 0 ? i : 0;
  }

  /// Truncate a long text
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  /// Calculate discount percentage
  static int discountPercent(double price, double discountPrice) {
    if (price <= 0) return 0;
    return (((price - discountPrice) / price) * 100).round();
  }
}
