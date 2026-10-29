import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/auth_service.dart';
import '../../data/settings_controller.dart';
import '../../models/sync_status.dart';
import '../../settings_scope.dart';
import '../../widgets/app_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.account});

  final AccountController account;

  Future<void> _editUsername(
    BuildContext context,
    SettingsController settings,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _UsernameDialog(initial: settings.username ?? ''),
    );
    if (name != null) settings.setUsername(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.s;
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- Header (Task 6.1) ----
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: 12),
                Text(
                  'Bible Track',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.loginTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ---- Username card ----
          _Card(
            child: ListTile(
              title: Text(strings.usernameLabel),
              subtitle: Text(settings.username ?? strings.defaultUsername),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editUsername(context, settings),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Leaderboard opt-in card ----
          _Card(
            child: SwitchListTile(
              title: Text(strings.showOnLeaderboardLabel),
              subtitle: Text(
                '${strings.showOnLeaderboardHint}\n${strings.publicProfilePrivacyNotice}',
              ),
              value: settings.showOnLeaderboard,
              onChanged: settings.setShowOnLeaderboard,
            ),
          ),
          const SizedBox(height: 8),

          // ---- Account card (Task 6.2) ----
          _AccountCard(account: account),
          const SizedBox(height: 8),

          // ---- Language card ----
          _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.languageLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'fil', label: Text('Filipino')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {settings.language},
                      onSelectionChanged: (v) => settings.setLanguage(v.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Theme card ----
          _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.themeLabel, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(strings.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(strings.themeDark),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) => settings.setThemeMode(v.first),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Logout button at the bottom (Task 6.3) ----
          const SizedBox(height: 24),
          _LogoutButton(account: account),
        ],
      ),
    );
  }
}

// ---- Shared card container ----
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ---- Logout button (Task 6.3) ----
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.account});

  final AccountController account;

  Future<void> _confirmLogout(BuildContext context) async {
    final strings = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.logoutTitle),
        content: Text(strings.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.logout),
          ),
        ],
      ),
    );
    if (ok == true) await account.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = context.s;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error),
        ),
        onPressed: () => _confirmLogout(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(strings.logout),
        ),
      ),
    );
  }
}

// ---- Username dialog ----
class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.initial});

  final String initial;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.length < 2 || text.length > 20) {
      setState(() => _error = context.s.usernameRule);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AlertDialog(
      title: Text(strings.usernameDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: strings.usernameLabel,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.save)),
      ],
    );
  }
}

// ---- Account card (Task 6.2 — only Switch Account inside the card) ----
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountController account;

  Future<void> _confirmSwitch(BuildContext context) async {
    final strings = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.switchAccount),
        content: Text(strings.switchAccountBody(account.hasUnsyncedChanges)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.switchAccount),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await account.switchAccount();
    if (result == SignInResult.failed && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.loginFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = context.s;

    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final user = account.user;
        final syncing = account.syncStatus == SyncStatus.syncing;

        return _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 40,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? strings.googleAccount,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Only "Switch account" stays inside the card (Task 6.2).
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmSwitch(context),
                    child: Text(strings.switchAccount),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.syncStatusText(account.syncStatus),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: syncing ? null : account.syncNow,
                      child: Text(strings.syncNow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
