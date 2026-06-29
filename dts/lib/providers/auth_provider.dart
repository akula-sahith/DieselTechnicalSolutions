import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? email;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.userName,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? email,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  static const String _authKey = 'is_logged_in';
  static const String _userNameKey = 'logged_user_name';
  static const String _emailKey = 'logged_user_email';

  AuthNotifier(this._prefs) : super(AuthState(isAuthenticated: false)) {
    _checkStatus();
  }

  void _checkStatus() {
    final isLoggedIn = _prefs.getBool(_authKey) ?? false;
    if (isLoggedIn) {
      state = AuthState(
        isAuthenticated: true,
        userName: _prefs.getString(_userNameKey) ?? 'Siva',
        email: _prefs.getString(_emailKey) ?? 'siva@dts.com',
      );
    }
  }

  Future<bool> login(String emailOrId, String password, bool rememberMe) async {
    state = state.copyWith(error: null);
    
    // Perform mock authentication validation
    if (emailOrId.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Please fill in all fields.');
      return false;
    }

    // Standard simulation: Allow any login but default the name to Siva
    // matching the screenshot "Good Morning, Siva"
    String name = 'Siva';
    if (emailOrId.contains('@')) {
      name = emailOrId.split('@')[0];
      name = name[0].toUpperCase() + name.substring(1);
    }

    if (rememberMe) {
      await _prefs.setBool(_authKey, true);
      await _prefs.setString(_userNameKey, name);
      await _prefs.setString(_emailKey, emailOrId);
    }

    state = AuthState(
      isAuthenticated: true,
      userName: name,
      email: emailOrId,
    );
    return true;
  }

  Future<void> logout() async {
    await _prefs.remove(_authKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_emailKey);
    state = AuthState(isAuthenticated: false);
  }
}
