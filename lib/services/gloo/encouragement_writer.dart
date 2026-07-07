import 'gloo_client.dart';

/// Drafts short, Scripture-grounded encouragement for prayer requests and
/// testimonies. The member must still send it manually.
class EncouragementWriter {
  EncouragementWriter({GlooClient? client}) : _gloo = client ?? GlooClient();

  final GlooClient _gloo;

  bool get isAvailable => _gloo.isConfigured;

  Future<String> draft({
    required String postBody,
    required bool testimony,
  }) async {
    final system = testimony
        ? 'You write brief Christian encouragement in response to testimonies. '
              'Celebrate what God has done, stay warm and humble, include one '
              'short Scripture reference if natural, and do not overclaim. '
              'Never use em-dashes.'
        : 'You write brief Christian encouragement in response to prayer '
              'requests. Be pastoral, gentle, Scripture-grounded, and concise. '
              'Do not promise outcomes. Offer prayerful presence. Never use '
              'em-dashes.';

    return _gloo.chat(
      temperature: 0.7,
      maxTokens: 180,
      messages: [
        GlooMessage.system(system),
        GlooMessage.user(
          'Write one response under 70 words. No heading.\n\n$postBody',
        ),
      ],
    );
  }

  void close() => _gloo.close();
}
