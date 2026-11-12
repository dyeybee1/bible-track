import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../l10n/strings.dart';
import 'bible_translation.dart';

/// When true the intro screen is shown on every app start (once per process).
/// Flip to false for production.
const bool kShowIntroEveryLaunch = false;

/// Username, language and theme. Saved on the phone (Hive box 'settings').
/// Defaults: Filipino and light mode.
/// Only the username is synced to the cloud; language and theme stay per device.
class SettingsController extends ChangeNotifier {
  SettingsController(this._box) {
    final lang = _box.get(_kLanguage);
    if (lang == 'fil' || lang == 'en') _language = lang as String;

    _themeMode = _box.get(_kTheme) == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final name = _box.get(_kUsername);
    if (name is String && name.trim().isNotEmpty) _username = name;

    final at = _box.get(_kUsernameAt);
    if (at is int) _usernameAt = at;

    _introSeen = _box.get(_kIntroSeen) == true;
    _showOnLeaderboard = _box.get(_kShowOnLeaderboard) == true;
    _preferredBibleTranslation = switch (_box.get(_kBibleTranslation)) {
      'tl1905' => BibleTranslation.tl1905,
      'web' => BibleTranslation.web,
      _ => null,
    };
    final fontSize = _box.get(_kReaderFontSize);
    if (fontSize is num && fontSize.isFinite) {
      _readerFontSize = fontSize.toDouble().clamp(14, 30);
    }
  }

  static const _kLanguage = 'language';
  static const _kTheme = 'theme';
  static const _kUsername = 'username';
  static const _kUsernameAt = 'usernameAt';
  static const _kIntroSeen = 'introSeen';
  static const _kShowOnLeaderboard = 'showOnLeaderboard';
  static const _kBibleTranslation = 'readerTranslation';
  static const _kReaderFontSize = 'readerFontSize';

  final Box<dynamic> _box;

  String _language = 'fil';
  ThemeMode _themeMode = ThemeMode.light;
  String? _username;
  int _usernameAt = 0;
  bool _introSeen = false;
  bool _showOnLeaderboard = false;
  BibleTranslation? _preferredBibleTranslation;
  double _readerFontSize = 20;

  /// Device-only reader preferences; never included in account sync data.
  BibleTranslation get preferredBibleTranslation =>
      _preferredBibleTranslation ??
      (_language == 'fil' ? BibleTranslation.tl1905 : BibleTranslation.web);
  double get readerFontSize => _readerFontSize;

  void setPreferredBibleTranslation(BibleTranslation value) {
    _preferredBibleTranslation = value;
    _box.put(_kBibleTranslation, value.name);
    notifyListeners();
  }

  void setReaderFontSize(double value) {
    if (!value.isFinite) return;
    _readerFontSize = value.clamp(14, 30);
    _box.put(_kReaderFontSize, _readerFontSize);
    notifyListeners();
  }

  String get language => _language;
  ThemeMode get themeMode => _themeMode;

  /// null until the user picks a name (asked right after the first login).
  String? get username => _username;

  /// When the username was last changed (milliseconds since epoch).
  int get usernameUpdatedAt => _usernameAt;

  /// Whether the user has seen the intro screen.
  bool get introSeen => _introSeen;

  /// Whether the user wants their reading stats shown on the public leaderboard.
  /// Default is off.
  bool get showOnLeaderboard => _showOnLeaderboard;

  Strings get strings => Strings(_language);

  void setLanguage(String lang) {
    if (lang != 'fil' && lang != 'en') return;
    _language = lang;
    _box.put(_kLanguage, lang);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode != ThemeMode.light && mode != ThemeMode.dark) return;
    _themeMode = mode;
    _box.put(_kTheme, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  /// Returns false when the name is not valid (must be 2 to 20 characters).
  bool setUsername(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 20) return false;
    _username = trimmed;
    _usernameAt = DateTime.now().millisecondsSinceEpoch;
    _box.put(_kUsername, trimmed);
    _box.put(_kUsernameAt, _usernameAt);
    notifyListeners();
    return true;
  }

  /// A username that came from the cloud. Used only if it is newer.
  void applyRemoteUsername(String name, int at) {
    if (_username != null && at <= _usernameAt) return;
    _username = name;
    _usernameAt = at;
    _box.put(_kUsername, name);
    _box.put(_kUsernameAt, at);
    notifyListeners();
  }

  void clearUsername() {
    _username = null;
    _usernameAt = 0;
    _box.delete(_kUsername);
    _box.delete(_kUsernameAt);
    notifyListeners();
  }

  void markIntroSeen() {
    if (_introSeen) return;
    _introSeen = true;
    _box.put(_kIntroSeen, true);
    notifyListeners();
  }

  void setShowOnLeaderboard(bool value) {
    if (_showOnLeaderboard == value) return;
    _showOnLeaderboard = value;
    _box.put(_kShowOnLeaderboard, value);
    notifyListeners();
  }
}
