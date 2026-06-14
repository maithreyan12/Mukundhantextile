import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final Map<String, dynamic>? variant;
  final Product? product;
  final DateTime createdAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.quantity = 1,
    this.variant,
    this.product,
    required this.createdAt,
  });

  double get totalPrice {
    if (product == null) return 0;
    return product!.effectivePrice * quantity;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      variant: json['variant'] as Map<String, dynamic>?,
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'variant': variant,
      };

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      userId: userId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      variant: variant,
      product: product,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, productId, quantity, variant];
}
