import 'package:dio/dio.dart';
import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/auth/models/auth_models.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

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
    final data = AuthResponse.fromJson(res.data['data']);
    await _api.saveTokens(data.accessToken, data.refreshToken);
    return data;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = AuthResponse.fromJson(res.data['data']);
    await _api.saveTokens(data.accessToken, data.refreshToken);
    return data;
  }

  Future<void> logout(Dio dio) async {
    try {
      await dio.post('/auth/logout');
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

  Future<AuthUser> getProfile() async {
    final res = await _api.dio.get('/users/me');
    return AuthUser.fromJson(res.data['data']);
  }
}