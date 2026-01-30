import 'user_enums.dart';

class Profile {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final UserType userType;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.userType,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
      userType: UserType.values.firstWhere(
        (e) => e.name == json['user_type'],
        orElse: () => UserType.donor,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'user_type': userType.name, // Enum to string
      'created_at': createdAt.toIso8601String(),
    };
  }
}
