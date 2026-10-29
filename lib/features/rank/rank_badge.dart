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
    final (icon, color) = const [
      (Icons.grain, Color(0xFF986B38)),
      (Icons.eco_outlined, Color(0xFF4B8B40)),
      (Icons.local_florist_outlined, Color(0xFF23866C)),
      (Icons.park_outlined, Color(0xFF2777A2)),
      (Icons.spa_outlined, Color(0xFF8255B4)),
      (Icons.shield_outlined, Color(0xFFB16B23)),
      (Icons.auto_awesome, Color(0xFFBD496A)),
      (Icons.auto_stories, Color(0xFFC09824)),
    ][rankLadder.indexOf(tier)];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Semantics(
      label: context.s.rankTierName(tier),
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: foreground.withAlpha(24),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: foreground.withAlpha(150), width: 1.5),
        ),
        child: Icon(icon, color: foreground, size: size * 0.6),
      ),
    );
  }
}
