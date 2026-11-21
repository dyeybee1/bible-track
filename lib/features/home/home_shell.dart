import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../settings_scope.dart';
import '../../widgets/floating_pill_nav.dart';
import '../books/books_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../spinner/spinner_screen.dart';

/// Main tabs: 0 Books, 1 Leaderboard.
/// Profile and the spinner open as pushed routes.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.progress,
    required this.account,
    required this.cloud,
    required this.quizRepo,
  });

  final ProgressController progress;
  final AccountController account;
  final CloudRepository cloud;
  final QuizRepository quizRepo;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _hintChecked = false;
  bool _showSpinHint = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hintChecked) return;
    _hintChecked = true;
    final settings = SettingsScope.of(context);
    if (settings.spinHintSeen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      settings.markSpinHintSeen();
      setState(() => _showSpinHint = true);
      _hintTimer = Timer(const Duration(seconds: 6), _dismissSpinHint);
    });
  }

  void _dismissSpinHint() {
    _hintTimer?.cancel();
    if (_showSpinHint && mounted) setState(() => _showSpinHint = false);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _openSpinner() {
    _dismissSpinHint();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SpinnerScreen(
          progress: widget.progress,
          account: widget.account,
          cloud: widget.cloud,
          quizRepo: widget.quizRepo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final padding = MediaQuery.paddingOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _dismissSpinHint(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(
              index: _index,
              children: [
                BooksScreen(
                  progress: widget.progress,
                  account: widget.account,
                  cloud: widget.cloud,
                  quizRepo: widget.quizRepo,
                  onSpin: _openSpinner,
                  showSpinHint: _showSpinHint,
                ),
                LeaderboardScreen(
                  progress: widget.progress,
                  account: widget.account,
                  cloud: widget.cloud,
                ),
              ],
            ),
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned(
                left: padding.left + 16,
                right: padding.right + 16,
                bottom: padding.bottom + 12,
                child: Center(
                  child: FloatingPillNav(
                    selectedIndex: _index,
                    onDestinationSelected: (i) {
                      _dismissSpinHint();
                      setState(() => _index = i);
                    },
                    destinations: [
                      FloatingPillDestination(
                        icon: Icons.menu_book_outlined,
                        selectedIcon: Icons.menu_book,
                        label: strings.navBooks,
                      ),
                      FloatingPillDestination(
                        icon: Icons.emoji_events_outlined,
                        selectedIcon: Icons.emoji_events,
                        label: strings.navLeaderboard,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
