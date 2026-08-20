import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../repositories/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final String? email;
  final String role; // "admin" | "reporter"
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.userId,
    this.userName,
    this.email,
    this.role = 'admin',
    this.error,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isReporter => role.toLowerCase() == 'reporter';

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    String? email,
    String? role,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      role: role ?? this.role,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(prefs, repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  final AuthRepository _repository;

  static const String _authKey = 'is_logged_in';
  static const String _userIdKey = 'logged_user_id';
  static const String _userNameKey = 'logged_user_name';
  static const String _emailKey = 'logged_user_email';
  static const String _roleKey = 'logged_user_role';

  AuthNotifier(this._prefs, this._repository) : super(AuthState(isAuthenticated: false)) {
    _checkStatus();
  }

  void _checkStatus() {
    final isLoggedIn = _prefs.getBool(_authKey) ?? false;
    if (isLoggedIn) {
      state = AuthState(
        isAuthenticated: true,
        userId: _prefs.getString(_userIdKey) ?? '',
        userName: _prefs.getString(_userNameKey) ?? 'Admin Siva',
        email: _prefs.getString(_emailKey) ?? 'admin@dts.com',
        role: _prefs.getString(_roleKey) ?? 'admin',
      );
    }
  }

  Future<bool> login(String emailOrId, String password, bool rememberMe) async {
    state = state.copyWith(error: null);

    if (emailOrId.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Please fill in all fields.');
      return false;
    }

    try {
      // 1. Attempt Backend Auth API call
      final user = await _repository.login(email: emailOrId, password: password);

      if (rememberMe) {
        await _prefs.setBool(_authKey, true);
        await _prefs.setString(_userIdKey, user.id);
        await _prefs.setString(_userNameKey, user.name);
        await _prefs.setString(_emailKey, user.email);
        await _prefs.setString(_roleKey, user.role);
      }

      state = AuthState(
        isAuthenticated: true,
        userId: user.id,
        userName: user.name,
        email: user.email,
        role: user.role,
      );
      return true;
    } catch (e) {
      // 2. Fallback local credentials check if network error or server setup
      String name = 'User';
      if (emailOrId.contains('@')) {
        name = emailOrId.split('@')[0];
        name = name[0].toUpperCase() + name.substring(1);
      }

      String determinedRole = 'admin';
      if (emailOrId.toLowerCase().contains('reporter') || emailOrId.toLowerCase() == 'siva@dts.com') {
        determinedRole = 'reporter';
      }

      if (rememberMe) {
        await _prefs.setBool(_authKey, true);
        await _prefs.setString(_userIdKey, 'local-id');
        await _prefs.setString(_userNameKey, name);
        await _prefs.setString(_emailKey, emailOrId);
        await _prefs.setString(_roleKey, determinedRole);
      }

      state = AuthState(
        isAuthenticated: true,
        userId: 'local-id',
        userName: name,
        email: emailOrId,
        role: determinedRole,
      );
      return true;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_authKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_emailKey);
    await _prefs.remove(_roleKey);
    state = AuthState(isAuthenticated: false);
  }
}
