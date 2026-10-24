import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'data/account_controller.dart';
import 'data/auth_service.dart';
import 'data/cloud_repository.dart';
import 'data/progress_controller.dart';
import 'data/quiz_repository.dart';
import 'data/settings_controller.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart'; // created by `flutterfire configure`
import 'settings_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  final progress = ProgressController(await Hive.openBox('progress'));
  final settings = SettingsController(await Hive.openBox('settings'));
  final cloud = CloudRepository();
  final account = AccountController(
    auth: AuthService(),
    cloud: cloud,
    progress: progress,
    settings: settings,
    box: await Hive.openBox('account'),
  );
  await account.start();

  final quizRepo = QuizRepository();

  runApp(
    BibleTrackApp(
      progress: progress,
      settings: settings,
      account: account,
      cloud: cloud,
      quizRepo: quizRepo,
    ),
  );
}

class BibleTrackApp extends StatelessWidget {
  const BibleTrackApp({
    super.key,
    required this.progress,
    required this.settings,
    required this.account,
    required this.cloud,
    required this.quizRepo,
  });

  final ProgressController progress;
  final SettingsController settings;
  final AccountController account;
  final CloudRepository cloud;
  final QuizRepository quizRepo;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Bible Track',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          locale: Locale(settings.language),
          supportedLocales: const [Locale('fil'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AuthGate(
            account: account,
            progress: progress,
            cloud: cloud,
            quizRepo: quizRepo,
          ),
        ),
      ),
    );
  }
}
