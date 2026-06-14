import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

enum UserRole { customer, admin }

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? phone;
  final bool isBanned;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.phone,
    this.isBanned = false,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin || email == AppConstants.adminEmail;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role']?.toString() ?? '') == 'admin'
          ? UserRole.admin
          : UserRole.customer,
      phone: json['phone'] as String?,
      isBanned: json['is_banned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'phone': phone,
      };

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? phone,
    UserRole? role,
    bool? isBanned,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, avatarUrl, role, phone, isBanned, createdAt];
}
