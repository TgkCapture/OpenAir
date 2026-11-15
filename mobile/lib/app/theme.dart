import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spacing scale, in logical pixels. Use these instead of ad-hoc numbers so
/// screens share one rhythm.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding at the edge of every screen.
  static const double screen = 16;
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Durations for transitions.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}

/// The app's colour roles. Screens read colours from here, never from
/// literals, so the whole app follows the theme and the broadcaster's brand
/// colour.
///
/// Read with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Page background.
  final Color background;

  /// Cards and bars sitting on the background.
  final Color surface;

  /// Controls sitting on a surface, such as chips and the mini player.
  final Color surfaceHigh;

  /// Hairlines and outlines.
  final Color border;

  /// Primary text and icons.
  final Color text;

  /// Secondary text. Meets 4.5:1 on [background] and [surface].
  final Color textMuted;

  /// The broadcaster's brand colour. Used for fills and indicators, not for
  /// small text on dark backgrounds, where it may not be readable.
  final Color brand;

  /// Text and icons on top of [brand].
  final Color onBrand;

  /// High-contrast fill for the main action on a screen (white in the dark
  /// theme, near-black in the light theme).
  final Color emphasis;

  /// Text and icons on top of [emphasis].
  final Color onEmphasis;

  /// Placeholder behind artwork that has not loaded.
  final Color artwork;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.brand,
    required this.onBrand,
    required this.emphasis,
    required this.onEmphasis,
    required this.artwork,
  });

  factory AppColors.dark(Color brand) => AppColors(
        background: const Color(0xFF0B0B0D),
        surface: const Color(0xFF17171B),
        surfaceHigh: const Color(0xFF212127),
        border: const Color(0xFF2A2A31),
        text: const Color(0xFFF2F2F4),
        textMuted: const Color(0xFFA0A0AB),
        brand: brand,
        onBrand: _readableOn(brand),
        emphasis: const Color(0xFFFFFFFF),
        onEmphasis: const Color(0xFF0B0B0D),
        artwork: const Color(0xFF24305E),
      );

  factory AppColors.light(Color brand) => AppColors(
        background: const Color(0xFFF5F6F8),
        surface: const Color(0xFFFFFFFF),
        surfaceHigh: const Color(0xFFF0F1F4),
        border: const Color(0xFFE2E4E9),
        text: const Color(0xFF111318),
        textMuted: const Color(0xFF5A5F6B),
        brand: brand,
        onBrand: _readableOn(brand),
        emphasis: const Color(0xFF111318),
        onEmphasis: const Color(0xFFFFFFFF),
        artwork: const Color(0xFFDCE6F7),
      );

  /// White or near-black, whichever is easier to read on [color].
  static Color _readableOn(Color color) =>
      color.computeLuminance() > 0.4 ? const Color(0xFF111318) : Colors.white;

  @override
  AppColors copyWith({Color? brand}) => AppColors(
        background: background,
        surface: surface,
        surfaceHigh: surfaceHigh,
        border: border,
        text: text,
        textMuted: textMuted,
        brand: brand ?? this.brand,
        onBrand: brand != null ? _readableOn(brand) : onBrand,
        emphasis: emphasis,
        onEmphasis: onEmphasis,
        artwork: artwork,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      emphasis: Color.lerp(emphasis, other.emphasis, t)!,
      onEmphasis: Color.lerp(onEmphasis, other.onEmphasis, t)!,
      artwork: Color.lerp(artwork, other.artwork, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  /// The app's colour roles for the current theme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  /// Used until the broadcaster's own colour has loaded from the server.
  static const Color defaultBrand = Color(0xFFE63946);

  static const String fontFamily = 'Inter';

  /// Parses a `#RRGGBB` colour from the server config. Returns null when the
  /// value is missing or malformed.
  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    final value = hex.replaceFirst('#', '');
    if (value.length != 6) return null;
    final rgb = int.tryParse(value, radix: 16);
    return rgb == null ? null : Color(0xFF000000 | rgb);
  }

  static ThemeData dark({Color brand = defaultBrand}) =>
      _build(Brightness.dark, AppColors.dark(brand));

  static ThemeData light({Color brand = defaultBrand}) =>
      _build(Brightness.light, AppColors.light(brand));

  static ThemeData _build(Brightness brightness, AppColors c) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.brand,
      onSecondary: c.onBrand,
      error: const Color(0xFFD64545),
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.surfaceHigh,
    );

    final text = _textTheme(c);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      fontFamily: fontFamily,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: c.text),

      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: brightness,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: isDark ? BorderSide.none : BorderSide(color: c.border),
        ),
      ),

      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 0),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          minimumSize: const Size(0, 48),
          shape: shape,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: c.border),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // Brand-coloured text is readable on the light theme only.
          foregroundColor: isDark ? c.text : c.brand,
          minimumSize: const Size(44, 44),
          textStyle: text.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: c.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.text, width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.emphasis,
        labelStyle: text.labelMedium,
        side: isDark ? BorderSide.none : BorderSide(color: c.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        showCheckmark: false,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.emphasis,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onEmphasis),
        shape: shape,
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.text,
        linearTrackColor: c.border,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.onBrand : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.brand : c.surfaceHigh,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.text,
        textColor: c.text,
        minVerticalPadding: AppSpacing.md,
      ),
    );
  }

  /// One typeface, a small set of sizes. Headings are tight and bold; body
  /// text is regular weight.
  static TextTheme _textTheme(AppColors c) {
    TextStyle style(double size, FontWeight weight,
            {double height = 1.3, double spacing = 0, Color? color}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? c.text,
        );

    return TextTheme(
      headlineLarge: style(30, FontWeight.w700, height: 1.15, spacing: -0.6),
      headlineMedium: style(26, FontWeight.w700, height: 1.15, spacing: -0.5),
      headlineSmall: style(22, FontWeight.w700, height: 1.2, spacing: -0.4),
      titleLarge: style(18, FontWeight.w700, spacing: -0.2),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400, height: 1.45),
      bodyMedium: style(14, FontWeight.w400, height: 1.45),
      bodySmall: style(12, FontWeight.w400, height: 1.4, color: c.textMuted),
      labelLarge: style(14, FontWeight.w700),
      labelMedium: style(13, FontWeight.w600),
      labelSmall: style(11, FontWeight.w700, spacing: 0.6),
    );
  }
}
