import 'package:flutter/material.dart';

import '../../data/progress_controller.dart';
import '../../data/rank_system.dart';
import '../../models/book.dart';
import '../../settings_scope.dart';
import 'rank_badge.dart';

/// Called only for an explicit chapter-read action, never by progress listeners.
/// Compare immediately around the write so a sync during a quiz cannot celebrate.
Future<void> markChapterReadWithRankUp({
  required BuildContext context,
  required ProgressController progress,
  required Book book,
  required int chapter,
}) async {
  final before = rankForStars(progress.chaptersReadLifetime);
  progress.markChapterRead(book, chapter);
  final after = rankForStars(progress.chaptersReadLifetime);
  if (!after.isHigherThan(before) || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final strings = ctx.s;
      return AlertDialog(
        title: Text(strings.rankUpTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1),
              duration: MediaQuery.disableAnimationsOf(ctx)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: RankBadge(tier: after.tier, size: 64),
                  ),
                  Icon(
                    Icons.star_rounded,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ],
              ),
            ),
            Text(
              strings.rankName(after),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(strings.rankUpMessage, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.rankUpContinue),
          ),
        ],
      );
    },
  );
}
