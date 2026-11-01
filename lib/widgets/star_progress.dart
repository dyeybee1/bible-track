import 'package:flutter/material.dart';

import '../data/rank_system.dart';
import '../settings_scope.dart';

/// Shared star-progress widget used in [StarChangeScreen], profile cards, etc.
///
/// Rules:
/// * **Top tier** (division == null): shows the raw [totalStars] count as text.
/// * **≤ 10 stars per division**: a row of star icons (filled / outline).
/// * **> 10 stars per division**: a [LinearProgressIndicator] with a "x / y" label.
///
/// Pass [highlightIndex] to light up a specific star in the row (used for
/// the "new star flies in" animation parent – the parent replaces that star
/// with its own animated widget, so [highlightIndex] just keeps the slot empty).
class StarProgress extends StatelessWidget {
  const StarProgress({
    super.key,
    required this.rank,
    this.totalStars,
    this.overrideFilled,
    this.color,
  });

  final RankInfo rank;

  /// Required for the top-tier display (shows raw star count).
  final int? totalStars;

  /// If set, draws this many filled stars instead of [rank.starsInDivision].
  /// Useful for animating the bar/row to a transient state.
  final int? overrideFilled;

  /// Icon / bar colour. Defaults to [ColorScheme.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = context.s;
    final c = color ?? scheme.primary;

    // ── Top tier ──────────────────────────────────────────────────────────────
    if (rank.division == null) {
      final stars = totalStars ?? rank.starsInDivision;
      return Text(
        strings.rankStars(stars),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      );
    }

    final filled = overrideFilled ?? rank.starsInDivision;
    final total = rank.starsForDivision;

    // ── Star row (≤ 10 per division) ─────────────────────────────────────────
    if (total <= 10) {
      return ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < total; i++)
              Icon(
                i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 28,
                color: i < filled ? c : c.withAlpha(80),
              ),
          ],
        ),
      );
    }

    // ── Progress bar (> 10 per division) ─────────────────────────────────────
    final ratio = (filled / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: c.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(c),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.rankStarProgress(filled, total),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }
}

