part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object> get props => [];
}

/// Sent once at app start to pick up the session saved on the device.
class AuthSessionRestoreRequested extends AuthEvent {}

/// Sent when the server no longer accepts the saved session.
class AuthSessionExpired extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);
  @override List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  const AuthRegisterRequested(this.email, this.password, this.fullName);
  @override List<Object> get props => [email, password, fullName];
}

class AuthLogoutRequested extends AuthEvent {}