import 'package:flutter/material.dart';

import '../data/rank_system.dart';
import '../settings_scope.dart';

/// Four star slots for every finite division, or the unlimited top-tier count.
class StarProgress extends StatelessWidget {
  const StarProgress({super.key, required this.rank, this.color});

  final RankInfo rank;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.tertiary;
    if (rank.isTopTier) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.s.rankStars(rank.topStars),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
          if (rank.nextMilestone != null) ...[
            const SizedBox(height: 8),
            MilestoneProgress(rank: rank, color: c),
          ],
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kStarsPerDivision; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              i < rank.starsInDivision
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 28,
              color: i < rank.starsInDivision ? c : c.withAlpha(80),
            ),
          ),
      ],
    );
  }
}

/// Shared top-tier counter and thin bar; no extra milestone prose.
class MilestoneProgress extends StatelessWidget {
  const MilestoneProgress({super.key, required this.rank, this.color});
  final RankInfo rank;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final threshold = rank.nextMilestoneThreshold;
    if (threshold == null) return const SizedBox.shrink();
    final counter = '${rank.topStars} / $threshold';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: rank.milestoneProgress,
            minHeight: 3,
            color: color,
            semanticsLabel: counter,
          ),
          const SizedBox(height: 4),
          Text(counter, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
