import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../settings_scope.dart';
import '../../widgets/app_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.account});

  final AccountController account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ListenableBuilder(
                listenable: account,
                builder: (context, _) {
                  final busy = account.signingIn;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 96),
                      const SizedBox(height: 20),
                      Text(
                        'Bible Track',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.loginTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: busy ? null : account.signIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.loginGoogle),
                          ),
                        ),
                      ),
                      if (account.signInFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            strings.loginFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        strings.loginNeedsInternet,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
