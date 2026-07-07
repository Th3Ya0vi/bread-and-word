import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../reading_progress.dart';
import 'auth_service.dart';

class CircleDoc {
  const CircleDoc({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberUids,
    this.createdBy = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberUids;
  final String createdBy;
  final DateTime? createdAt;

  int get memberCount => memberUids.length;

  factory CircleDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return CircleDoc(
      id: d.id,
      name: (m['name'] ?? 'Circle').toString(),
      inviteCode: (m['inviteCode'] ?? '').toString(),
      memberUids: (m['memberUids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdBy: (m['createdBy'] ?? '').toString(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class CircleReflection {
  const CircleReflection({
    required this.id,
    required this.uid,
    required this.author,
    required this.body,
    required this.dateKey,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String author;
  final String body;
  final String dateKey;
  final DateTime? createdAt;

  factory CircleReflection.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return CircleReflection(
      id: d.id,
      uid: (m['uid'] ?? '').toString(),
      author: (m['author'] ?? 'Friend in Christ').toString(),
      body: (m['body'] ?? '').toString(),
      dateKey: (m['dateKey'] ?? '').toString(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class VerseReaction {
  const VerseReaction({required this.uid, required this.kind});

  final String uid;
  final String kind;
}

class SocialRepository {
  SocialRepository._();
  static final SocialRepository instance = SocialRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _db.collection('circles');

  Stream<List<CircleDoc>> watchMyCircles() {
    final uid = AuthService.instance.uid;
    return _circles
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map(
          (s) => s.docs.map(CircleDoc.fromDoc).toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            ),
        );
  }

  Future<String> createCircle(String name) async {
    final auth = AuthService.instance;
    final ref = await _circles.add({
      'name': name.trim(),
      'inviteCode': _inviteCode(),
      'createdBy': auth.uid,
      'memberUids': [auth.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<CircleDoc?> joinByInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final snap = await _circles
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    await doc.reference.set({
      'memberUids': FieldValue.arrayUnion([AuthService.instance.uid]),
    }, SetOptions(merge: true));
    return CircleDoc.fromDoc(await doc.reference.get());
  }

  Stream<List<CircleReflection>> watchTodayReflections(String circleId) {
    final dateKey = ReadingProgress.easternDateKey();
    return _circles
        .doc(circleId)
        .collection('reflections')
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map(
          (s) => s.docs.map(CircleReflection.fromDoc).toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            ),
        );
  }

  Future<void> addReflection(String circleId, String body) async {
    final auth = AuthService.instance;
    await _circles.doc(circleId).collection('reflections').add({
      'uid': auth.uid,
      'author': auth.displayName,
      'body': body.trim(),
      'dateKey': ReadingProgress.easternDateKey(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, int>> watchVerseReactionCounts(String verseKey) {
    return _db
        .collection('bible_reactions')
        .doc(verseKey)
        .collection('reactions')
        .snapshots()
        .map((s) {
          final counts = <String, int>{};
          for (final d in s.docs) {
            final kind = (d.data()['kind'] ?? '').toString();
            if (kind.isEmpty) continue;
            counts[kind] = (counts[kind] ?? 0) + 1;
          }
          return counts;
        });
  }

  Stream<String?> watchMyVerseReaction(String verseKey) {
    return _db
        .collection('bible_reactions')
        .doc(verseKey)
        .collection('reactions')
        .doc(AuthService.instance.uid)
        .snapshots()
        .map((d) => d.data()?['kind']?.toString());
  }

  Future<void> reactToVerse(String verseKey, String kind) async {
    final auth = AuthService.instance;
    await _db
        .collection('bible_reactions')
        .doc(verseKey)
        .collection('reactions')
        .doc(auth.uid)
        .set({
          'uid': auth.uid,
          'author': auth.displayName,
          'kind': kind,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  static String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
