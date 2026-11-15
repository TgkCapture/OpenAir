import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/features/auth/models/auth_models.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  late final StreamSubscription<void> _sessionExpiredSub;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthSessionRestoreRequested>(_onRestore);
    on<AuthSessionExpired>((event, emit) => emit(AuthInitial()));
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);

    _sessionExpiredSub =
        _repo.onSessionExpired.listen((_) => add(AuthSessionExpired()));
  }

  /// Signs the user back in from the session saved on the device, then
  /// refreshes their profile in the background.
  Future<void> _onRestore(
      AuthSessionRestoreRequested event, Emitter<AuthState> emit) async {
    final cached = await _repo.cachedUser();
    if (cached == null) return;
    emit(AuthSuccess(cached));

    try {
      final fresh = await _repo.getProfile();
      // Skip the update if the user signed out or the session ended meanwhile.
      if (state is AuthSuccess) emit(AuthSuccess(fresh));
    } catch (_) {
      // Offline or server error: keep the cached user. A rejected session is
      // reported separately through AuthSessionExpired.
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _repo.login(email: event.email, password: event.password);
      emit(AuthSuccess(res.user));
    } on DioException catch (e) {
      emit(AuthFailure(_errorMessage(e, 'Login failed')));
    } catch (_) {
      emit(const AuthFailure('An unexpected error occurred'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _repo.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      emit(AuthSuccess(res.user));
    } on DioException catch (e) {
      emit(AuthFailure(_errorMessage(e, 'Registration failed')));
    } catch (_) {
      emit(const AuthFailure('An unexpected error occurred'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
    await _repo.logout();
  }

  /// Reads the API's error message, or explains that the server is unreachable.
  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (e.response == null) {
      return 'Cannot reach the server. Check your connection and try again.';
    }
    return fallback;
  }

  @override
  Future<void> close() {
    _sessionExpiredSub.cancel();
    return super.close();
  }
}
