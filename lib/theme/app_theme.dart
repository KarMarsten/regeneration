import 'package:flutter/material.dart';

enum AppColorTheme {
  dustyBlue,
  purpleDark,
  sageGreen,
  blushPink,
  sunshineYellow,
  peachOrange,
}

extension AppColorThemeExtension on AppColorTheme {
  String get label {
    switch (this) {
      case AppColorTheme.dustyBlue:
        return 'TARDIS Blue';
      case AppColorTheme.purpleDark:
        return 'Time Vortex';
      case AppColorTheme.sageGreen:
        return 'Gallifrey';
      case AppColorTheme.blushPink:
        return 'Rose';
      case AppColorTheme.sunshineYellow:
        return 'Bad Wolf';
      case AppColorTheme.peachOrange:
        return 'Dalek';
    }
  }

  Color get swatch {
    switch (this) {
      case AppColorTheme.dustyBlue:
        return const Color(0xFF003B6F);
      case AppColorTheme.purpleDark:
        return const Color(0xFF9B59B6);
      case AppColorTheme.sageGreen:
        return const Color(0xFF7BA68B);
      case AppColorTheme.blushPink:
        return const Color(0xFFE8A0B0);
      case AppColorTheme.sunshineYellow:
        return const Color(0xFFE8C547);
      case AppColorTheme.peachOrange:
        return const Color(0xFFE8956D);
    }
  }

  bool get isDark => this == AppColorTheme.purpleDark;

  String get dbValue => toString().split('.').last;

  static AppColorTheme fromDbValue(String value) {
    return AppColorTheme.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AppColorTheme.dustyBlue,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData getTheme(AppColorTheme colorTheme) {
    switch (colorTheme) {
      case AppColorTheme.dustyBlue:
        return _dustyBlue();
      case AppColorTheme.purpleDark:
        return _purpleDark();
      case AppColorTheme.sageGreen:
        return _sageGreen();
      case AppColorTheme.blushPink:
        return _blushPink();
      case AppColorTheme.sunshineYellow:
        return _sunshineYellow();
      case AppColorTheme.peachOrange:
        return _peachOrange();
    }
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surfaceContainerLow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
        overlayColor: colorScheme.primary.withOpacity(0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }

  // ── TARDIS Blue (default light) ────────────────────────────────────────────
  // Palette drawn from the TARDIS itself:
  //   body  #003B6F  sign bar #004D99  windows #C8DFF0  lamp glow #E8F4FF
  static ThemeData _dustyBlue() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003B6F),
          brightness: Brightness.light,
          primary: const Color(0xFF003B6F),   // TARDIS body — deep navy
          secondary: const Color(0xFF004D99), // sign-bar blue
          tertiary: const Color(0xFF7AB3D4),  // window-glass blue
          surface: const Color(0xFFF0F6FC),   // lamp-glow white-blue
          surfaceContainerLow: const Color(0xFFDDEEF8),
          surfaceContainerHighest: const Color(0xFFC0DCF0),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF001833), // darkest TARDIS navy
        ),
      );

  // ── Purple Dark ────────────────────────────────────────────────────────────
  static ThemeData _purpleDark() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B59B6),
          brightness: Brightness.dark,
          primary: const Color(0xFFBB8FCE),
          secondary: const Color(0xFF9B59B6),
          tertiary: const Color(0xFF6C3483),
          surface: const Color(0xFF1A0A2E),
          surfaceContainerLow: const Color(0xFF250D40),
          surfaceContainerHighest: const Color(0xFF3B1766),
          onPrimary: const Color(0xFF1A0A2E),
          onSurface: const Color(0xFFEDD9FA),
        ),
      );

  // ── Sage Green ─────────────────────────────────────────────────────────────
  static ThemeData _sageGreen() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7BA68B),
          brightness: Brightness.light,
          primary: const Color(0xFF558B6E),
          secondary: const Color(0xFF7BA68B),
          tertiary: const Color(0xFFADC8B5),
          surface: const Color(0xFFF4FAF6),
          surfaceContainerLow: const Color(0xFFEBF4EE),
          surfaceContainerHighest: const Color(0xFFD4EADB),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1A2E22),
        ),
      );

  // ── Blush Pink ─────────────────────────────────────────────────────────────
  static ThemeData _blushPink() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A0B0),
          brightness: Brightness.light,
          primary: const Color(0xFFD47A92),
          secondary: const Color(0xFFE8A0B0),
          tertiary: const Color(0xFFF2C5D0),
          surface: const Color(0xFFFDF4F6),
          surfaceContainerLow: const Color(0xFFFAECF0),
          surfaceContainerHighest: const Color(0xFFF5D8E0),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF3D1A24),
        ),
      );

  // ── Sunshine Yellow ────────────────────────────────────────────────────────
  static ThemeData _sunshineYellow() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8C547),
          brightness: Brightness.light,
          primary: const Color(0xFFC9A820),
          secondary: const Color(0xFFE8C547),
          tertiary: const Color(0xFFF2D96A),
          surface: const Color(0xFFFEFBF0),
          surfaceContainerLow: const Color(0xFFFDF6DC),
          surfaceContainerHighest: const Color(0xFFFAEDB0),
          onPrimary: const Color(0xFF2A2000),
          onSurface: const Color(0xFF2A2000),
        ),
      );

  // ── Peach Orange ───────────────────────────────────────────────────────────
  static ThemeData _peachOrange() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8956D),
          brightness: Brightness.light,
          primary: const Color(0xFFD06B3D),
          secondary: const Color(0xFFE8956D),
          tertiary: const Color(0xFFF2B896),
          surface: const Color(0xFFFDF7F3),
          surfaceContainerLow: const Color(0xFFFAEFE7),
          surfaceContainerHighest: const Color(0xFFF5DDD0),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF3D1A08),
        ),
      );
}
