import 'books_data.dart';

enum BibleTranslation { tl1905, web }

/// Availability is for a whole APP chapter; languages are never mixed.
List<BibleTranslation> availableTranslations(String bookId, int chapter) {
  final book = bookById(bookId);
  if (chapter < 1 || chapter > book.totalChapters) {
    throw RangeError.range(chapter, 1, book.totalChapters, 'chapter');
  }
  if (book.isDeutero ||
      (bookId == 'est' && chapter >= 10) ||
      (bookId == 'dan' && const {3, 13, 14}.contains(chapter))) {
    return const [BibleTranslation.web];
  }
  return const [BibleTranslation.tl1905, BibleTranslation.web];
}

BibleTranslation translationForChapter(
  String bookId,
  int chapter,
  BibleTranslation preferred,
) => availableTranslations(bookId, chapter).contains(preferred)
    ? preferred
    : BibleTranslation.web;
