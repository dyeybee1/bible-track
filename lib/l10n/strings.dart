import '../models/book.dart';
import '../models/sync_status.dart';

/// All texts of the app in Filipino ('fil') and English ('en').
/// To add a text: add one getter/method here, then use it with `context.s`.
class Strings {
  const Strings(this.lang);

  /// 'fil' or 'en'
  final String lang;

  bool get _fil => lang == 'fil';
  String _t(String fil, String en) => _fil ? fil : en;

  // ---- navigation ----
  String get navBooks => _t('Mga Libro', 'Books');
  String get navSpin => _t('Paikot', 'Spinner');
  String get navProfile => 'Profile';
  String get navSettings => _t('Setting', 'Settings');

  // ---- books list ----
  String get booksTitle => _t('Mga Libro', 'Books');

  String sectionName(Section s) {
    switch (s) {
      case Section.oldTestament:
        return _t('Lumang Tipan', 'Old Testament');
      case Section.newTestament:
        return _t('Bagong Tipan', 'New Testament');
      case Section.deuterocanonical:
        return 'Deuterocanonical';
    }
  }

  String finishedCount(int done, int total) =>
      _t('$done/$total natapos', '$done/$total finished');

  String bookSemantics(String name, int read, int total, bool done) => _t(
    '$name, $read sa $total kabanata${done ? ', tapos na' : ''}',
    '$name, $read of $total chapters${done ? ', finished' : ''}',
  );

  // ---- chapter screen ----
  String chaptersCount(int read, int total) =>
      _t('$read/$total kabanata', '$read/$total chapters');
  String chapterCountLabel(int n) =>
      _t('$n kabanata', n == 1 ? '1 chapter' : '$n chapters');
  String get finishedLabel => _t('Tapos na', 'Finished');
  String finishedBookMessage(String name) =>
      _t('Natapos mo na ang $name!', 'You finished $name!');
  String get markUpTo => _t('Markahan hanggang dito', 'Mark up to here');
  String get markAll => _t('Markahan lahat', 'Mark all');
  String get clearAll => _t('Alisin lahat', 'Clear all');
  String get upToHint => _t(
    'I-tap ang huling kabanatang nabasa mo.',
    'Tap the last chapter you read.',
  );
  String get clearTitle => _t('Alisin ang lahat?', 'Clear everything?');
  String clearBody(String name) => _t(
    'Mabubura ang lahat ng nabasang kabanata ng $name.',
    'All chapters you marked as read in $name will be removed.',
  );
  String get cancel => _t('Kanselahin', 'Cancel');
  String get clearConfirm => _t('Alisin', 'Clear');
  String chapterSemantics(int n, bool read) => _t(
    'Kabanata $n${read ? ', nabasa na' : ''}',
    'Chapter $n${read ? ', read' : ''}',
  );

  // ---- spinner ----
  String get spinTitle => _t('Ano ang babasahin?', 'What to read?');
  String get spinIntro => _t(
    'Hindi alam kung ano ang babasahin? Paikutin ang gulong.',
    "Not sure what to read? Spin the wheel.",
  );
  String get allBooksFinished =>
      _t('Natapos mo na ang lahat ng libro!', "You've finished every book!");
  String get scopeAllBooksFinished => _t(
    'Natapos mo na ang lahat ng libro sa scope na ito!',
    "You've finished all books in this scope!",
  );
  String wheelSemantics(List<String> names) => _t(
    'Gulong ng mga libro: ${names.join(', ')}',
    'Book wheel: ${names.join(', ')}',
  );
  String wheelCount(int n) {
    return _t(
      '$n libro sa gulong.',
      n == 1 ? '1 book on the wheel.' : '$n books on the wheel.',
    );
  }

  String get includeFinished =>
      _t('Isama ang mga natapos na', 'Include finished books');
  String get spinButton => _t('Paikutin', 'Spin');
  String get spinAgain => _t('Ikot ulit', 'Spin again');
  String get readLabel => _t('Basahin ang', 'Read');
  String get openBook => _t('Buksan ang libro', 'Open book');

