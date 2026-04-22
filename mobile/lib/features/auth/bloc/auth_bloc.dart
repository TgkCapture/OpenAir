import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/features/auth/models/auth_models.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _repo.login(email: event.email, password: event.password);
      emit(AuthSuccess(res.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ?? 'Login failed';
      emit(AuthFailure(msg));
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
      final msg = e.response?.data?['error']?['message'] ?? 'Registration failed';
      emit(AuthFailure(msg));
    } catch (_) {
      emit(const AuthFailure('An unexpected error occurred'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }
}