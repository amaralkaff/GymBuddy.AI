// lib/models/user_profile_model.dart
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String password;
  final int height;
  final int weight;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'password': password,
      'height': height,
      'weight': weight,
    };
  }
}
