enum Testament { ot, nt }

/// The three groups shown in the book list.
enum Section { oldTestament, deuterocanonical, newTestament }

class Book {
  const Book(
    this.id,
    this.nameEn,
    this.nameFil,
    this.testament,
    this.totalChapters, {
    this.isDeutero = false,
  });

  final String id;
  final String nameEn;
  final String nameFil;
  final Testament testament;
  final int totalChapters;
  final bool isDeutero;

  Section get section {
    if (isDeutero) return Section.deuterocanonical;
    return testament == Testament.ot
        ? Section.oldTestament
        : Section.newTestament;
  }

  /// [lang] is 'fil' or 'en'.
  String nameFor(String lang) => lang == 'fil' ? nameFil : nameEn;
}
