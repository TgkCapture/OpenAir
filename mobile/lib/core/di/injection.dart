import 'package:get_it/get_it.dart';
import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final apiService = await ApiService.create();
  getIt.registerSingleton<ApiService>(apiService);
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiService>()),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<SettingsBloc>(() => SettingsBloc());
}