import 'package:flutter/material.dart';

import '../../data/progress_controller.dart';
import '../../settings_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/profile_access.dart';
import 'profile_sections.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.progress});

  final ProgressController progress;

  Future<void> _confirmStartOver(BuildContext context) async {
    final strings = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.startOverTitle),
        content: Text(strings.startOverBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.startOverConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    progress.startNewCycle();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.startOverDone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;
    final settings = SettingsScope.of(context);
    final settingsBuilder = ProfileAccess.maybeOf(context)?.settingsBuilder;
    final username = settings.username ?? strings.defaultUsername;

    return Scaffold(
      appBar: appHeader(
        context,
        title: strings.navProfile,
        showProfileAction: false,
        actions: [
          if (settingsBuilder != null)
            IconButton(
              key: const ValueKey('header-settings-action'),
              tooltip: strings.navSettings,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => Navigator.of(
                context,
              ).push<void>(MaterialPageRoute(builder: settingsBuilder)),
              icon: CircleAvatar(
                radius: 15,
                backgroundColor: scheme.onSurface,
                child: Semantics(
                  label: strings.navSettings,
                  child: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: scheme.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final canStartOver = progress.allBooksCompleted;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              ProfileDetails(
                username: username,
                chaptersRead: progress.chaptersReadLifetime,
                maxStars: progress.maxStarsEver,
                timesCompleted: progress.timesCompleted,
                chaptersCycle: progress.chaptersReadTotal,
                booksDone: progress.completedBooks,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canStartOver
                    ? () => _confirmStartOver(context)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(strings.startOver),
                ),
              ),
              if (!canStartOver)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.startOverHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
