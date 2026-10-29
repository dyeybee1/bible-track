import 'package:flutter/material.dart';

import '../../data/cloud_repository.dart';
import '../../data/public_profile.dart';
import '../../settings_scope.dart';
import 'profile_sections.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.uid, this.cloud});

  final String uid;
  final CloudRepository? cloud;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<PublicProfile?> _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid || oldWidget.cloud != widget.cloud) _load();
  }

  void _load() {
    _profile = (widget.cloud ?? CloudRepository()).fetchPublicProfile(
      widget.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(strings.navProfile)),
      body: FutureBuilder<PublicProfile?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                semanticsLabel: strings.publicProfileLoading,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      strings.publicProfileOffline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => setState(_load),
                      child: Text(strings.leaderboardRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  strings.publicProfileUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ProfileDetails(
                username: profile.username,
                chaptersRead: profile.chaptersRead,
                maxStars: profile.maxStars,
                timesCompleted: profile.timesCompleted,
                chaptersCycle: profile.chaptersCycle,
                booksDone: profile.completedBooks,
              ),
              const SizedBox(height: 16),
              Text(
                strings.profileLastUpdated(profile.updatedAt),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
