import 'package:flutter/material.dart';

import '../../data/progress_controller.dart';
import '../../data/rank_system.dart';
import '../../models/book.dart';
import 'star_change_screen.dart';

/// Called only for an explicit chapter-read action (quiz passed or direct mark
/// when the chapter has no questions). Never call on sync, app-start, or
/// startNewCycle.
///
/// Captures the star counts around the write and opens [StarChangeScreen].
Future<void> showStarChangeScreen({
  required BuildContext context,
  required ProgressController progress,
  required Book book,
  required int chapter,
}) async {
  final starsBefore = progress.chaptersReadLifetime;
  final rankBefore = rankForStars(starsBefore);

  progress.markChapterRead(book, chapter);

  final starsAfter = progress.chaptersReadLifetime;
  if (starsAfter == starsBefore || !context.mounted) return;

  final rankAfter = rankForStars(starsAfter);
  await pushStarChangeScreen(
    context: context,
    before: rankBefore,
    after: rankAfter,
    maxStarsEver: progress.maxStarsEver,
    isGain: starsAfter > starsBefore,
  );
}
