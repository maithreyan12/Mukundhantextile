import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final Map<String, dynamic>? variant;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    this.variant,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      productImage: json['product_image'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      variant: json['variant'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'quantity': quantity,
        'price': price,
        'variant': variant,
      };

  @override
  List<Object?> get props => [id, orderId, productId, quantity, price];
}
