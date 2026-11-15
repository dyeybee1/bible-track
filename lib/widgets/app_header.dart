import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../settings_scope.dart';

/// Branded header shared by the reading, library, and account screens.
/// Its height follows the actual title and accessibility text size.
AppBar appHeader(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  Widget? leading,
  bool themeToggle = false,
}) {
  final theme = Theme.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final hasLeading = leading != null || Navigator.of(context).canPop();
  final actionCount = actions.length + (themeToggle ? 1 : 0);
  final titleWidth = math.max(
    80.0,
    MediaQuery.sizeOf(context).width -
        40 -
        (hasLeading ? 56 : 0) -
        actionCount * 48,
  );
  final titleStyle = theme.textTheme.headlineMedium!.copyWith(
    fontSize: 27,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -.7,
    color: theme.appBarTheme.foregroundColor,
  );
  final measure = TextPainter(
    text: TextSpan(text: title, style: titleStyle),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: titleWidth);
  final toolbarHeight = math.max(108.0, measure.height + scaler.scale(14) + 50);
  measure.dispose();

  return AppBar(
    toolbarHeight: toolbarHeight,
    titleSpacing: 20,
    leading: leading,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_outlined, size: 17),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'BIBLE TRACK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.appBarTheme.foregroundColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.6,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      ],
    ),
    actions: [
      ...actions,
      if (themeToggle) const _ThemeToggle(),
      if (actionCount > 0) const SizedBox(width: 12),
    ],
  );
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = SettingsScope.of(context);
    final strings = context.s;
    return IconButton.outlined(
      tooltip: dark ? strings.themeLight : strings.themeDark,
      onPressed: () =>
          settings.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        backgroundColor: Colors.white.withValues(alpha: .06),
        side: BorderSide(color: Colors.white.withValues(alpha: .25)),
        minimumSize: const Size.square(44),
        iconSize: 20,
      ),
    );
  }
}
