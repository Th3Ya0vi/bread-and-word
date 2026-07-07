import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'youversion_models.dart';

/// On-device cache for Bible chapters. Scripture text doesn't change, so we
/// store each fetched chapter and only re-fetch from YouVersion once it's
/// older than [_ttl] (about a month) — saving API calls and working offline.
class BibleCache {
  BibleCache._();

  static const _ttl = Duration(days: 30);

  static String _key(int bibleId, String ref) => 'bible_${bibleId}_$ref';

  static Future<Chapter?> get(int bibleId, String ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(bibleId, ref));
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt =
          DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt());
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final verses = (j['v'] as List)
          .map((e) => Verse(
                number: (e['n'] as num).toInt(),
                text: (e['t'] ?? '').toString(),
              ))
          .toList();
      return Chapter(reference: (j['ref'] ?? '').toString(), verses: verses);
    } catch (_) {
      return null;
    }
  }

  static Future<void> put(int bibleId, String ref, Chapter c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final j = {
        'ref': c.reference,
        'at': DateTime.now().millisecondsSinceEpoch,
        'v': c.verses.map((v) => {'n': v.number, 't': v.text}).toList(),
      };
      await prefs.setString(_key(bibleId, ref), jsonEncode(j));
    } catch (_) {}
  }
}
