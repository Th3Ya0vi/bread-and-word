import 'gloo_client.dart';

/// Turns a passage into a short, warm devotional reflection using Gloo's
/// faith-tuned models. Kept deliberately brief and pastoral.
class DevotionalWriter {
  DevotionalWriter({GlooClient? client}) : _gloo = client ?? GlooClient();

  final GlooClient _gloo;

  bool get isAvailable => _gloo.isConfigured;

  static const _system =
      'You are a gentle, orthodox Christian devotional writer for an app called '
      'Bread & Word. Write a short reflection (90–130 words) on the given verse: '
      'warm, pastoral, scripturally grounded, and encouraging. No headings, no '
      'lists, no preamble — just the reflection itself in plain prose.';

  /// Returns (title, body). Title is a short 2–4 word phrase.
  Future<({String title, String body})> reflect({
    required String reference,
    required String verseText,
  }) async {
    final body = await _gloo.chat(
      temperature: 0.8,
      maxTokens: 400,
      messages: [
        const GlooMessage.system(_system),
        GlooMessage.user('$reference\n\n"$verseText"\n\n'
            'Write the reflection. On the first line, give a 2–4 word title, '
            'then a blank line, then the reflection.'),
      ],
    );
    return _split(body);
  }

  ({String title, String body}) _split(String raw) {
    final parts = raw.split(RegExp(r'\n\s*\n'));
    if (parts.length >= 2) {
      return (title: parts.first.trim(), body: parts.sublist(1).join('\n\n').trim());
    }
    return (title: 'A Word for Today', body: raw.trim());
  }

  void close() => _gloo.close();
}
