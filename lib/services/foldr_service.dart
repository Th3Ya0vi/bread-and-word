import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/secrets.dart';

/// Uploads files to foldr.space and returns a permanent link.
/// Used to store recordings of live rooms (the host's session).
///
/// The key is injected via --dart-define (FOLDR_API_KEY) and gitignored.
class FoldrService {
  FoldrService._();
  static final FoldrService instance = FoldrService._();

  static const _endpoint = 'https://foldr.space/api/v1/files';
  static const _apiKey = String.fromEnvironment(
    'FOLDR_API_KEY',
    defaultValue: Secrets.foldrApiKey,
  );

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Uploads a local file; returns its permanent public URL (or null on failure).
  Future<FoldrFile?> upload(String filePath) async {
    if (!isConfigured) return null;
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_endpoint))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));
      final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(minutes: 2)),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] != true) return null;
      final f = json['file'] as Map<String, dynamic>;
      return FoldrFile(
        publicUrl: (f['publicUrl'] ?? '').toString(),
        downloadUrl: (f['downloadUrl'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

class FoldrFile {
  const FoldrFile({required this.publicUrl, required this.downloadUrl});

  /// Shareable page link, e.g. https://foldr.space/f/{token}
  final String publicUrl;

  /// Direct file link (use for in-app audio playback).
  final String downloadUrl;
}
