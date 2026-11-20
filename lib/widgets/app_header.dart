import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../settings_scope.dart';
import 'app_logo.dart';
import 'profile_access.dart';

/// Compact warm-paper header with the existing detail-page back action.
AppBar appHeader(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  Widget? leading,
  bool themeToggle = false,
  bool root = false,
  bool showProfileAction = true,
}) {
  final theme = Theme.of(context);
  final profile = ProfileAccess.maybeOf(context);
  final hasLeading =
      leading != null || (!root && Navigator.of(context).canPop());
  final count =
      actions.length +
      (themeToggle ? 1 : 0) +
      (showProfileAction && profile != null ? 1 : 0);
  final width = math.max(
    72.0,
    MediaQuery.sizeOf(context).width - 32 - (hasLeading ? 48 : 0) - count * 48,
  );
  final titleStyle = theme.textTheme.titleLarge!.copyWith(
    fontSize: 19,
    height: 1.2,
  );
  final painter = TextPainter(
    text: TextSpan(text: root ? 'Bible Track' : title, style: titleStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: width);
  final height = math.max(64.0, painter.height + 24);
  painter.dispose();
  return AppBar(
    toolbarHeight: height,
    titleSpacing: hasLeading ? 0 : 20,
    leadingWidth: 48,
    leading: leading,
    automaticallyImplyLeading: !root,
    title: root
        ? Row(
            children: [
              const ExcludeSemantics(child: ClipOval(child: AppLogo(size: 32))),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Bible Track',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ],
          )
        : Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
    actions: [
      if (themeToggle) const _ThemeToggle(),
      ...actions,
      if (showProfileAction && profile != null)
        IconButton(
          key: const ValueKey('header-profile-action'),
          tooltip: context.s.navProfile,
          onPressed: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: profile.profileBuilder)),
          icon: CircleAvatar(
            radius: 15,
            backgroundColor: theme.colorScheme.onSurface,
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: theme.colorScheme.surface,
            ),
          ),
        ),
      const SizedBox(width: 8),
    ],
  );
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = SettingsScope.of(context);
    return IconButton(
      tooltip: dark ? context.s.themeLight : context.s.themeDark,
      onPressed: () =>
          settings.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
      ),
    );
  }
}
