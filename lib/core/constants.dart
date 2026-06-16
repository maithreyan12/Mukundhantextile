import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String adminEmail = 'mukundhantextile@gmail.com';

  // ── Supabase (loaded from .env file) ───────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ── Storage Buckets ───────────────────────────────────
  static const String productImagesBucket = 'product-images';
  static const String categoryImagesBucket = 'category-images';
  static const String bannerImagesBucket = 'banner-images';
  static const String avatarsBucket = 'avatars';

  // ── App Info ──────────────────────────────────────────
  static const String appName = "Mugundhan Tex & Readymades";
  static const String appTagline = 'Shop Smart, Live Better';
  static const String currency = '₹';
  static const String appVersion = '1.0.0';

  // ── Contact Info ─────────────────────────────────────
  static const String contactPhone = '96777 81159';
  static const String contactAddress =
      '22, Chennai-Bangalore Road, Kilmonavur, Vellore 632 013';
  static const String storeMapUrl =
      'https://maps.app.goo.gl/FkS3Pras5srMkBc86?g_st=iw';


  // ── Pagination ────────────────────────────────────────
  static const int pageSize = 20;

  // ── Payment Methods ───────────────────────────────────
  static const List<String> paymentMethods = [
    'cod',
    'credit_card',
    'upi',
  ];

  static String paymentMethodLabel(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'credit_card':
        return 'Credit / Debit Card';
      case 'upi':
        return 'UPI';
      default:
        return method;
    }
  }
}
