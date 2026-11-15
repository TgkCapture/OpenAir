import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/auth/models/auth_models.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _cached = AuthUser(
  id: '1',
  email: 'viewer@example.com',
  fullName: 'Cached Name',
  role: 'user',
);

const _fresh = AuthUser(
  id: '1',
  email: 'viewer@example.com',
  fullName: 'Fresh Name',
  role: 'user',
);

void main() {
  late _MockAuthRepository repo;
  late StreamController<void> sessionExpired;

  setUp(() {
    repo = _MockAuthRepository();
    sessionExpired = StreamController<void>.broadcast();
    when(() => repo.onSessionExpired).thenAnswer((_) => sessionExpired.stream);
  });

  tearDown(() => sessionExpired.close());

  String nameOf(AuthState state) => (state as AuthSuccess).user.fullName;

  blocTest<AuthBloc, AuthState>(
    'stays signed out at launch when no session is saved',
    setUp: () => when(() => repo.cachedUser()).thenAnswer((_) async => null),
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(AuthSessionRestoreRequested()),
    expect: () => <AuthState>[],
    verify: (_) => verifyNever(() => repo.getProfile()),
  );

  blocTest<AuthBloc, AuthState>(
    'restores the saved user at launch, then refreshes the profile',
    setUp: () {
      when(() => repo.cachedUser()).thenAnswer((_) async => _cached);
      when(() => repo.getProfile()).thenAnswer((_) async => _fresh);
    },
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(AuthSessionRestoreRequested()),
    verify: (bloc) => expect(nameOf(bloc.state), 'Fresh Name'),
  );

  blocTest<AuthBloc, AuthState>(
    'keeps the saved user when the profile cannot be fetched (offline)',
    setUp: () {
      when(() => repo.cachedUser()).thenAnswer((_) async => _cached);
      when(() => repo.getProfile()).thenThrow(Exception('offline'));
    },
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(AuthSessionRestoreRequested()),
    verify: (bloc) => expect(nameOf(bloc.state), 'Cached Name'),
  );

  blocTest<AuthBloc, AuthState>(
    'signs out when the server rejects the saved session',
    build: () => AuthBloc(repo),
    seed: () => const AuthSuccess(_cached),
    act: (bloc) => sessionExpired.add(null),
    expect: () => [isA<AuthInitial>()],
  );

  blocTest<AuthBloc, AuthState>(
    'logout signs out and clears the session on the server and device',
    setUp: () => when(() => repo.logout()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo),
    seed: () => const AuthSuccess(_cached),
    act: (bloc) => bloc.add(AuthLogoutRequested()),
    expect: () => [isA<AuthInitial>()],
    verify: (_) => verify(() => repo.logout()).called(1),
  );
}
