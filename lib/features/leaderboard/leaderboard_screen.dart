import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/leaderboard_controller.dart';
import '../../data/progress_controller.dart';
import '../../data/settings_controller.dart';
import '../../settings_scope.dart';

/// The leaderboard tab: top-50 users by chaptersRead (lifetime), with the
/// current user highlighted and their rank shown even if outside top 50.
///
/// Uses a live Firestore stream so the list updates automatically when:
///  • another user opts in / their score changes
///  • the current user enables "Show on Leaderboard" in Settings
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.progress,
    required this.account,
    required this.cloud,
  });

  final ProgressController progress;
  final AccountController account;
  final CloudRepository cloud;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with AutomaticKeepAliveClientMixin {
  LeaderboardController? _ctrl;

  @override
  bool get wantKeepAlive => false; // allow rebuild when tab is re-visited

  @override
  void initState() {
    super.initState();
    _startStream();
    // Re-subscribe when the account's public-profile write completes so that
    // own-rank picks up a freshly written entry immediately.
    widget.account.addListener(_onAccountChanged);
    widget.progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    widget.account.removeListener(_onAccountChanged);
    widget.progress.removeListener(_onProgressChanged);
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _onAccountChanged() {
    // If the user was just created / UID changed, restart the stream.
    final uid = widget.account.user?.uid;
    if (uid != null && uid != _ctrl?.currentUid) {
      _startStream();
    }
  }

  void _onProgressChanged() {
    // Keep own-rank in sync whenever the user reads more chapters.
    _ctrl?.updateMyChaptersRead(widget.progress.chaptersReadLifetime);
  }

  // ── Stream lifecycle ──────────────────────────────────────────────────────

  void _startStream() {
    final uid = widget.account.user?.uid;
    if (uid == null) return;

    _ctrl?.dispose();
    _ctrl = LeaderboardController(
      cloud: widget.cloud,
      currentUid: uid,
      myChaptersRead: widget.progress.chaptersReadLifetime,
    );
    _ctrl!.addListener(() {
      if (mounted) setState(() {});
    });
    // No explicit load() needed — controller subscribes the stream in its
    // constructor and notifies when the first snapshot arrives.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = context.s;
    final settings = SettingsScope.of(context);
    final uid = widget.account.user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.leaderboardTitle)),
        body: const SizedBox.shrink(),
      );
    }

    final ctrl = _ctrl;

    if (ctrl == null || ctrl.status == LeaderboardStatus.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.leaderboardTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.leaderboardTitle)),
      body: _LeaderboardBody(
        ctrl: ctrl,
        currentUid: uid,
        settings: settings,
        strings: strings,
        onRetry: _startStream,
        progress: widget.progress,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({
    required this.ctrl,
    required this.currentUid,
    required this.settings,
    required this.strings,
    required this.onRetry,
    required this.progress,
  });

  final LeaderboardController ctrl;
  final String currentUid;
  final SettingsController settings;
  final dynamic strings;
  final VoidCallback onRetry;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (ctrl.status == LeaderboardStatus.offline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                strings.leaderboardOffline as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(strings.leaderboardRetry as String),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.status == LeaderboardStatus.empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                strings.leaderboardEmpty as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.leaderboardOptInPrompt as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loaded state.
    final entries = ctrl.entries;
    final ownRank = ctrl.ownRank;
    final meInTop50 = entries.any((e) => e.uid == currentUid);

    return Column(
      children: [
        // ---- Own rank banner (shown when outside top 50 and rank is known) ----
        if (!meInTop50 && ownRank != null && ownRank > 0)
          _OwnRankBanner(
            rank: ownRank,
            chaptersRead: progress.chaptersReadLifetime,
            strings: strings,
            scheme: scheme,
            theme: theme,
          ),

        // ---- Hint if the user is not opted in ----
        if (!settings.showOnLeaderboard)
          _OptInHint(strings: strings, scheme: scheme, theme: theme),

        // ---- List ----
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              final rank = i + 1;
              final isMe = entry.uid == currentUid;
              return _LeaderboardTile(
                rank: rank,
                entry: entry,
                isMe: isMe,
                scheme: scheme,
                theme: theme,
                strings: strings,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OwnRankBanner extends StatelessWidget {
  const _OwnRankBanner({
    required this.rank,
    required this.chaptersRead,
    required this.strings,
    required this.scheme,
    required this.theme,
  });

  final int rank;
  final int chaptersRead;
  final dynamic strings;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.leaderboardYourRank(rank) as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$chaptersRead ${strings.leaderboardChapters}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OptInHint extends StatelessWidget {
  const _OptInHint({
    required this.strings,
    required this.scheme,
    required this.theme,
  });

  final dynamic strings;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.leaderboardOptInPrompt as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.scheme,
    required this.theme,
    required this.strings,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final ColorScheme scheme;
  final ThemeData theme;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? scheme.primaryContainer : scheme.surface;
    final borderColor =
        isMe ? scheme.primary.withAlpha(120) : scheme.outlineVariant;

    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFFFD700));
    } else if (rank == 2) {
      rankWidget = Icon(Icons.emoji_events, color: Colors.grey.shade400);
    } else if (rank == 3) {
      rankWidget = Icon(Icons.emoji_events, color: Colors.brown.shade300);
    } else {
      rankWidget = SizedBox(
        width: 28,
        child: Text(
          '$rank',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: rankWidget)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.username,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              isMe ? FontWeight.w700 : FontWeight.w500,
                          color: isMe
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ikaw',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.chaptersRead} ${strings.leaderboardChapters}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMe
                        ? scheme.onPrimaryContainer.withAlpha(180)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
