/// A passage of Scripture as returned by the YouVersion Platform API.
class Passage {
  const Passage({
    required this.id,
    required this.reference,
    required this.text,
  });

  /// e.g. "JHN.3.16"
  final String id;

  /// Localized human reference, e.g. "John 3:16"
  final String reference;

  /// Plain text (we request format=text so there's no HTML to strip).
  final String text;

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      id: (json['id'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      text: _clean((json['content'] ?? '').toString()),
    );
  }

  static String _clean(String raw) =>
      raw.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// A single numbered verse within a chapter.
class Verse {
  const Verse({required this.number, required this.text});
  final int number;
  final String text;
}

/// A chapter parsed into numbered verses.
class Chapter {
  const Chapter({required this.reference, required this.verses});
  final String reference;
  final List<Verse> verses;
}

/// The verse-of-the-day pointer: which passage YouVersion curated for a day.
class VerseOfDayRef {
  const VerseOfDayRef({required this.day, required this.passageId});
  final int day;
  final String passageId;

  factory VerseOfDayRef.fromJson(Map<String, dynamic> json) => VerseOfDayRef(
        day: (json['day'] as num?)?.toInt() ?? 0,
        passageId: (json['passage_id'] ?? '').toString(),
      );
}

/// A Bible version available to this app key.
class BibleVersion {
  const BibleVersion({
    required this.id,
    required this.abbreviation,
    required this.title,
  });
  final int id;
  final String abbreviation;
  final String title;

  factory BibleVersion.fromJson(Map<String, dynamic> json) => BibleVersion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        abbreviation: (json['abbreviation'] ?? '').toString(),
        title: (json['title'] ?? json['local_title'] ?? '').toString(),
      );
}
