import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bible versions enabled for our YouVersion app key.
class BibleVersionOption {
  const BibleVersionOption(this.id, this.abbreviation, this.title);
  final int id;
  final String abbreviation;
  final String title;
}

// Versions enabled and license-accepted for our YouVersion app key, popular
// modern translations first. (KJV is not licensed to this key.)
const kBibleVersions = <BibleVersionOption>[
  BibleVersionOption(111, 'NIV', 'New International Version'),
  BibleVersionOption(2692, 'NASB', 'New American Standard Bible (2020)'),
  BibleVersionOption(1588, 'AMP', 'Amplified Bible'),
  BibleVersionOption(3034, 'BSB', 'Berean Standard Bible'),
  BibleVersionOption(2079, 'EASY', 'EasyEnglish Bible'),
  BibleVersionOption(110, 'NIrV', 'New International Reader’s Version'),
  BibleVersionOption(113, 'NIVUK', 'New International Version (UK)'),
  BibleVersionOption(12, 'ASV', 'American Standard Version'),
  BibleVersionOption(2660, 'LSV', 'Literal Standard Version'),
  BibleVersionOption(2163, 'GNV', 'Geneva Bible'),
  BibleVersionOption(42, 'CPDV', 'Catholic Public Domain'),
];

BibleVersionOption versionById(int id) =>
    kBibleVersions.firstWhere((v) => v.id == id,
        orElse: () => kBibleVersions.first);

/// The member's chosen Bible version, persisted and observable so the Bible
/// screens react when it changes.
class BiblePrefs {
  BiblePrefs._();
  static final BiblePrefs instance = BiblePrefs._();

  static const _key = 'bible_version_id';
  static const _default = 111; // NIV

  final ValueNotifier<int> versionId = ValueNotifier<int>(_default);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      versionId.value = prefs.getInt(_key) ?? _default;
    } catch (_) {}
  }

  Future<void> setVersion(int id) async {
    versionId.value = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, id);
    } catch (_) {}
  }
}
