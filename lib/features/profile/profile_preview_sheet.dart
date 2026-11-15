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
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: ctx.s.chapterClose,
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
          RankBadge(tier: rank.tier, size: 64),
          const SizedBox(height: 12),
          Text(
            username,
            style: Theme.of(ctx).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            ctx.s.rankName(rank),
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
              color: Theme.of(ctx).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$chaptersRead ${ctx.s.leaderboardChapters}',
              style: Theme.of(ctx).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(ctx.s.viewProfile),
            ),
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
