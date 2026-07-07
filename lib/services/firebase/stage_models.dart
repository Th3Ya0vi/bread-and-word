import 'package:cloud_firestore/cloud_firestore.dart';

/// A member's place on a room's live audio stage.
///
/// Stored at `rooms/{roomId}/stage/{uid}`. The [role] is one of:
/// - `host`      — the room creator, always on stage, can manage others.
/// - `speaker`   — promoted onto the stage, may publish audio.
/// - `requested` — an audience member raising their hand to speak.
class StageMember {
  const StageMember({
    required this.uid,
    required this.role,
    required this.author,
    this.since,
    this.muted = false,
  });

  final String uid;
  final String role;
  final String author;
  final DateTime? since;

  /// Muted by the host — the speaker's microphone is forced off.
  final bool muted;

  bool get isHost => role == 'host';
  bool get isSpeaker => role == 'host' || role == 'speaker';
  bool get isRequesting => role == 'requested';

  factory StageMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return StageMember(
      uid: d.id,
      role: (m['role'] ?? 'audience').toString(),
      author: (m['author'] ?? 'Friend').toString(),
      since: (m['since'] as Timestamp?)?.toDate(),
      muted: m['muted'] == true,
    );
  }
}
