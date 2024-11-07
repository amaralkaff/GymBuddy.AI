import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout_ai/models/user_profile_state.dart';
import 'package:workout_ai/services/user_profile_service.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileService _profileService;

  UserProfileCubit(this._profileService) : super(const UserProfileState());

  Future<void> loadUserProfile() async {
    try {
      emit(const UserProfileState(status: UserProfileStatus.loading));
      final profile = await _profileService.getUserProfile();
      emit(UserProfileState(
        status: UserProfileStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(UserProfileState(
        status: UserProfileStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> updateUserProfile({
    required String username,
    required String email,
    required int height,
    required int weight,
  }) async {
    try {
      emit(const UserProfileState(status: UserProfileStatus.loading));
      final updatedProfile = await _profileService.updateUserProfile(
        username: username,
        email: email,
        height: height,
        weight: weight,
      );
      emit(UserProfileState(
        status: UserProfileStatus.success,
        profile: updatedProfile,
      ));
    } catch (e) {
      emit(UserProfileState(
        status: UserProfileStatus.error,
        error: e.toString(),
      ));
    }
  }
}
