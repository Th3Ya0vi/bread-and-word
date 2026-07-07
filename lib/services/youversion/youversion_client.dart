import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/secrets.dart';
import '../reading_progress.dart';
import 'youversion_models.dart';

/// Thin client for the YouVersion Platform REST API.
///
/// Auth is via the `X-YVP-App-Key` header. The key is injected at build time
/// with `--dart-define-from-file=dart_defines.local.json` (which is gitignored),
/// so it never lives in source or version control.
///
///   flutter run --dart-define-from-file=dart_defines.local.json
class YouVersionClient {
  YouVersionClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _base = 'https://api.youversion.com/v1';

  /// Injected at build time, falling back to the baked-in test key.
  static const appKey = String.fromEnvironment(
    'YOUVERSION_APP_KEY',
    defaultValue: Secrets.youVersionKey,
  );

  /// NIV (New International Version) — the default, now licensed for our app
  /// key. Other enabled versions (NASB 2692, AMP 1588, BSB 3034, EASY 2079,
  /// NIrV 110, ASV 12, LSV 2660, …) are listed in `versions.dart`.
  static const defaultBibleId = 111;

  bool get isConfigured => appKey.isNotEmpty;

  Map<String, String> get _headers => {
    'X-YVP-App-Key': appKey,
    'Accept': 'application/json',
  };

  /// Today's verse of the day, resolved to actual passage text.
  /// [bibleId] selects the version; [day] defaults to today's day-of-year.
  Future<Passage> verseOfDay({int? bibleId, int? day}) async {
    final d = day ?? ReadingProgress.easternDayOfYear();
    final ref = await _verseOfDayRef(d);
    return passage(ref.passageId, bibleId: bibleId);
  }

  Future<VerseOfDayRef> _verseOfDayRef(int day) async {
    final uri = Uri.parse('$_base/verse_of_the_days/$day');
    final json = await _getJson(uri);
    return VerseOfDayRef.fromJson(json);
  }

  /// Fetch plain-text Scripture for a reference like "JHN.3.16" or "PSA.23".
  Future<Passage> passage(String reference, {int? bibleId}) async {
    final id = bibleId ?? defaultBibleId;
    final uri = Uri.parse(
      '$_base/bibles/$id/passages/$reference',
    ).replace(queryParameters: {'format': 'text'});
    final json = await _getJson(uri);
    return Passage.fromJson(json);
  }

  /// Fetch a chapter parsed into numbered verses (uses the HTML format, which
  /// carries verse markers, then splits it into verses).
  Future<Chapter> chapterVerses(String reference, {int? bibleId}) async {
    final id = bibleId ?? defaultBibleId;
    final uri = Uri.parse(
      '$_base/bibles/$id/passages/$reference',
    ).replace(queryParameters: {'format': 'html'});
    final json = await _getJson(uri);
    final reference0 = (json['reference'] ?? '').toString();
    final html = (json['content'] ?? '').toString();
    return Chapter(reference: reference0, verses: _parseVerses(html));
  }

  /// YouVersion HTML marks each verse with `<span class="yv-v" v="N">`.
  /// We split on those markers and clean the text in between.
  static List<Verse> _parseVerses(String html) {
    final marker = RegExp(r'<span class="yv-v" v="(\d+)"></span>');
    final matches = marker.allMatches(html).toList();
    if (matches.isEmpty) {
      final text = _stripHtml(html);
      return text.isEmpty ? const [] : [Verse(number: 1, text: text)];
    }
    final verses = <Verse>[];
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final number = int.tryParse(m.group(1) ?? '') ?? (i + 1);
      final end = i + 1 < matches.length ? matches[i + 1].start : html.length;
      var segment = html.substring(m.end, end);
      // Drop the visible verse label span; strip remaining tags.
      segment = segment.replaceAll(
        RegExp(r'<span class="yv-vlbl">.*?</span>'),
        '',
      );
      final text = _stripHtml(segment);
      if (text.isNotEmpty) verses.add(Verse(number: number, text: text));
    }
    return verses;
  }

  static String _stripHtml(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', '’')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Bible versions enabled for this app key. `language_ranges[]` is required
  /// (ISO 639-3, e.g. "eng") or the API returns 422.
  Future<List<BibleVersion>> listVersions({String language = 'eng'}) async {
    final uri = Uri.parse(
      '$_base/bibles',
    ).replace(queryParameters: {'language_ranges[]': language});
    final json = await _getJson(uri);
    final data = (json['data'] ?? json['bibles'] ?? []) as List<dynamic>;
    return data
        .map((e) => BibleVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    if (!isConfigured) {
      throw const YouVersionException(
        'No app key. Run with --dart-define-from-file=dart_defines.local.json',
      );
    }
    final res = await _http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw YouVersionException(
      'GET ${uri.path} failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  void close() => _http.close();
}

class YouVersionException implements Exception {
  const YouVersionException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'YouVersionException: $message';
}
