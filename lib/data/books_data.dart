import '../models/book.dart';

/// The 73-book Catholic canon, in Catholic order.
/// Chapter counts follow the Catholic (Vulgate-based) numbering. Check them
/// against the Filipino Bible edition you choose as your reference, because a
/// few books (Joel, Malachi, Esther, Daniel) differ between editions.
const List<Book> allBooks = [
  // ---- Old Testament (46, including the 7 deuterocanonical books) ----
  Book('gen', 'Genesis', 'Genesis', Testament.ot, 50),
  Book('exo', 'Exodus', 'Exodo', Testament.ot, 40),
  Book('lev', 'Leviticus', 'Levitico', Testament.ot, 27),
  Book('num', 'Numbers', 'Mga Bilang', Testament.ot, 36),
  Book('deu', 'Deuteronomy', 'Deuteronomio', Testament.ot, 34),
  Book('jos', 'Joshua', 'Josue', Testament.ot, 24),
  Book('jdg', 'Judges', 'Mga Hukom', Testament.ot, 21),
  Book('rut', 'Ruth', 'Ruth', Testament.ot, 4),
  Book('1sa', '1 Samuel', '1 Samuel', Testament.ot, 31),
  Book('2sa', '2 Samuel', '2 Samuel', Testament.ot, 24),
  Book('1ki', '1 Kings', '1 Hari', Testament.ot, 22),
  Book('2ki', '2 Kings', '2 Hari', Testament.ot, 25),
  Book('1ch', '1 Chronicles', '1 Cronica', Testament.ot, 29),
  Book('2ch', '2 Chronicles', '2 Cronica', Testament.ot, 36),
  Book('ezr', 'Ezra', 'Ezra', Testament.ot, 10),
  Book('neh', 'Nehemiah', 'Nehemias', Testament.ot, 13),
  Book('tob', 'Tobit', 'Tobit', Testament.ot, 14, isDeutero: true),
  Book('jdt', 'Judith', 'Judith', Testament.ot, 16, isDeutero: true),
  Book('est', 'Esther', 'Ester', Testament.ot, 16),
  Book('1ma', '1 Maccabees', '1 Macabeo', Testament.ot, 16, isDeutero: true),
  Book('2ma', '2 Maccabees', '2 Macabeo', Testament.ot, 15, isDeutero: true),
  Book('job', 'Job', 'Job', Testament.ot, 42),
  Book('psa', 'Psalms', 'Mga Awit', Testament.ot, 150),
  Book('pro', 'Proverbs', 'Mga Kawikaan', Testament.ot, 31),
  Book('ecc', 'Ecclesiastes', 'Eclesiastes', Testament.ot, 12),
  Book('sng', 'Song of Songs', 'Awit ng mga Awit', Testament.ot, 8),
  Book('wis', 'Wisdom', 'Karunungan', Testament.ot, 19, isDeutero: true),
  Book('sir', 'Sirach', 'Sirak', Testament.ot, 51, isDeutero: true),
  Book('isa', 'Isaiah', 'Isaias', Testament.ot, 66),
  Book('jer', 'Jeremiah', 'Jeremias', Testament.ot, 52),
  Book('lam', 'Lamentations', 'Panaghoy', Testament.ot, 5),
  Book('bar', 'Baruch', 'Baruc', Testament.ot, 6, isDeutero: true),
  Book('eze', 'Ezekiel', 'Ezekiel', Testament.ot, 48),
  Book('dan', 'Daniel', 'Daniel', Testament.ot, 14),
  Book('hos', 'Hosea', 'Oseas', Testament.ot, 14),
  Book('joe', 'Joel', 'Joel', Testament.ot, 4),
  Book('amo', 'Amos', 'Amos', Testament.ot, 9),
  Book('oba', 'Obadiah', 'Obadias', Testament.ot, 1),
  Book('jon', 'Jonah', 'Jonas', Testament.ot, 4),
  Book('mic', 'Micah', 'Mikas', Testament.ot, 7),
  Book('nah', 'Nahum', 'Nahum', Testament.ot, 3),
  Book('hab', 'Habakkuk', 'Habakuk', Testament.ot, 3),
  Book('zep', 'Zephaniah', 'Zefanias', Testament.ot, 3),
  Book('hag', 'Haggai', 'Hagai', Testament.ot, 2),
  Book('zec', 'Zechariah', 'Zacarias', Testament.ot, 14),
  Book('mal', 'Malachi', 'Malakias', Testament.ot, 3),

  // ---- New Testament (27) ----
  Book('mat', 'Matthew', 'Mateo', Testament.nt, 28),
  Book('mrk', 'Mark', 'Marcos', Testament.nt, 16),
  Book('luk', 'Luke', 'Lucas', Testament.nt, 24),
  Book('jhn', 'John', 'Juan', Testament.nt, 21),
  Book('act', 'Acts', 'Mga Gawa', Testament.nt, 28),
  Book('rom', 'Romans', 'Roma', Testament.nt, 16),
  Book('1co', '1 Corinthians', '1 Corinto', Testament.nt, 16),
  Book('2co', '2 Corinthians', '2 Corinto', Testament.nt, 13),
  Book('gal', 'Galatians', 'Galacia', Testament.nt, 6),
  Book('eph', 'Ephesians', 'Efeso', Testament.nt, 6),
  Book('php', 'Philippians', 'Filipos', Testament.nt, 4),
  Book('col', 'Colossians', 'Colosas', Testament.nt, 4),
  Book('1th', '1 Thessalonians', '1 Tesalonica', Testament.nt, 5),
  Book('2th', '2 Thessalonians', '2 Tesalonica', Testament.nt, 3),
  Book('1ti', '1 Timothy', '1 Timoteo', Testament.nt, 6),
  Book('2ti', '2 Timothy', '2 Timoteo', Testament.nt, 4),
  Book('tit', 'Titus', 'Tito', Testament.nt, 3),
  Book('phm', 'Philemon', 'Filemon', Testament.nt, 1),
  Book('heb', 'Hebrews', 'Hebreo', Testament.nt, 13),
  Book('jas', 'James', 'Santiago', Testament.nt, 5),
  Book('1pe', '1 Peter', '1 Pedro', Testament.nt, 5),
  Book('2pe', '2 Peter', '2 Pedro', Testament.nt, 3),
  Book('1jn', '1 John', '1 Juan', Testament.nt, 5),
  Book('2jn', '2 John', '2 Juan', Testament.nt, 1),
  Book('3jn', '3 John', '3 Juan', Testament.nt, 1),
  Book('jud', 'Jude', 'Judas', Testament.nt, 1),
  Book('rev', 'Revelation', 'Apocalipsis', Testament.nt, 22),
];

final Map<String, Book> _booksById = {for (final b in allBooks) b.id: b};

Book bookById(String id) => _booksById[id]!;

final Map<Section, List<Book>> booksBySection = {
  for (final s in Section.values)
    s: allBooks.where((b) => b.section == s).toList(growable: false),
};

/// Number of chapters in the whole canon (used for the overall progress).
final int totalChaptersInBible = allBooks.fold<int>(
  0,
  (sum, b) => sum + b.totalChapters,
);
