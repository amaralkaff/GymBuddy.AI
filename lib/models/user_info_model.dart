// lib/models/user_info_model.dart

class UserInfo {
  final String username;
  final String email;
  final int height;
  final int weight;

  UserInfo({
    required this.username,
    required this.email,
    required this.height,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'height': height,
      'weight': weight,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] as String,
      email: json['email'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
    );
  }
}