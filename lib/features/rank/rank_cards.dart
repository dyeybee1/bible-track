import 'package:flutter/material.dart';

import '../../data/rank_system.dart';
import '../../settings_scope.dart';
import '../../widgets/star_progress.dart';
import 'rank_badge.dart';

class CurrentRankCard extends StatelessWidget {
  const CurrentRankCard({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final rank = rankForStars(stars);
    final strings = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RankBadge(tier: rank.tier, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.currentRank,
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                      Text(
                        strings.rankName(rank),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StarProgress(rank: rank, color: scheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

class HighestRankCard extends StatelessWidget {
  const HighestRankCard({super.key, required this.maxStarsEver});

  final int maxStarsEver;

  @override
  Widget build(BuildContext context) {
    final rank = rankForStars(maxStarsEver);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            RankBadge(tier: rank.tier, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s.highestRank,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    context.s.rankName(rank),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
