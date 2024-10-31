// lib/models/user_info_model.dart
class UserInfo {
  final String username;
  final String email;
  final String password;
  final int height;
  final int weight;

  const UserInfo({
    required this.username,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'height': height,
      'weight': weight,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
    );
  }
}