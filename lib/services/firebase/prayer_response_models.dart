import 'package:cloud_firestore/cloud_firestore.dart';

/// A response to a prayer request — a written word of encouragement or a
/// recorded spoken prayer. Lives at `prayers/{prayerId}/responses/{id}`.
class PrayerResponse {
  const PrayerResponse({
    required this.id,
    required this.uid,
    required this.author,
    required this.type,
    this.text,
    this.audioUrl,
    this.durationMs,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String author;

  /// 'text' | 'audio'
  final String type;

  final String? text;
  final String? audioUrl;
  final int? durationMs;
  final DateTime? createdAt;

  bool get isAudio => type == 'audio';

  /// durationMs formatted as m:ss — e.g. 0:07, 1:42. Empty when unknown.
  String get durationLabel => formatDuration(durationMs);

  factory PrayerResponse.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return PrayerResponse(
      id: d.id,
      uid: (m['uid'] ?? '').toString(),
      author: (m['author'] ?? 'Friend in Christ').toString(),
      type: (m['type'] ?? 'text').toString(),
      text: m['text']?.toString(),
      audioUrl: m['audioUrl']?.toString(),
      durationMs: (m['durationMs'] as num?)?.toInt(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Format a millisecond duration as m:ss — e.g. 0:07, 2:05.
String formatDuration(int? ms) {
  if (ms == null || ms < 0) return '';
  final totalSeconds = (ms / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
