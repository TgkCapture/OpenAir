import 'dart:convert';

import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/auth/models/auth_models.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  /// Fires when the stored session is no longer accepted by the server.
  Stream<void> get onSessionExpired => _api.onSessionExpired;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    return _startSession(AuthResponse.fromJson(res.data['data']));
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _startSession(AuthResponse.fromJson(res.data['data']));
  }

  Future<AuthResponse> _startSession(AuthResponse data) async {
    await _api.saveTokens(data.accessToken, data.refreshToken);
    await _api.saveUserJson(jsonEncode(data.user.toJson()));
    return data;
  }

  /// The user saved by the last sign-in, or null when nobody is signed in.
  /// Reads only from the device, so it also works offline.
  Future<AuthUser?> cachedUser() async {
    if (await _api.readRefreshToken() == null) return null;
    final json = await _api.readUserJson();
    if (json == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Signs this device out. The local session is cleared even when the server
  /// cannot be reached.
  Future<void> logout() async {
    final refreshToken = await _api.readRefreshToken();
    try {
      await _api.dio.post('/auth/logout', data: {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } catch (_) {}
    await _api.clearTokens();
  }

  Future<void> forgotPassword(String email) async {
    await _api.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  /// Fetches the current user from the server and refreshes the cached copy.
  Future<AuthUser> getProfile() async {
    final res = await _api.dio.get('/users/me');
    final user = AuthUser.fromJson(res.data['data']);
    await _api.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }
}
