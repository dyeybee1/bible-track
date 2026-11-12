import 'books_data.dart';

enum BibleTranslation { tl1905, web }

enum BibleTextAvailability { available, unavailable, pending }

BibleTranslation translationForLanguage(String language) =>
    language == 'fil' ? BibleTranslation.tl1905 : BibleTranslation.web;

/// Availability is for a whole APP chapter in the requested language.
BibleTextAvailability chapterTextAvailability(
  String bookId,
  int chapter,
  BibleTranslation translation,
) {
  final book = bookById(bookId);
  if (chapter < 1 || chapter > book.totalChapters) {
    throw RangeError.range(chapter, 1, book.totalChapters, 'chapter');
  }
  if (translation == BibleTranslation.web) {
    return bookId == 'est' && const {5, 15}.contains(chapter)
        ? BibleTextAvailability.pending
        : BibleTextAvailability.available;
  }
  if (book.isDeutero ||
      (bookId == 'est' && chapter >= 10) ||
      (bookId == 'dan' && const {3, 13, 14}.contains(chapter))) {
    return BibleTextAvailability.unavailable;
  }
  return BibleTextAvailability.available;
}

List<BibleTranslation> availableTranslations(String bookId, int chapter) => [
  for (final translation in BibleTranslation.values)
    if (chapterTextAvailability(bookId, chapter, translation) ==
        BibleTextAvailability.available)
      translation,
];
