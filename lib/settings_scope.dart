import 'package:flutter/widgets.dart';

import 'data/settings_controller.dart';
import 'l10n/strings.dart';

/// Makes the settings available everywhere below it and rebuilds the widgets
/// that use it when the language, theme or username changes.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found above this widget');
    return scope!.notifier!;
  }
}

extension StringsOnContext on BuildContext {
  /// The texts in the current language: `context.s.booksTitle`.
  Strings get s => SettingsScope.of(this).strings;
}
