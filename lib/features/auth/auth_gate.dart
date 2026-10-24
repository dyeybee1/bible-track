import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/settings_controller.dart';
import '../../settings_scope.dart';
import '../home/home_shell.dart';
import '../intro/intro_screen.dart';
import 'login_screen.dart';
import 'username_screen.dart';

/// Decides which screen to show: login, username prompt, intro, or the app itself.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.account,
    required this.progress,
    required this.cloud,
  });

  final AccountController account;
  final ProgressController progress;
  final CloudRepository cloud;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Once-per-process flag: whether we have already shown the intro this session.
  bool _shownThisSession = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.account,
      builder: (context, _) {
        switch (widget.account.phase) {
          case AuthPhase.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthPhase.signedOut:
            return LoginScreen(account: widget.account);
          case AuthPhase.needsUsername:
            return UsernameScreen(account: widget.account);
          case AuthPhase.ready:
            final settings = SettingsScope.of(context);
            final needsIntro = kShowIntroEveryLaunch
                ? !_shownThisSession
                : !settings.introSeen;

            if (needsIntro) {
              return IntroScreen(
                onDone: () {
                  settings.markIntroSeen();
                  setState(() => _shownThisSession = true);
                },
              );
            }
            return HomeShell(
              progress: widget.progress,
              account: widget.account,
              cloud: widget.cloud,
            );
        }
      },
    );
  }
}
