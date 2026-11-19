import 'package:bible_track/data/account_controller.dart';
import 'package:bible_track/data/progress_controller.dart';
import 'package:bible_track/data/quiz_repository.dart';
import 'package:bible_track/data/settings_controller.dart';
import 'package:bible_track/features/home/home_shell.dart';
import 'package:bible_track/features/spinner/spinner_screen.dart';
import 'package:bible_track/settings_scope.dart';
import 'package:bible_track/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../widget_test.dart' show FakeAuthService, FakeCloudRepository;

class LibraryFixture {
  late final SettingsController settings;
  late final ProgressController progress;
  late final AccountController account;
  final cloud = FakeCloudRepository();
  final quiz = QuizRepository();
  late final Box<dynamic> settingsBox;

  Future<void> init() async {
    settingsBox = await Hive.openBox('library_s', bytes: Uint8List(0));
    settings = SettingsController(settingsBox);
    progress = ProgressController(
      await Hive.openBox('library_p', bytes: Uint8List(0)),
    );
    account = AccountController(
      auth: FakeAuthService(),
      cloud: cloud,
      progress: progress,
      settings: settings,
      box: await Hive.openBox('library_a', bytes: Uint8List(0)),
    );
  }

  Widget app({
    bool spinner = false,
    bool dark = false,
    double scale = 1,
    bool reduceMotion = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) => SettingsScope(
    controller: settings,
    child: MaterialApp(
      theme: dark ? darkTheme : lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
          padding: padding,
        ),
        child: child!,
      ),
      home: spinner
          ? SpinnerScreen(
              progress: progress,
              account: account,
              cloud: cloud,
              quizRepo: quiz,
            )
          : HomeShell(
              progress: progress,
              account: account,
              cloud: cloud,
              quizRepo: quiz,
            ),
    ),
  );

  Future<void> dispose() async {
    account.dispose();
    progress.dispose();
    settings.dispose();
    await Hive.close();
  }
}

void libraryPhone(WidgetTester tester, [Size size = const Size(390, 844)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loadLibraryFonts() async {
  for (final family in ['Newsreader', 'PlusJakartaSans']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}