  // ---- spinner scope ----
  String get scopeAll => _t('Lahat', 'All');
  String get scopeOldTestament => _t('Lumang Tipan', 'Old Testament');
  String get scopeNewTestament => _t('Bagong Tipan', 'New Testament');
  String get spinScopeSemantics => _t('Piliin ang saklaw', 'Choose scope');

  // ---- intro screen ----
  String get introTitle => _t('Kunin ang iyong Biblia', 'Get your Bible');
  String get introBody => _t(
    'Ang Bible Track ay para sa pagsubaybay ng progress mo lang. Walang teksto ng Biblia sa app na ito. Kumuha ng sarili mong Biblia (libro o app), basahin ito, at markahan dito ang mga kabanatang natapos mo.',
    'Bible Track only tracks your progress. It does not contain the Bible text. Get your own Bible (printed or an app), read it, and mark the chapters you finish here.',
  );
  String get introStep1 => _t('Kunin ang iyong Biblia', 'Get your Bible');
  String get introStep2 => _t('Magbasa ng kabanata', 'Read a chapter');
  String get introStep3 =>
      _t('Markahan dito ang natapos mo', 'Mark it as read here');
  String get introStartReading => _t('Simulan ang pagbabasa', 'Start reading');
  String get introGotIt => _t('Sige', 'Got it');

  // ---- how-to button (books screen) ----
  String get howToUse => _t('Paano gamitin', 'How to use');

  // ---- profile ----
  String get defaultUsername => _t('Mambabasa', 'Reader');
  String get wholeBibleFinished =>
      _t('Natapos ang buong Biblia', 'Finished the whole Bible');
  String timesLabel(int n) => _t('$n beses', n == 1 ? '1 time' : '$n times');
  String get booksFinishedLabel => _t('Natapos na libro', 'Books finished');
  String get chaptersReadLabel => _t('Nabasang kabanata', 'Chapters read');
  String get overallProgress => _t('Kabuuang progress', 'Overall progress');
  String get startOver => _t('Magsimulang muli', 'Start over');
  String get startOverHint => _t(
    'Magagamit kapag tapos na ang lahat ng libro.',
    'Available once every book is finished.',
  );
  String get startOverTitle => _t('Magsimula ulit?', 'Start over?');
  String get startOverBody => _t(
    'Magiging bago ulit ang lahat ng libro, at madadagdagan ng 1 ang bilang ng beses na natapos mo ang Biblia.',
    'Every book will be unread again, and the number of times you finished the Bible goes up by 1.',
  );
  String get startOverConfirm => _t('Magsimula', 'Start');
  String get startOverDone => _t(
    'Nagsimula ka ulit. Magandang pagbabasa!',
    'You started over. Happy reading!',
  );

  // ---- settings ----
  String get usernameLabel => 'Username';
  String get usernameDialogTitle =>
      _t('Palitan ang username', 'Change username');
  String get usernameRule =>
      _t('Dapat 2 hanggang 20 titik.', 'Must be 2 to 20 characters.');
  String get save => _t('I-save', 'Save');
  String get googleAccount => 'Google account';
  String get googleNotConnected => _t(
    'Hindi pa naka-connect. Idadagdag sa susunod na bersyon.',
    'Not connected yet. Coming in a later version.',
  );
  String get languageLabel => _t('Wika', 'Language');
  String get themeLabel => _t('Tema', 'Theme');
  String get themeLight => _t('Maliwanag', 'Light');
  String get themeDark => _t('Madilim', 'Dark');

  // ---- login and username prompt ----
  String get loginTagline =>
      _t('Subaybayan ang pagbabasa mo ng Biblia.', 'Track your Bible reading.');
  String get loginGoogle =>
      _t('Magpatuloy gamit ang Google', 'Continue with Google');
  String get loginNeedsInternet => _t(
    'Kailangan ng internet para sa unang login.',
    'You need internet for the first login.',
  );
  String get loginFailed => _t(
    'Hindi nakapag-login. Siguraduhing may internet at subukan ulit.',
    "Couldn't log in. Check your internet and try again.",
  );
  String get usernamePromptTitle =>
      _t('Ano ang itatawag namin sa iyo?', 'What should we call you?');
  String get usernamePromptHint => _t(
    'Pwede mo itong palitan sa Settings.',
    'You can change this later in Settings.',
  );
  String get continueButton => _t('Magpatuloy', 'Continue');

