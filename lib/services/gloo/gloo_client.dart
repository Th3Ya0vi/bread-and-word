import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/secrets.dart';

/// Client for Gloo AI Studio — faith-tuned, OpenAI-compatible inference.
/// Used to generate devotional reflections (and, later, a safe ministry-context
/// chat assistant).
///
/// Auth is OAuth2 client-credentials: we exchange a client id/secret for a
/// short-lived bearer token, cache it, and send it on chat requests.
///
/// Credentials are injected at build time and are gitignored:
///   flutter run --dart-define-from-file=dart_defines.local.json
///
/// NOTE: Gloo's docs don't publish the exact token URL; [tokenUrl] defaults to
/// the conventional path and can be overridden via GLOO_TOKEN_URL once verified.
class GlooClient {
  GlooClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _chatUrl = 'https://platform.ai.gloo.com/ai/v2/chat/completions';

  static const clientId = String.fromEnvironment(
    'GLOO_CLIENT_ID',
    defaultValue: Secrets.glooClientId,
  );
  static const clientSecret = String.fromEnvironment(
    'GLOO_CLIENT_SECRET',
    defaultValue: Secrets.glooClientSecret,
  );
  static const tokenUrl = String.fromEnvironment(
    'GLOO_TOKEN_URL',
    defaultValue: 'https://platform.ai.gloo.com/oauth2/token',
  );

  /// Faith-tuned routing to the latest Claude Sonnet via Gloo.
  static const defaultModel = 'gloo-anthropic-claude-sonnet-4.6';

  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  String? _token;
  DateTime _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  Future<String> _accessToken() async {
    if (_token != null && DateTime.now().isBefore(_tokenExpiry)) {
      return _token!;
    }
    final basic = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final res = await _http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic $basic',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials', 'scope': 'api/access'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw GlooException('Token request failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final token = json['access_token'] as String?;
    if (token == null) throw const GlooException('No access_token in response');
    final ttl = (json['expires_in'] as num?)?.toInt() ?? 3600;
    _token = token;
    // Refresh a minute early to avoid edge-of-expiry failures.
    _tokenExpiry = DateTime.now().add(Duration(seconds: ttl - 60));
    return token;
  }

  /// OpenAI-compatible chat completion. Returns the assistant's text.
  Future<String> chat({
    required List<GlooMessage> messages,
    String model = defaultModel,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    if (!isConfigured) {
      throw const GlooException(
        'Gloo not configured. Set GLOO_CLIENT_ID/GLOO_CLIENT_SECRET in '
        'dart_defines.local.json.',
      );
    }
    final token = await _accessToken();
    final res = await _http.post(
      Uri.parse(_chatUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': false,
        'messages': messages.map((m) => m.toJson()).toList(),
      }),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw GlooException('Chat request failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const GlooException('No choices in response');
    final msg = (choices.first as Map)['message'] as Map?;
    return (msg?['content'] ?? '').toString().trim();
  }

  void close() => _http.close();
}

class GlooMessage {
  const GlooMessage(this.role, this.content);
  const GlooMessage.system(this.content) : role = 'system';
  const GlooMessage.user(this.content) : role = 'user';

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class GlooException implements Exception {
  const GlooException(this.message);
  final String message;
  @override
  String toString() => 'GlooException: $message';
}
