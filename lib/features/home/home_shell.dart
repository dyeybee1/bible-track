import 'package:flutter/material.dart';

import '../../data/account_controller.dart';
import '../../data/cloud_repository.dart';
import '../../data/progress_controller.dart';
import '../../data/quiz_repository.dart';
import '../../settings_scope.dart';
import '../books/books_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../settings/settings_screen.dart';
import '../spinner/spinner_screen.dart';

/// The main screen with the bottom navigation bar.
///
/// Tab order (index):
///   0 – Books    (Mga Libro / Books)
///   1 – Spin     (Paikot   / Spinner)
///   2 – Leaderboard (Ranggo / Leaderboard)  ← new
///   3 – Settings. Profile opens from the shared header.
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

  @override
  Widget build(BuildContext context) {
    final strings = context.s;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          // 0 – Books
          BooksScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
            quizRepo: widget.quizRepo,
            onSpin: () => setState(() => _index = 1),
          ),
          // 1 – Spin
          SpinnerScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
            quizRepo: widget.quizRepo,
          ),
          // 2 – Leaderboard
          LeaderboardScreen(
            progress: widget.progress,
            account: widget.account,
            cloud: widget.cloud,
          ),
          // 3 – Settings
          SettingsScreen(account: widget.account),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: strings.navBooks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.casino_outlined),
              selectedIcon: const Icon(Icons.casino),
              label: strings.navSpin,
            ),
            NavigationDestination(
              icon: const Icon(Icons.emoji_events_outlined),
              selectedIcon: const Icon(Icons.emoji_events),
              label: strings.navLeaderboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: strings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
