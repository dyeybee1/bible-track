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
    final c = color ?? Theme.of(context).colorScheme.primary;
    if (rank.isTopTier) {
      return Text(
        context.s.rankStars(rank.topStars),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c),
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
