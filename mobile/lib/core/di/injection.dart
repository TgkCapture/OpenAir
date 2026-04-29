import 'package:get_it/get_it.dart';
import 'package:openair/core/services/api_service.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';
import 'package:openair/features/podcasts/bloc/podcast_bloc.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';
import 'package:openair/features/radio/bloc/radio_bloc.dart';
import 'package:openair/features/vod/bloc/vod_bloc.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final apiService = await ApiService.create();
  getIt.registerSingleton<ApiService>(apiService);
  
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt<ApiService>()));
  getIt.registerLazySingleton<ChannelRepository>(() => ChannelRepository(getIt<ApiService>()));
  getIt.registerLazySingleton<VodRepository>(() => VodRepository(getIt<ApiService>()));
  getIt.registerLazySingleton<PodcastRepository>(() => PodcastRepository(getIt<ApiService>()));
  
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<RadioBloc>(() => RadioBloc(getIt<ChannelRepository>()));
  getIt.registerFactory<SettingsBloc>(() => SettingsBloc());
  getIt.registerFactory<VodBloc>(() => VodBloc(getIt<VodRepository>()));
  getIt.registerFactory<PodcastBloc>(() => PodcastBloc(getIt<PodcastRepository>()));
}