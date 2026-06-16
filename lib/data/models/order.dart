import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;
}

class Order extends Equatable {
  final String id;
  final String userId;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final OrderStatus status;
  final String paymentMethod;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    this.discountAmount = 0,
    this.couponCode,
    this.status = OrderStatus.pending,
    this.paymentMethod = 'cod',
    this.shippingAddress = const {},
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  double get finalAmount => totalAmount - discountAmount;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      couponCode: json['coupon_code'] as String?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      shippingAddress:
          Map<String, dynamic>.from(json['shipping_address'] as Map? ?? {}),
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      shippedAt: json['shipped_at'] != null
          ? DateTime.parse(json['shipped_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'total_amount': totalAmount,
        'discount_amount': discountAmount,
        'coupon_code': couponCode,
        'status': status.name,
        'payment_method': paymentMethod,
        'shipping_address': shippingAddress,
        'confirmed_at': confirmedAt?.toIso8601String(),
        'shipped_at': shippedAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
      };

  Order copyWith({
    OrderStatus? status,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id,
      userId: userId,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      couponCode: couponCode,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      items: items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        totalAmount,
        status,
        createdAt,
        confirmedAt,
        shippedAt,
        deliveredAt
      ];
}
