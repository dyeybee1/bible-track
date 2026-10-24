import 'package:flutter/material.dart';

const _navy = Color(0xFF164B77);
const _navyDark = Color(0xFF6FA8DC);

ThemeData _build(Brightness brightness) {
  final light = brightness == Brightness.light;
  final bg = light ? const Color(0xFFF4F6F8) : const Color(0xFF0D1626);
  final scheme = ColorScheme.fromSeed(seedColor: _navy, brightness: brightness)
      .copyWith(
        primary: light ? _navy : _navyDark,
        onPrimary: light ? Colors.white : const Color(0xFF06222A),
        surface: light ? Colors.white : const Color(0xFF16233A),
        outlineVariant: light
            ? const Color(0xFFDDE2EA)
            : const Color(0xFF26354F),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
  );
}

final ThemeData lightTheme = _build(Brightness.light);
final ThemeData darkTheme = _build(Brightness.dark);

/// Teal-green used for everything that is "finished".
Color doneColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? const Color(0xFF2B7A6C)
    : const Color(0xFF3FB59F);

/// Text/icon color that is readable on top of [doneColor].
Color onDoneColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? Colors.white
    : const Color(0xFF05201B);
