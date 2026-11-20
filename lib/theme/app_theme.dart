import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';

/// Shared brand colors, including controls drawn outside the Material theme.
abstract final class AppPalette {
  static const forest = Color(0xFF0B5E42);
  static const cream = Color(0xFFFAF9F5);
  static const mint = Color(0xFF2DD4BF);
  static const gold = Color(0xFFD97706);
  static const ink = Color(0xFF0F172A);
  static const darkBackground = Color(0xFF121417);
  static const darkSurface = Color(0xFF1A1D23);
}

abstract final class AppTypography {
  static const serif = 'Newsreader';
  static const sans = 'PlusJakartaSans';
}

ThemeData _build(Brightness brightness) {
  final light = brightness == Brightness.light;
  final bg = light ? AppPalette.cream : AppPalette.darkBackground;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.forest,
        brightness: brightness,
      ).copyWith(
        primary: light ? AppPalette.forest : AppPalette.mint,
        onPrimary: light ? Colors.white : AppPalette.ink,
        primaryContainer: light
            ? const Color(0xFFE8F5EE)
            : const Color(0xFF13382E),
        onPrimaryContainer: light ? AppPalette.forest : AppPalette.cream,
        secondary: light ? AppPalette.forest : AppPalette.mint,
        onSecondary: light ? Colors.white : AppPalette.ink,
        secondaryContainer: light
            ? const Color(0xFFE8F5EE)
            : const Color(0xFF13382E),
        onSecondaryContainer: light ? AppPalette.ink : AppPalette.cream,
        tertiary: light ? AppPalette.gold : const Color(0xFFF59E0B),
        error: light ? const Color(0xFFDC2626) : const Color(0xFFF87171),
        errorContainer: light
            ? const Color(0xFFFEF2F2)
            : const Color(0xFF391A1E),
        onTertiary: light ? AppPalette.cream : AppPalette.ink,
        surface: light ? Colors.white : AppPalette.darkSurface,
        onSurface: light ? const Color(0xFF0F172A) : AppPalette.cream,
        onSurfaceVariant: light
            ? const Color(0xFF475569)
            : const Color(0xFF94A3B8),
        surfaceDim: light ? const Color(0xFFEBEAE5) : AppPalette.darkBackground,
        surfaceBright: light ? Colors.white : const Color(0xFF2D333F),
        surfaceContainerLowest: light ? Colors.white : const Color(0xFF101215),
        surfaceContainerLow: light ? AppPalette.cream : AppPalette.darkSurface,
        surfaceContainer: light
            ? const Color(0xFFF4F4F0)
            : const Color(0xFF242831),
        surfaceContainerHigh: light
            ? const Color(0xFFF4F4F0)
            : const Color(0xFF242831),
        surfaceContainerHighest: light
            ? const Color(0xFFEBEAE5)
            : const Color(0xFF242831),
        outline: light ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        outlineVariant: light
            ? const Color(0xFFEBEAE5)
            : const Color(0xFF2D333F),
      );
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.sans,
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
        fontFamily: AppTypography.serif,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -.8,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.serif,
        fontSize: 27,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -.7,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.serif,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: -.4,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.serif,
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
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle:
          (light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(
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
      elevation: .5,
      shadowColor: scheme.onSurface.withValues(alpha: .08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outlineVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainer,
      linearMinHeight: 5,
      borderRadius: BorderRadius.circular(8),
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

/// Soft green fill for completed chapters, progress bars, and completion banners.
Color doneColor(BuildContext context) =>
    Theme.of(context).colorScheme.primaryContainer;

/// Text/icon color that is readable on top of [doneColor].
Color onDoneColor(BuildContext context) =>
    Theme.of(context).colorScheme.onPrimaryContainer;

/// Readable completion text and icons on an unfilled page or card.
Color doneForegroundColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
