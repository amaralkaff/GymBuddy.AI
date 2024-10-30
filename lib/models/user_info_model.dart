// lib/models/user_info_model.dart

class UserInfo {
  final String? id;
  final String username;
  final String email;
  final String password; // Make password required for registration
  final int height;
  final int weight;

  UserInfo({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
  });

  // Create a separate factory for login response
  factory UserInfo.fromLoginResponse(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'],
      username: json['username'] as String,
      email: json['email'] as String,
      password: '', // Empty password for logged-in user
      height: json['height'] as int,
      weight: json['weight'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'height': height,
      'weight': weight,
    };
  }

  // Create a copy with modified fields
  UserInfo copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    int? height,
    int? weight,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
