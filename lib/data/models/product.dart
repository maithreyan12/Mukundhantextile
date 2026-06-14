import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String? categoryId;
  final String? categoryName;
  final int stock;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final List<Map<String, dynamic>> variants;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.discountPrice,
    this.categoryId,
    this.categoryName,
    this.stock = 0,
    this.images = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    this.variants = const [],
    required this.createdAt,
  });

  double get effectivePrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';

  bool get inStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : null,
      stock: json['stock'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'discount_price': discountPrice,
        'category_id': categoryId,
        'stock': stock,
        'images': images,
        'is_active': isActive,
        'variants': variants,
      };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? categoryId,
    int? stock,
    List<String>? images,
    bool? isActive,
    List<Map<String, dynamic>>? variants,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      rating: rating,
      reviewCount: reviewCount,
      isActive: isActive ?? this.isActive,
      variants: variants ?? this.variants,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, price, discountPrice, stock, isActive];
}
