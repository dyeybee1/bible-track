import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';

import '../models/sync_status.dart';
import 'auth_service.dart';
import 'cloud_repository.dart';
import 'progress_controller.dart';
import 'settings_controller.dart';
import 'sync_merge.dart';

enum AuthPhase { loading, signedOut, needsUsername, ready }

/// Knows who is logged in and keeps this phone and the cloud in sync.
///
/// The phone is always the main copy: the app works offline and saves to Hive
/// first. The cloud sync runs in the background a few seconds after a change,
/// when the app opens, and when it comes back to the foreground.
class AccountController extends ChangeNotifier with WidgetsBindingObserver {
  AccountController({
    required AuthService auth,
    required CloudRepository cloud,
    required ProgressController progress,
    required SettingsController settings,
    required Box<dynamic> box,
  }) : _auth = auth,
       _cloud = cloud,
       _progress = progress,
       _settings = settings,
       _box = box;

  static const String _kUid = 'uid';

  final AuthService _auth;
  final CloudRepository _cloud;
  final ProgressController _progress;
  final SettingsController _settings;
  final Box<dynamic> _box;

  AuthPhase _phase = AuthPhase.loading;
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _signingIn = false;
  bool _signInFailed = false;

  bool _syncing = false;
  bool _syncAgain = false;
  bool _applying = false; // true while we ourselves change local data
  int _knownUsernameAt = 0;
  bool _knownShowOnLeaderboard = false;
  int _handleToken = 0;

  Timer? _debounce;
  Timer? _retry;
  StreamSubscription<User?>? _sub;

  AuthPhase get phase => _phase;
  SyncStatus get syncStatus => _syncStatus;
  bool get signingIn => _signingIn;
  bool get signInFailed => _signInFailed;
  User? get user => _auth.currentUser;

  /// True when there may be changes that are not in the cloud yet.
  bool get hasUnsyncedChanges =>
      _syncing ||
      _syncStatus == SyncStatus.failed ||
      (_debounce?.isActive ?? false);

  // ------------------------------------------------------------ startup

