import 'package:flutter/widgets.dart';

/// Makes Profile and its Settings route available throughout the app.
class ProfileAccess extends InheritedWidget {
  const ProfileAccess({
    super.key,
    required this.profileBuilder,
    required this.settingsBuilder,
    required super.child,
  });

  final WidgetBuilder profileBuilder;
  final WidgetBuilder settingsBuilder;

  static ProfileAccess? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileAccess>();

  @override
  bool updateShouldNotify(ProfileAccess oldWidget) =>
      profileBuilder != oldWidget.profileBuilder ||
      settingsBuilder != oldWidget.settingsBuilder;
}
