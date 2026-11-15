import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openair/app/router.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/auth/bloc/auth_bloc.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';

class OpenAirApp extends StatelessWidget {
  const OpenAirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsBloc>()..add(SettingsLoaded())),
        BlocProvider.value(value: getIt<AudioController>()),
        BlocProvider(
          lazy: false,
          create: (_) => getIt<AuthBloc>()..add(AuthSessionRestoreRequested()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: state.brandName,
            theme: AppTheme.light(brand: state.brandColor),
            darkTheme: AppTheme.dark(brand: state.brandColor),
            themeMode: state.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}