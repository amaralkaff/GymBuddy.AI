// lib/models/auth_state.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_info_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserInfo? user;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserInfo? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

// lib/models/auth_state.dart

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(status: AuthStatus.unauthenticated));

  void loggedIn(UserInfo user) {
    emit(AuthState(
      status: AuthStatus.authenticated,
      user: user,
    ));
  }

  void loggedOut() {
    emit(AuthState(status: AuthStatus.unauthenticated));
  }

  void setError(String error) {
    emit(state.copyWith(
      error: error,
      status: AuthStatus.unauthenticated,
    ));
  }

  UserInfo? get currentUser => state.user;
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
}
