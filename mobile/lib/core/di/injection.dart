import 'package:get_it/get_it.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerFactory(() => SettingsBloc());
}