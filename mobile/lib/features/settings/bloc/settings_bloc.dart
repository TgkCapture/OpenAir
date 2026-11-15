import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:openair/app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// The broadcaster's branding as set in the admin dashboard.
class Branding {
  final String name;
  final String? primaryColorHex;
  const Branding({required this.name, this.primaryColorHex});
}

/// Loads the branding from the server. Supplied to [SettingsBloc] so the bloc
/// does not depend on the network layer.
typedef BrandingLoader = Future<Branding> Function();

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const _darkModeKey = 'is_dark_mode';
  static const _brandColorKey = 'brand_color';
  static const _brandNameKey = 'brand_name';

  final BrandingLoader? _loadBranding;

  SettingsBloc({BrandingLoader? loadBranding})
      : _loadBranding = loadBranding,
        super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<ThemeToggled>(_onThemeToggled);
  }

  Future<void> _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();

    // Start from what was saved last time, so the app opens in the right
    // theme and brand colour straight away, including offline.
    final isDark = prefs.getBool(_darkModeKey) ?? true;
    emit(state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      brandColor: AppTheme.parseHex(prefs.getString(_brandColorKey)),
      brandName: prefs.getString(_brandNameKey),
    ));

    final loadBranding = _loadBranding;
    if (loadBranding == null) return;
    try {
      final branding = await loadBranding();
      final color = AppTheme.parseHex(branding.primaryColorHex);
      if (color != null) {
        await prefs.setString(_brandColorKey, branding.primaryColorHex!);
      }
      await prefs.setString(_brandNameKey, branding.name);
      emit(state.copyWith(brandColor: color, brandName: branding.name));
    } catch (_) {
      // Offline or server error: keep the saved branding.
    }
  }

  Future<void> _onThemeToggled(ThemeToggled event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state.themeMode == ThemeMode.light;
    await prefs.setBool(_darkModeKey, isDark);
    emit(state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }
}
