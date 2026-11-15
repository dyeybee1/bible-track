import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';

/// Shared brand colors, including controls drawn outside the Material theme.
abstract final class AppPalette {
  static const deepViolet = Color(0xFF3F008D);
  static const softWhite = Color(0xFFF4F2F6);
  static const electricLime = Color(0xFFC3F53A);
  static const onLime = Color(0xFF281044);
  static const darkBackground = Color(0xFF160B25);
  static const darkSurface = Color(0xFF241437);
}

ThemeData _build(Brightness brightness) {
  final light = brightness == Brightness.light;
  final bg = light ? AppPalette.softWhite : AppPalette.darkBackground;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.deepViolet,
        brightness: brightness,
      ).copyWith(
        primary: light ? AppPalette.deepViolet : AppPalette.electricLime,
        onPrimary: light ? AppPalette.softWhite : AppPalette.onLime,
        primaryContainer: light
            ? const Color(0xFFECE3F7)
            : const Color(0xFF38204F),
        onPrimaryContainer: light
            ? AppPalette.deepViolet
            : AppPalette.softWhite,
        secondary: AppPalette.electricLime,
        onSecondary: AppPalette.onLime,
        secondaryContainer: light
            ? const Color(0xFFEDF7D3)
            : const Color(0xFF303C19),
        onSecondaryContainer: light ? AppPalette.onLime : AppPalette.softWhite,
        tertiary: light ? AppPalette.deepViolet : AppPalette.electricLime,
        onTertiary: light ? AppPalette.softWhite : AppPalette.onLime,
        surface: light ? Colors.white : AppPalette.darkSurface,
        onSurface: light ? const Color(0xFF241534) : AppPalette.softWhite,
        onSurfaceVariant: light
            ? const Color(0xFF74677F)
            : const Color(0xFFC3B5D1),
        surfaceDim: light ? const Color(0xFFE1DAE8) : AppPalette.darkBackground,
        surfaceBright: light ? Colors.white : const Color(0xFF443153),
        surfaceContainerLowest: light ? Colors.white : const Color(0xFF10071C),
        surfaceContainerLow: light
            ? AppPalette.softWhite
            : AppPalette.darkSurface,
        surfaceContainer: light
            ? const Color(0xFFEEE8F4)
            : const Color(0xFF2A193D),
        surfaceContainerHigh: light
            ? const Color(0xFFECE4F2)
            : const Color(0xFF322044),
        surfaceContainerHighest: light
            ? const Color(0xFFE3DCE9)
            : const Color(0xFF3B294C),
        outline: light ? const Color(0xFF85758F) : const Color(0xFF9987AA),
        outlineVariant: light
            ? const Color(0xFFE3DCE9)
            : const Color(0xFF443153),
      );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -.7,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: -.4,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.35,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.65, letterSpacing: 0),
      bodyMedium: TextStyle(fontSize: 14, height: 1.55, letterSpacing: 0),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.deepViolet,
      foregroundColor: AppPalette.softWhite,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: light
            ? Brightness.dark
            : Brightness.light,
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      elevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.secondary,
      indicatorShape: const StadiumBorder(),
      labelPadding: const EdgeInsets.only(top: 5),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 20,
          color: states.contains(WidgetState.selected)
              ? scheme.onSecondary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          height: 1.2,
          letterSpacing: 0,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.secondary : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.onSecondary : null,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : states.contains(WidgetState.selected)
            ? scheme.secondary
            : null,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : states.contains(WidgetState.selected)
            ? scheme.onSecondary
            : null,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      minVerticalPadding: 12,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
  );
}

final ThemeData lightTheme = _build(Brightness.light);
final ThemeData darkTheme = _build(Brightness.dark);

/// Lime fill for completed chapters, progress bars, and completion banners.
Color doneColor(BuildContext context) => AppPalette.electricLime;

/// Text/icon color that is readable on top of [doneColor].
Color onDoneColor(BuildContext context) => AppPalette.onLime;

/// Readable completion text and icons on an unfilled page or card.
Color doneForegroundColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
