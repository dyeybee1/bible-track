import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../settings_scope.dart';
import '../../widgets/app_logo.dart';

/// Shown once, right after the first login.
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key, required this.account});

  final AccountController account;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: _suggestion(),
  );
  String? _error;

  // The first word of the Google name, as a starting point.
  String _suggestion() {
    final name = widget.account.user?.displayName?.trim() ?? '';
    if (name.isEmpty) return '';
    final first = name.split(' ').first;
    return first.length > 20 ? first.substring(0, 20) : first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.account.submitUsername(_controller.text)) {
      setState(() => _error = context.s.usernameRule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.s;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(size: 80),
                  const SizedBox(height: 24),
                  Text(
                    strings.usernamePromptTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.usernamePromptHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 20,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: strings.usernameLabel,
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(strings.continueButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
