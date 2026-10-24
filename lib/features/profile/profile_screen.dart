import 'package:flutter/material.dart';

import '../../data/books_data.dart';
import '../../data/progress_controller.dart';
import '../../settings_scope.dart';

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
    final username = settings.username ?? strings.defaultUsername;
    final initial = username.isEmpty
        ? '?'
        : String.fromCharCode(username.runes.first).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(strings.navProfile)),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final booksDone = progress.completedBooks;
          final chapters = progress.chaptersReadTotal;
          final ratio = totalChaptersInBible == 0
              ? 0.0
              : (chapters / totalChaptersInBible).clamp(0.0, 1.0).toDouble();
          final canStartOver = progress.allBooksCompleted;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: scheme.primary,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(username, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 20),
              _Panel(
                child: Column(
                  children: [
                    Text(
                      strings.wholeBibleFinished,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.timesLabel(progress.timesCompleted),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '$booksDone/${allBooks.length}',
                      label: strings.booksFinishedLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      value: '$chapters',
                      label: strings.chaptersReadLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.overallProgress),
                        Text(
                          '${(ratio * 100).floor()}%',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: scheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
