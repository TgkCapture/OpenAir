import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openair/app/theme.dart';
import 'package:openair/features/settings/bloc/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG contrast ratio between two colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppTheme.parseHex', () {
    test('parses a #RRGGBB colour', () {
      expect(AppTheme.parseHex('#1D4ED8'), const Color(0xFF1D4ED8));
      expect(AppTheme.parseHex('0F766E'), const Color(0xFF0F766E));
    });

    test('returns null for missing or malformed values', () {
      expect(AppTheme.parseHex(null), isNull);
      expect(AppTheme.parseHex(''), isNull);
      expect(AppTheme.parseHex('#FFF'), isNull);
      expect(AppTheme.parseHex('#GGGGGG'), isNull);
    });
  });

  group('AppColors', () {
    test('secondary text is readable on every surface, in both themes', () {
      for (final colors in [
        AppColors.dark(AppTheme.defaultBrand),
        AppColors.light(AppTheme.defaultBrand),
      ]) {
        for (final surface in [colors.background, colors.surface, colors.surfaceHigh]) {
          expect(contrast(colors.textMuted, surface), greaterThanOrEqualTo(4.5));
          expect(contrast(colors.text, surface), greaterThanOrEqualTo(7));
        }
        expect(contrast(colors.onEmphasis, colors.emphasis), greaterThanOrEqualTo(7));
      }
    });

    test('text on the brand colour adapts to how light the brand is', () {
      // A dark brand gets white text, a light one gets dark text.
      expect(AppColors.dark(const Color(0xFF1D4ED8)).onBrand, Colors.white);
      expect(AppColors.dark(const Color(0xFFFFD60A)).onBrand, const Color(0xFF111318));
    });

    test('the theme carries the brand colour', () {
      const brand = Color(0xFF0F766E);
      final theme = AppTheme.dark(brand: brand);
      expect(theme.extension<AppColors>()!.brand, brand);
      expect(theme.colorScheme.primary, brand);
    });
  });

  group('SettingsBloc branding', () {
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('uses the broadcaster name and colour from the server and saves them',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = SettingsBloc(
        loadBranding: () async =>
            const Branding(name: 'Station One', primaryColorHex: '#1D4ED8'),
      )..add(SettingsLoaded());
      await settle();

      expect(bloc.state.brandName, 'Station One');
      expect(bloc.state.brandColor, const Color(0xFF1D4ED8));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('brand_color'), '#1D4ED8');
      expect(prefs.getString('brand_name'), 'Station One');
      await bloc.close();
    });

    test('opens with the saved branding when the server cannot be reached',
        () async {
      SharedPreferences.setMockInitialValues({
        'brand_color': '#0F766E',
        'brand_name': 'Saved Station',
        'is_dark_mode': false,
      });
      final bloc = SettingsBloc(
        loadBranding: () async => throw Exception('offline'),
      )..add(SettingsLoaded());
      await settle();

      expect(bloc.state.brandName, 'Saved Station');
      expect(bloc.state.brandColor, const Color(0xFF0F766E));
      expect(bloc.state.themeMode, ThemeMode.light);
      await bloc.close();
    });

    test('keeps the default colour when the server sends a malformed one',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = SettingsBloc(
        loadBranding: () async =>
            const Branding(name: 'Station', primaryColorHex: 'not-a-colour'),
      )..add(SettingsLoaded());
      await settle();

      expect(bloc.state.brandColor, AppTheme.defaultBrand);
      await bloc.close();
    });
  });
}
