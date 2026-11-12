import '../models/book.dart';
import '../data/rank_system.dart';
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
  String bookChapter(String book, int chapter) =>
      _t('$book • Kabanata $chapter', '$book • Chapter $chapter');
  String get chapterRead => _t('Basahin', 'Read');
  String get chapterReadAgain => _t('Basahin ulit', 'Read again');
  String get chapterTakeQuiz => _t('Sagutan na', 'Take the quiz');
  String chapterQuestionCount(int count) =>
      _t('$count na tanong', count == 1 ? '1 question' : '$count questions');
  String get chapterMarkRead => _t('Markahan bilang nabasa', 'Mark as read');
  String get chapterRemoveRead => _t('Alisin sa nabasa', 'Remove from read');
  String get chapterChooseHint => _t(
    'Magbasa muna, o sagutan ang quiz kapag handa ka na. Sa sarili mong bilis.',
    'Read first, or take the quiz when you feel ready. Go at your own pace.',
  );
  String get chapterReadHint => _t(
    'Maaari mong balikan ang kabanata anumang oras.',
    'You can return to this chapter whenever you like.',
  );
  String get chapterClose => _t('Isara', 'Close');
  String get readerSmaller => _t('Paliitin ang teksto', 'Smaller text');
  String get readerLarger => _t('Palakihin ang teksto', 'Larger text');
  String get readerLoading => _t('Inihahanda ang teksto…', 'Loading chapter…');
  String get readerError => _t(
    'Hindi ma-load ang teksto. Subukan ulit. Maaari mo pa ring sagutan ang quiz.',
    'The text could not be loaded. Try again. You can still take the quiz.',
  );
  String get readerRetry => _t('Subukan ulit', 'Try again');
  String get readerPending => _t(
    'Hindi pa available ang teksto ng chapter na ito. Maaari mong basahin ito sa sarili mong Bibliya.',
    'The text of this chapter is not available yet. You can read it in your own Bible.',
  );
  String get readerTagalogUnavailable => _t(
    'Hindi pa available sa Tagalog ang kabanatang ito.',
    'This chapter is not available in Tagalog yet.',
  );
  String get readerChangeLanguageHint => _t(
    'Maaari mong palitan ang wika ng app sa Settings para mabasa ito sa English.',
    'You can change the app language in Settings to read it in English.',
  );
  String get readerQuiz => _t('Sagutan ang Quiz', 'Take the quiz');
  String get readerAlreadyRead =>
      _t('Nabasa mo na ito', 'You have already read this');
  String get previousChapter => _t('Naunang kabanata', 'Previous chapter');
  String get nextChapter => _t('Susunod na kabanata', 'Next chapter');
  String get textSources => _t('Mga Pinagmulan ng Teksto', 'Text sources');
  String get webSourceTitle => _t(
    'World English Bible — Katolikong edisyon',
    'World English Bible — Catholic edition',
  );
  String get webSourceBody => _t(
    'Walang copyright, malayang gamitin. Mula sa eBible.org (eng-web-c), kasama ang pitong deuterocanonical na aklat at ang mga dagdag sa Ester at Daniel.',
    'Public domain. From eBible.org (eng-web-c), including the seven deuterocanonical books and the additions to Esther and Daniel.',
  );
  String get tagalogSourceBody => _t(
    'Ang Dating Biblia (1905), Walang copyright, malayang gamitin. Mula sa CrossWire SWORD TagAngBiblia 1.2, na isinulat sa digital na anyo nina Richard at Dolores Long. Ang JSON export ng getBible ay itinugma sa orihinal na module.',
    'Ang Dating Biblia (1905), public domain. From CrossWire SWORD TagAngBiblia 1.2, digitized by Richard and Dolores Long. The getBible JSON export was checked against the original module.',
  );
  String get webTrademarkNote => _t(
    'Ang “World English Bible” ay trademark ng eBible.org. Ang mga salita ng pinagmulan ay pinanatili; inalis ang mga tala at format, at inayos ang bilang ng mga kabanata at talata para sa app.',
    '“World English Bible” is a trademark of eBible.org. Source wording is preserved; notes and formatting are removed, and chapters and verses are arranged for the app.',
  );
  String get sourcesEnglishNote => _t(
    'Wala pang Tagalog na teksto ang pitong deuterocanonical na aklat, Ester 10–16, at Daniel 3, 13 at 14. Palitan ang wika ng app sa Settings para mabasa ang mga ito sa English (WEB). May ilang teksto sa Ester na inihahanda pa; maaari pa ring sagutan ang quiz.',
    'Tagalog text is unavailable for the seven deuterocanonical books, Esther 10–16, and Daniel 3, 13 and 14. Change the app language in Settings to read them in English (WEB). Some Esther text is still being prepared; its quiz remains available.',
  );
  String readerCredit(bool web) => web
      ? 'World English Bible (Catholic) - eBible.org'
      : 'Ang Dating Biblia (1905) - CrossWire';
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
  String get introTitle => _t('Magbasa sa iyong paraan', 'Read your way');
  String get introBody => _t(
    'Pumili ng kabanata at basahin ang naka-save na teksto sa app, o gamitin ang sarili mong Bibliya. Kapag handa ka na, sagutan ang quiz para markahan ang nabasa. Hindi nagbabago ang progress sa pagbabasa lamang.',
    'Choose a chapter and read the offline text in the app, or use your own Bible. When you feel ready, take the quiz to mark it as read. Reading alone does not change your progress.',
  );
  String get introStep1 => _t('Pumili ng kabanata', 'Choose a chapter');
  String get introStep2 => _t('Magbasa ng kabanata', 'Read a chapter');
  String get introStep3 =>
      _t('Markahan dito ang natapos mo', 'Mark it as read here');
  String get introStartReading => _t('Simulan ang pagbabasa', 'Start reading');
  String get introGotIt => _t('Sige', 'Got it');

  // ---- how-to button (books screen) ----
  String get howToUse => _t('Paano gamitin', 'How to use');

  // ---- profile ----
  String rankTierName(RankTier tier) => _t(tier.nameFil, tier.nameEn);
  String rankDivision(RankDivision division) => switch (division) {
    RankDivision.v => _t('V', 'V'),
    RankDivision.iv => _t('IV', 'IV'),
    RankDivision.iii => _t('III', 'III'),
    RankDivision.ii => _t('II', 'II'),
    RankDivision.i => _t('I', 'I'),
  };
  String rankName(RankInfo rank) => rank.division == null
      ? rankTierName(rank.tier)
      : '${rankTierName(rank.tier)} ${rankDivision(rank.division!)}';
  String get currentRank => _t('Kasalukuyang Rank', 'Current Rank');
  String get highestRank => _t('Pinakamataas na Rank', 'Highest Rank');
  String rankStars(int stars) =>
      _t('$stars bituin', stars == 1 ? '1 star' : '$stars stars');
  String get rankUpTitle => _t('Bagong rank!', 'New rank!');
  String get rankUpMessage => _t(
    'Bawat kabanata ay isang hakbang. Magandang pagbabasa!',
    'Each chapter is a step forward. Happy reading!',
  );
  String get rankUpContinue => _t('Sige!', 'Lovely!');

  String get defaultUsername => _t('Mambabasa', 'Reader');
  String get viewProfile => _t('Tingnan ang Profile', 'View profile');
  String get publicProfileLoading =>
      _t('Naglo-load ng profile...', 'Loading profile...');
  String get publicProfileUnavailable => _t(
    'Hindi available ang profile na ito.',
    'This profile is not available.',
  );
  String get publicProfileOffline => _t(
    'Hindi ma-load ang profile. Kumonekta sa internet at subukan ulit.',
    'Could not load this profile. Connect to the internet and try again.',
  );
  String profileLastUpdated(DateTime? updatedAt, {DateTime? now}) {
    final prefix = _t('Huling update', 'Last updated');
    if (updatedAt == null) return '$prefix: ${_t('hindi alam', 'unknown')}';
    final elapsed = (now ?? DateTime.now()).difference(updatedAt);
    if (elapsed.inMinutes < 1) {
      return '$prefix: ${_t('ngayon lang', 'just now')}';
    }
    if (elapsed.inHours < 1) {
      final n = elapsed.inMinutes;
      return '$prefix: ${_t('$n minuto ang nakalipas', '$n minute${n == 1 ? '' : 's'} ago')}';
    }
    if (elapsed.inDays < 1) {
      final n = elapsed.inHours;
      return '$prefix: ${_t('$n oras ang nakalipas', '$n hour${n == 1 ? '' : 's'} ago')}';
    }
    final n = elapsed.inDays;
    return '$prefix: ${_t('$n araw ang nakalipas', '$n day${n == 1 ? '' : 's'} ago')}';
  }

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
  String get publicProfilePrivacyNotice => _t(
    'Makikita ng ibang user ang iyong pangalan, rank, at bilang ng nabasa.',
    'Your name, rank, and reading counts will be visible to other users.',
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
  String leaderboardRankLabel(int rank) => _t('Ranggo #$rank', 'Rank #$rank');
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
  String get finishersOffline =>
      _t('Hindi available offline.', 'Not available offline.');
  String get finishersEmpty => _t(
    'Wala pang nakatapos ng librong ito.',
    'No one has finished this book yet.',
  );
  String get finishersYou => _t('Ikaw', 'You');
  String get finishersShowAll => _t('Tingnan lahat', 'See all');

  // ---- star change screen ----
  String get starGainTitle =>
      _t('Nakakuha ka ng bituin!', 'You earned a star!');
  String get starLossTitle => _t('Nabawasan ng 1 star', 'You lost 1 star');
  String starRankUp(String rankName) =>
      _t('Umakyat ka sa $rankName!', 'You ranked up to $rankName!');
  String starRankDown(String rankName) =>
      _t('Bumaba ka sa $rankName', 'You moved down to $rankName');
  String starHighestStill(String rankName) => _t(
    'Pinakamataas na Rank mo pa rin: $rankName',
    'Your highest rank is still: $rankName',
  );
  String get starTapToContinue =>
      _t('Pindutin para magpatuloy', 'Tap to continue');
  String get starPlusOne => '+1 ★';
  String get starMinusOne => '-1 ★';

  // ---- un-mark confirmation ----
  String get unmarkTitle => _t('Alisin ang marka?', 'Remove mark?');
  String get unmarkBody => _t(
    'Aalisin ito sa nabasa. Mababawasan ka ng 1 star at kailangan mong sagutan ulit ang quiz para maibalik ito. Ituloy?',
    'This will be removed from your read chapters. You will lose 1 star and need to retake the quiz to get it back. Continue?',
  );
  String get unmarkConfirm => _t('Ituloy', 'Confirm');

  // ---- quiz ----
  String quizTitle(int chapter) =>
      _t('Kabanata $chapter — Quiz', 'Chapter $chapter — Quiz');
  String quizProgress(int current, int total) =>
      _t('$current / $total', '$current / $total');
  String get quizChooseAnswer => _t('Pumili ng sagot', 'Choose an answer');
  String get quizCheckAnswers => _t('Suriin ang mga sagot', 'Check answers');
  String get quizWrong => _t(
    'Konti na lang! Basahin ulit ang chapter at subukan ulit.',
    'Almost there! Re-read the chapter and try again.',
  );
  String get quizRetry => _t('Subukan ulit', 'Try again');
  String get quizPassed => _t(
    '🎉 Magaling! Natapos mo ang quiz!',
    '🎉 Well done! You passed the quiz!',
  );
  String get quizLearnedTitle => _t('Natutunan mo', 'What you learned');
  String get quizMarkRead => _t('Markahan bilang nabasa', 'Mark as read');
  String get quizNoQuestions =>
      _t('Walang quiz para sa kabanatang ito.', 'No quiz for this chapter.');
}