  // ---- account and sync (settings) ----
  String get switchAccount => _t('Palitan ang account', 'Switch account');
  String switchAccountBody(bool unsynced) => _t(
    'Ang progress ng ibang account ang ilalagay sa phone na ito. Naka-save pa rin sa cloud ang progress ng kasalukuyang account.'
        '${unsynced ? ' Babala: may mga pagbabago na hindi pa na-upload at mawawala ang mga ito.' : ''}',
    "The other account's progress will replace the progress on this phone. The current account keeps its progress in the cloud."
        '${unsynced ? ' Warning: some changes are not uploaded yet and will be lost.' : ''}',
  );
  String get logout => _t('Mag-logout', 'Log out');
  String get logoutTitle => _t('Mag-logout?', 'Log out?');
  String get logoutBody => _t(
    'Mananatili sa phone na ito ang progress mo. Mag-login ulit para ma-sync.',
    'Your progress stays on this phone. Log in again to sync.',
  );
  String get syncNow => _t('I-sync ngayon', 'Sync now');
  String syncStatusText(SyncStatus s) {
    switch (s) {
      case SyncStatus.idle:
        return _t('Hindi pa naka-sync', 'Not synced yet');
      case SyncStatus.syncing:
        return _t('Nagsi-sync...', 'Syncing...');
      case SyncStatus.synced:
        return _t('Naka-sync na', 'Up to date');
      case SyncStatus.failed:
        return _t(
          'Hindi makapag-sync. Susubukan ulit.',
          "Couldn't sync. Will try again.",
        );
    }
  }

  // ---- settings (continued) ----
  String get showOnLeaderboardLabel =>
      _t('Ipakita sa Ranggo', 'Show on Leaderboard');
  String get showOnLeaderboardHint => _t(
    'Ipapakita ang iyong username at bilang ng nabasang kabanata sa pampublikong ranggo.',
    'Your username and chapter count will be visible on the public leaderboard.',
  );

  // ---- navigation (continued) ----
  String get navLeaderboard => _t('Ranggo', 'Leaderboard');

  // ---- leaderboard screen ----
  String get leaderboardTitle => _t('Ranggo', 'Leaderboard');
  String get leaderboardLoading => _t('Naglo-load...', 'Loading...');
  String get leaderboardOffline => _t(
    'Hindi available offline. Kumonekta sa internet at subukan ulit.',
    'Not available offline. Connect to the internet and try again.',
  );
  String get leaderboardEmpty => _t(
    'Walang sinuman ang naka-opt-in sa leaderboard pa.',
    'No one has opted in to the leaderboard yet.',
  );
  String get leaderboardRetry => _t('Subukan ulit', 'Try again');
  String get leaderboardOptInPrompt => _t(
    'I-on ang "Ipakita sa Ranggo" sa Settings para makita ang iyong pangalan dito.',
    'Turn on "Show on Leaderboard" in Settings to appear here.',
  );
  String leaderboardRankLabel(int rank) =>
      _t('Ranggo #$rank', 'Rank #$rank');
  String leaderboardYourRank(int rank) =>
      _t('Ranggo mo: #$rank', 'Your rank: #$rank');
  String get leaderboardYourRankUnknown =>
      _t('Hindi ma-compute ang ranggo mo.', 'Your rank could not be computed.');
  String get leaderboardChapters => _t('kabanata', 'chapters');
  String get leaderboardTopN => _t('Top 50', 'Top 50');

  // ---- chapter screen: who finished this book ----
  String get finishersTitle => _t('Mga Nakatapos', 'Finished by');
  String finishersCount(int n) =>
      _t('$n nakatapos', n == 1 ? '1 finished' : '$n finished');
  String get finishersLoading => _t('Naglo-load...', 'Loading...');
  String get finishersOffline => _t(
    'Hindi available offline.',
    'Not available offline.',
  );
  String get finishersEmpty => _t(
    'Wala pang nakatapos ng librong ito.',
    'No one has finished this book yet.',
  );
  String get finishersYou => _t('Ikaw', 'You');
  String get finishersShowAll => _t('Tingnan lahat', 'See all');
}
