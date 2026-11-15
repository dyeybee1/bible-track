import 'package:flutter/widgets.dart';

/// Makes the existing profile route available to headers on every page.
class ProfileAccess extends InheritedWidget {
  const ProfileAccess({
    super.key,
    required this.profileBuilder,
    required super.child,
  });

  final WidgetBuilder profileBuilder;

  static ProfileAccess? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileAccess>();

  @override
  bool updateShouldNotify(ProfileAccess oldWidget) =>
      profileBuilder != oldWidget.profileBuilder;
}
