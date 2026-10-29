import 'package:flutter/material.dart';

import '../../data/books_data.dart';
import '../../settings_scope.dart';
import '../rank/rank_cards.dart';

/// Identical reading information on own and public profiles.
class ProfileDetails extends StatelessWidget {
  const ProfileDetails({
    super.key,
    required this.username,
    required this.chaptersRead,
    required this.maxStars,
    required this.timesCompleted,
    required this.chaptersCycle,
    required this.booksDone,
  });

  final String username;
  final int chaptersRead;
  final int maxStars;
  final int timesCompleted;
  final int chaptersCycle;
  final int booksDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = username.isEmpty
        ? '?'
        : String.fromCharCode(username.runes.first).toUpperCase();
    return Column(
      children: [
        CurrentRankCard(stars: chaptersRead),
        const SizedBox(height: 8),
        HighestRankCard(maxStarsEver: maxStars),
        const SizedBox(height: 20),
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
        Center(child: Text(username, style: theme.textTheme.headlineSmall)),
        const SizedBox(height: 20),

        ProfileStatsSection(
          timesCompleted: timesCompleted,
          chapters: chaptersCycle,
          booksDone: booksDone,
        ),
      ],
    );
  }
}

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.timesCompleted,
    required this.chapters,
    required this.booksDone,
  });

  final int timesCompleted;
  final int chapters;
  final int booksDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;
    final ratio = (chapters / totalChaptersInBible).clamp(0.0, 1.0);
    return Column(
      children: [
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
                strings.timesLabel(timesCompleted),
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
                value: '$chapters/$totalChaptersInBible',
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
                  Expanded(child: Text(strings.overallProgress)),
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
      ],
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
