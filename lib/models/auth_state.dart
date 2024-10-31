// lib/models/auth_state.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user_info_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserInfo? user;
  final String? error;

  const AuthState({
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

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'user': user?.toJson(),
      'error': error,
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      status: AuthStatus.values[json['status'] as int? ?? 0],
      user: json['user'] != null ? UserInfo.fromJson(json['user'] as Map<String, dynamic>) : null,
      error: json['error'] as String?,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  static const String _stateKey = 'auth_state';

  AuthCubit() : super(const AuthState(status: AuthStatus.initial)) {
    _loadSavedState();
  }

  void initializeAuth(bool isAuthenticated) {
    if (isAuthenticated) {
      emit(state.copyWith(status: AuthStatus.authenticated));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      
      if (stateJson != null) {
        final savedState = AuthState.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
        if (savedState.status == AuthStatus.authenticated) {
          emit(savedState);
        } else {
          emit(const AuthState(status: AuthStatus.unauthenticated));
        }
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stateKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> loggedIn(UserInfo user) async {
    final newState = AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
    emit(newState);
    await _saveState();
  }

  Future<void> loggedOut() async {
    const newState = AuthState(status: AuthStatus.unauthenticated);
    emit(newState);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }

  Future<void> setError(String error) async {
    final newState = state.copyWith(
      error: error,
      status: AuthStatus.unauthenticated,
    );
    emit(newState);
    await _saveState();
  }

  UserInfo? get currentUser => state.user;
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
}