import 'package:cloud_firestore/cloud_firestore.dart';

enum PrayerKind {
  prayer,
  testimony;

  static PrayerKind fromString(Object? value) {
    return value == 'testimony' ? PrayerKind.testimony : PrayerKind.prayer;
  }

  String get wireName => this == PrayerKind.testimony ? 'testimony' : 'prayer';
}

/// A prayer request or testimony on the wall.
class Prayer {
  const Prayer({
    required this.id,
    required this.author,
    required this.authorUid,
    required this.body,
    required this.prayingCount,
    required this.answered,
    this.kind = PrayerKind.prayer,
    this.createdAt,
  });

  final String id;
  final String author;
  final String authorUid;
  final String body;
  final int prayingCount;
  final bool answered;
  final PrayerKind kind;
  final DateTime? createdAt;

  bool get isTestimony => kind == PrayerKind.testimony;

  factory Prayer.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Prayer(
      id: d.id,
      author: (m['author'] ?? 'Anonymous').toString(),
      authorUid: (m['authorUid'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      prayingCount: (m['prayingCount'] as num?)?.toInt() ?? 0,
      answered: m['answered'] == true,
      kind: PrayerKind.fromString(m['kind']),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A gathering room.
class RoomDoc {
  const RoomDoc({
    required this.id,
    required this.title,
    required this.kind,
    required this.blurb,
    required this.hereNow,
    this.createdAt,
    this.createdBy = '',
    this.closed = false,
    this.recordingUrl = '',
    this.planId = '',
    this.planTitle = '',
    this.planDayLabel = '',
    this.planReferences = const [],
  });

  final String id;
  final String title;
  final String kind; // "Prayer" | "Bible Study"
  final String blurb;
  final int hereNow; // filled from presence, not stored on the doc
  final DateTime? createdAt;
  final String createdBy;
  final bool closed; // host ended the room — live session over
  final String recordingUrl; // foldr.space link to the session recording

  // Optional reading-plan context — set when a room is opened to read a plan
  // day together. Drives the "now reading" banner on the live stage.
  final String planId;
  final String planTitle;
  final String planDayLabel; // e.g. "Day 3 · The Bread of Life"
  final List<String> planReferences; // YouVersion refs for that day

  bool get hasPlan => planReferences.isNotEmpty;

  factory RoomDoc.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d, {
    int hereNow = 0,
  }) {
    final m = d.data() ?? const {};
    return RoomDoc(
      id: d.id,
      title: (m['title'] ?? 'Untitled').toString(),
      kind: (m['kind'] ?? 'Prayer').toString(),
      blurb: (m['blurb'] ?? '').toString(),
      hereNow: hereNow,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      createdBy: (m['createdBy'] ?? '').toString(),
      closed: m['closed'] == true,
      recordingUrl: (m['recordingUrl'] ?? '').toString(),
      planId: (m['planId'] ?? '').toString(),
      planTitle: (m['planTitle'] ?? '').toString(),
      planDayLabel: (m['planDayLabel'] ?? '').toString(),
      planReferences: (m['planReferences'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  RoomDoc copyWith({int? hereNow}) => RoomDoc(
    id: id,
    title: title,
    kind: kind,
    blurb: blurb,
    hereNow: hereNow ?? this.hereNow,
    createdAt: createdAt,
    createdBy: createdBy,
    closed: closed,
    recordingUrl: recordingUrl,
    planId: planId,
    planTitle: planTitle,
    planDayLabel: planDayLabel,
    planReferences: planReferences,
  );
}

/// A chat message inside a room.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.uid,
    required this.author,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String author;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return ChatMessage(
      id: d.id,
      uid: (m['uid'] ?? '').toString(),
      author: (m['author'] ?? 'Friend').toString(),
      text: (m['text'] ?? '').toString(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Relative "x ago" label in the mono-uppercase style the design uses.
String agoLabel(DateTime? t) {
  if (t == null) return 'JUST NOW';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'JUST NOW';
  if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
  if (d.inHours < 24) return '${d.inHours}H AGO';
  if (d.inDays == 1) return 'YESTERDAY';
  return '${d.inDays}D AGO';
}
