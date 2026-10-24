import 'package:flutter/material.dart';

import '../../settings_scope.dart';
import '../../widgets/app_logo.dart';

/// Shown at first launch and accessible from the Books screen "How to use" button.
///
/// When [fromBooks] is true the button says "Sige / Got it" and pops the route.
/// When false (first launch) the button says "Simulan ang pagbabasa / Start reading"
/// and calls [onDone].
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key, this.fromBooks = false, this.onDone});

  final bool fromBooks;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;

    void handleButton() {
      if (fromBooks) {
        Navigator.of(context).pop();
      } else {
        onDone?.call();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 88),
                  const SizedBox(height: 24),
                  Text(
                    strings.introTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.introBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _StepRow(
                    step: 1,
                    icon: Icons.menu_book_outlined,
                    label: strings.introStep1,
                  ),
                  const SizedBox(height: 16),
                  _StepRow(
                    step: 2,
                    icon: Icons.auto_stories_outlined,
                    label: strings.introStep2,
                  ),
                  const SizedBox(height: 16),
                  _StepRow(
                    step: 3,
                    icon: Icons.check_circle_outline,
                    label: strings.introStep3,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: handleButton,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          fromBooks
                              ? strings.introGotIt
                              : strings.introStartReading,
                        ),
                      ),
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

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.icon, required this.label});

  final int step;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, size: 24, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
