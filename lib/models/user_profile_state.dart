// lib/models/user_profile_state.dart
import '../models/user_profile_model.dart';

enum UserProfileStatus { loading, success, error }

class UserProfileState {
  final UserProfileStatus status;
  final UserProfile? profile;
  final String? error;

  const UserProfileState({
    this.status = UserProfileStatus.loading,
    this.profile,
    this.error,
  });

  UserProfileState copyWith({
    UserProfileStatus? status,
    UserProfile? profile,
    String? error,
  }) {
    return UserProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}