  Future<void> start() async {
    try {
      await _auth.init();
    } catch (_) {
      // Sign-in will report the problem when the user tries it.
    }
    _knownUsernameAt = _settings.usernameUpdatedAt;
    _knownShowOnLeaderboard = _settings.showOnLeaderboard;
    WidgetsBinding.instance.addObserver(this);
    _progress.addListener(_onLocalChange);
    _settings.addListener(_onSettingsChange);
    _sub = _auth.authChanges.listen(_handleUser);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.removeListener(_onLocalChange);
    _settings.removeListener(_onSettingsChange);
    _sub?.cancel();
    _debounce?.cancel();
    _retry?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSync(delay: const Duration(seconds: 1));
    } else if (state == AppLifecycleState.paused) {
      _debounce?.cancel();
      unawaited(syncNow());
    }
  }

  // ------------------------------------------------------------ login state

  Future<void> _handleUser(User? user) async {
    final token = ++_handleToken;

    if (user == null) {
      _debounce?.cancel();
      _retry?.cancel();
      _setPhase(AuthPhase.signedOut);
      return;
    }

    // A different Google account logged in on this phone: the progress that is
    // here belongs to the other account, so it must not be mixed in.
    final lastUid = _box.get(_kUid);
    if (lastUid is String && lastUid != user.uid) {
      _setPhase(AuthPhase.loading);
      _applying = true;
      _progress.wipeLocal();
      _settings.clearUsername();
      _applying = false;
      _knownUsernameAt = _settings.usernameUpdatedAt;
      _syncStatus = SyncStatus.idle;
    }
    await _box.put(_kUid, user.uid);

    // New phone, or first login: look for the username saved in the cloud.
    if (_settings.username == null) {
      _setPhase(AuthPhase.loading);
      try {
        final remote = await _cloud.fetchState(user.uid);
        if (token != _handleToken) return;
        final name = remote.username;
        if (name != null) {
          _applying = true;
          _settings.applyRemoteUsername(name, remote.usernameAt);
          _applying = false;
          _knownUsernameAt = _settings.usernameUpdatedAt;
        }
      } catch (_) {
        if (token != _handleToken) return;
      }
    }

    _setPhase(
      _settings.username == null ? AuthPhase.needsUsername : AuthPhase.ready,
    );
    if (_phase == AuthPhase.ready) {
      _scheduleSync(delay: const Duration(milliseconds: 500));
    }
  }

  void _setPhase(AuthPhase p) {
    _phase = p;
    notifyListeners();
  }

  Future<void> signIn() async {
    if (_signingIn) return;
    _signingIn = true;
    _signInFailed = false;
    notifyListeners();
    final result = await _auth.signInWithGoogle();
    _signingIn = false;
    _signInFailed = result == SignInResult.failed;
    notifyListeners();
  }

  /// Choose another Google account. Progress of the new account replaces the
  /// progress on this phone (the old account keeps its copy in the cloud).
  Future<SignInResult> switchAccount() => _auth.switchAccount();

  Future<void> signOut() => _auth.signOut();

  /// Called by the "what should we call you?" screen. Returns false if invalid.
  bool submitUsername(String name) {
    if (!_settings.setUsername(name)) return false;
    _setPhase(AuthPhase.ready);
    _scheduleSync();
    return true;
  }

  // ------------------------------------------------------------ syncing

  void _onLocalChange() {
    if (_applying) return;
    _scheduleSync();
  }

  void _onSettingsChange() {
    if (_applying) return;
    final usernameChanged =
        _settings.usernameUpdatedAt != _knownUsernameAt;
    final leaderboardChanged =
        _settings.showOnLeaderboard != _knownShowOnLeaderboard;
    if (usernameChanged) {
      _knownUsernameAt = _settings.usernameUpdatedAt;
    }
    if (leaderboardChanged) {
      _knownShowOnLeaderboard = _settings.showOnLeaderboard;
    }
    if (usernameChanged || leaderboardChanged) {
      _scheduleSync();
    }
  }

  void _scheduleSync({Duration delay = const Duration(seconds: 3)}) {
    if (_phase != AuthPhase.ready) return;
    _debounce?.cancel();
    _debounce = Timer(delay, () => unawaited(syncNow()));
  }

  void _setSyncStatus(SyncStatus s) {
    _syncStatus = s;
    notifyListeners();
  }

  Future<void> syncNow() async {
    final current = _auth.currentUser;
    if (current == null || _phase != AuthPhase.ready) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }

    _syncing = true;
    _debounce?.cancel();
    _setSyncStatus(SyncStatus.syncing);

    final baseline = _progress.exportRecords();
    final local = SyncState(
      cycle: _progress.cycle,
      books: baseline,
      username: _settings.username,
      usernameAt: _settings.usernameUpdatedAt,
    );

    try {
      final merged = await _cloud
          .sync(current.uid, local)
          .timeout(const Duration(seconds: 20));

      _applying = true;
      _progress.applyMerge(merged.cycle, merged.books, baseline);
      final name = merged.username;
      if (name != null) _settings.applyRemoteUsername(name, merged.usernameAt);
      _knownUsernameAt = _settings.usernameUpdatedAt;
      _applying = false;

      _retry?.cancel();
      _setSyncStatus(SyncStatus.synced);

      // Keep the public leaderboard entry in sync.
      final uid = current.uid;
      unawaited(_syncPublicProfile(uid));
    } catch (_) {
      _applying = false;
      _setSyncStatus(SyncStatus.failed);
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 30), () => unawaited(syncNow()));
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        _scheduleSync(delay: const Duration(seconds: 1));
      }
    }
  }

  /// Writes or deletes publicProfiles/{uid} depending on the setting.
  Future<void> _syncPublicProfile(String uid) async {
    if (_settings.showOnLeaderboard) {
      final name = _settings.username;
      if (name == null) return; // not ready yet
      try {
        await _cloud.updatePublicProfile(
          uid: uid,
          username: name,
          chaptersRead: _progress.chaptersReadLifetime,
          completedBooks: _progress.completedBooks,
        );
      } catch (_) {
        // Non-critical; will be retried on the next sync.
      }
    } else {
      try {
        await _cloud.deletePublicProfile(uid);
      } catch (_) {
        // Non-critical.
      }
    }
  }
}
