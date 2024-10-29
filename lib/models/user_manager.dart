// lib/models/user_manager.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_1/models/user_info_model.dart';

class UserManager extends Cubit<UserInfo?> {
  UserManager() : super(null);

  void setUserInfo(UserInfo userInfo) => emit(userInfo);
  
  void clearUserInfo() => emit(null);
  
  // Add this getter
  bool get isUserInfoSet => state != null;
  
  UserInfo? get userInfo => state;
}