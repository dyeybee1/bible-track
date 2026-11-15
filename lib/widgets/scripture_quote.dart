import 'package:flutter/material.dart';

import '../settings_scope.dart';
import '../theme/app_theme.dart';

class ScriptureQuote extends StatelessWidget {
  const ScriptureQuote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Column(
        children: [
          Text(
            '“${context.s.guidingVerse}”',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTypography.serif,
              fontSize: 17,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.s.guidingVerseReference,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
