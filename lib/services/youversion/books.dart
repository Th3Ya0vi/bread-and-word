/// The 66-book Protestant canon with YouVersion USFM codes and chapter counts.
class BibleBook {
  const BibleBook(this.name, this.usfm, this.chapters, this.oldTestament);
  final String name;
  final String usfm;
  final int chapters;
  final bool oldTestament;
}

const kBibleBooks = <BibleBook>[
  // ── Old Testament ──
  BibleBook('Genesis', 'GEN', 50, true),
  BibleBook('Exodus', 'EXO', 40, true),
  BibleBook('Leviticus', 'LEV', 27, true),
  BibleBook('Numbers', 'NUM', 36, true),
  BibleBook('Deuteronomy', 'DEU', 34, true),
  BibleBook('Joshua', 'JOS', 24, true),
  BibleBook('Judges', 'JDG', 21, true),
  BibleBook('Ruth', 'RUT', 4, true),
  BibleBook('1 Samuel', '1SA', 31, true),
  BibleBook('2 Samuel', '2SA', 24, true),
  BibleBook('1 Kings', '1KI', 22, true),
  BibleBook('2 Kings', '2KI', 25, true),
  BibleBook('1 Chronicles', '1CH', 29, true),
  BibleBook('2 Chronicles', '2CH', 36, true),
  BibleBook('Ezra', 'EZR', 10, true),
  BibleBook('Nehemiah', 'NEH', 13, true),
  BibleBook('Esther', 'EST', 10, true),
  BibleBook('Job', 'JOB', 42, true),
  BibleBook('Psalms', 'PSA', 150, true),
  BibleBook('Proverbs', 'PRO', 31, true),
  BibleBook('Ecclesiastes', 'ECC', 12, true),
  BibleBook('Song of Solomon', 'SNG', 8, true),
  BibleBook('Isaiah', 'ISA', 66, true),
  BibleBook('Jeremiah', 'JER', 52, true),
  BibleBook('Lamentations', 'LAM', 5, true),
  BibleBook('Ezekiel', 'EZK', 48, true),
  BibleBook('Daniel', 'DAN', 12, true),
  BibleBook('Hosea', 'HOS', 14, true),
  BibleBook('Joel', 'JOL', 3, true),
  BibleBook('Amos', 'AMO', 9, true),
  BibleBook('Obadiah', 'OBA', 1, true),
  BibleBook('Jonah', 'JON', 4, true),
  BibleBook('Micah', 'MIC', 7, true),
  BibleBook('Nahum', 'NAM', 3, true),
  BibleBook('Habakkuk', 'HAB', 3, true),
  BibleBook('Zephaniah', 'ZEP', 3, true),
  BibleBook('Haggai', 'HAG', 2, true),
  BibleBook('Zechariah', 'ZEC', 14, true),
  BibleBook('Malachi', 'MAL', 4, true),
  // ── New Testament ──
  BibleBook('Matthew', 'MAT', 28, false),
  BibleBook('Mark', 'MRK', 16, false),
  BibleBook('Luke', 'LUK', 24, false),
  BibleBook('John', 'JHN', 21, false),
  BibleBook('Acts', 'ACT', 28, false),
  BibleBook('Romans', 'ROM', 16, false),
  BibleBook('1 Corinthians', '1CO', 16, false),
  BibleBook('2 Corinthians', '2CO', 13, false),
  BibleBook('Galatians', 'GAL', 6, false),
  BibleBook('Ephesians', 'EPH', 6, false),
  BibleBook('Philippians', 'PHP', 4, false),
  BibleBook('Colossians', 'COL', 4, false),
  BibleBook('1 Thessalonians', '1TH', 5, false),
  BibleBook('2 Thessalonians', '2TH', 3, false),
  BibleBook('1 Timothy', '1TI', 6, false),
  BibleBook('2 Timothy', '2TI', 4, false),
  BibleBook('Titus', 'TIT', 3, false),
  BibleBook('Philemon', 'PHM', 1, false),
  BibleBook('Hebrews', 'HEB', 13, false),
  BibleBook('James', 'JAS', 5, false),
  BibleBook('1 Peter', '1PE', 5, false),
  BibleBook('2 Peter', '2PE', 3, false),
  BibleBook('1 John', '1JN', 5, false),
  BibleBook('2 John', '2JN', 1, false),
  BibleBook('3 John', '3JN', 1, false),
  BibleBook('Jude', 'JUD', 1, false),
  BibleBook('Revelation', 'REV', 22, false),
];

List<BibleBook> get oldTestamentBooks =>
    kBibleBooks.where((b) => b.oldTestament).toList();
List<BibleBook> get newTestamentBooks =>
    kBibleBooks.where((b) => !b.oldTestament).toList();
