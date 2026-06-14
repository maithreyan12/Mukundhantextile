import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    required this.createdAt,
  });

  String get shortAddress => '$street, $city, $state - $pincode';

  Map<String, dynamic> toShippingJson() => {
        'full_name': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
      };

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
        'is_default': isDefault,
      };

  Address copyWith({
    String? fullName,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, fullName, phone, street, city, state, pincode, isDefault];
}
