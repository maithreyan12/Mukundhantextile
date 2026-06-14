import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final String id;
  final String imageUrl;
  final String? title;
  final String? targetType; // 'product', 'category', 'url'
  final String? targetId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.targetType,
    this.targetId,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      title: json['title'] as String?,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'image_url': imageUrl,
        'title': title,
        'target_type': targetType,
        'target_id': targetId,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  @override
  List<Object?> get props =>
      [id, imageUrl, title, targetType, targetId, isActive, sortOrder];
}
