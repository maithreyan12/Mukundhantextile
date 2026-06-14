import 'package:equatable/equatable.dart';

class Coupon extends Equatable {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'flat'
  final double value;
  final double minOrderAmount;
  final DateTime? expiryDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    this.minOrderAmount = 0,
    this.expiryDate,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isUsageLimitReached => usageLimit > 0 && usedCount >= usageLimit;

  bool get isValid => isActive && !isExpired && !isUsageLimitReached;

  double calculateDiscount(double orderAmount) {
    if (!isValid || orderAmount < minOrderAmount) return 0;
    if (discountType == 'percentage') {
      return (orderAmount * value / 100).clamp(0, orderAmount);
    }
    return value.clamp(0, orderAmount);
  }

  String get discountLabel {
    if (discountType == 'percentage') return '${value.toInt()}% OFF';
    return '₹${value.toStringAsFixed(0)} OFF';
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      usageLimit: json['usage_limit'] as int? ?? 0,
      usedCount: json['used_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'discount_type': discountType,
        'value': value,
        'min_order_amount': minOrderAmount,
        'expiry_date': expiryDate?.toIso8601String(),
        'usage_limit': usageLimit,
        'is_active': isActive,
      };

  @override
  List<Object?> get props =>
      [id, code, discountType, value, isActive, expiryDate];
}
