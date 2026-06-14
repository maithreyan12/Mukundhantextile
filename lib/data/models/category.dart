import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'image_url': imageUrl,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  Category copyWith({
    String? name,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, isActive, sortOrder];
}
