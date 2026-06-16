import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String? comment;
  final String? userName;
  final String? userAvatar;
  final String? productName;
  final String? productImage;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    this.userName,
    this.userAvatar,
    this.productName,
    this.productImage,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final product = json['products'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      userName: profile?['name'] as String?,
      userAvatar: profile?['avatar_url'] as String?,
      productName: product?['name'] as String?,
      productImage: product?['image_url'] as String?,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      };

  @override
  List<Object?> get props => [id, userId, productId, rating];
}
