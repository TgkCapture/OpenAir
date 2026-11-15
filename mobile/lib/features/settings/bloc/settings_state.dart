part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;

  /// The broadcaster's brand colour, from the server config.
  final Color brandColor;

  /// The broadcaster's name, shown in the app header.
  final String brandName;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.brandColor = AppTheme.defaultBrand,
    this.brandName = 'OpenAir',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? brandColor,
    String? brandName,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        brandColor: brandColor ?? this.brandColor,
        brandName: brandName ?? this.brandName,
      );

  @override
  List<Object> get props => [themeMode, brandColor, brandName];
}
