import 'package:flutter/material.dart';

import '../../data/rank_system.dart';
import '../../settings_scope.dart';

/// All tier artwork lives here so custom badges can replace these icons later.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.tier, this.size = 48});

  final RankTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = const [
      Icons.grain,
      Icons.eco_outlined,
      Icons.local_florist_outlined,
      Icons.park_outlined,
      Icons.spa_outlined,
      Icons.shield_outlined,
      Icons.explore_outlined,
      Icons.auto_awesome,
      Icons.auto_stories,
    ][rankLadder.indexOf(tier)];
    final foreground = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: context.s.rankTierName(tier),
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: foreground.withAlpha(24),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, color: foreground, size: size * 0.6),
      ),
    );
  }
}
