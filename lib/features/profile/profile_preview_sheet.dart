import 'package:flutter/material.dart';

import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/rank_system.dart';
import '../../settings_scope.dart';
import '../rank/rank_badge.dart';
import 'profile_screen.dart';
import 'public_profile_screen.dart';

/// Shared by leaderboard rows and the book's "Finished by" readers list.
Future<void> showProfilePreview({
  required BuildContext context,
  required String uid,
  required String username,
  required int chaptersRead,
  required String? currentUid,
  required ProgressController progress,
  required CloudRepository cloud,
}) async {
  final rank = rankForStars(chaptersRead);
  final open = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RankBadge(tier: rank.tier, size: 64),
          const SizedBox(height: 12),
          Text(
            username,
            style: Theme.of(ctx).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            ctx.s.rankName(rank),
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.s.viewProfile),
          ),
        ],
      ),
    ),
  );
  if (open != true || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => uid == currentUid
          ? ProfileScreen(progress: progress)
          : PublicProfileScreen(uid: uid, cloud: cloud),
    ),
  );
}
