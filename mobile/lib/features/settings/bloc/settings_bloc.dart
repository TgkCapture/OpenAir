import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<ThemeToggled>(_onThemeToggled);
  }

  Future<void> _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    emit(state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> _onThemeToggled(ThemeToggled event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state.themeMode == ThemeMode.light;
    await prefs.setBool('is_dark_mode', isDark);
    emit(state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }
}