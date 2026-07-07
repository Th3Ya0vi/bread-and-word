import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'models.dart';

/// The prayer wall, backed by Firestore `prayers`.
class PrayersRepository {
  PrayersRepository._();
  static final PrayersRepository instance = PrayersRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('prayers');

  /// Newest first. Answered prayers remain on the wall as testimony.
  Stream<List<Prayer>> watch({int limit = 50}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Prayer.fromDoc).toList());
  }

  Future<void> add({
    required String body,
    bool anonymous = false,
    PrayerKind kind = PrayerKind.prayer,
  }) async {
    final auth = AuthService.instance;
    await _col.add({
      'author': anonymous ? 'Anonymous' : auth.displayName,
      'authorUid': auth.uid,
      'body': body.trim(),
      'kind': kind.wireName,
      'prayingCount': 0,
      'answered': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record that the current user prayed — idempotent (counts once per person).
  Future<void> pray(String prayerId) async {
    final uid = AuthService.instance.uid;
    final prayerRef = _col.doc(prayerId);
    final markRef = prayerRef.collection('prayedBy').doc(uid);
    await _db.runTransaction((tx) async {
      final mark = await tx.get(markRef);
      if (mark.exists) return;
      tx.set(markRef, {'at': FieldValue.serverTimestamp()});
      tx.update(prayerRef, {'prayingCount': FieldValue.increment(1)});
    });
  }

  /// Whether the current user already prayed for this request.
  Stream<bool> watchPrayed(String prayerId) {
    final uid = AuthService.instance.uid;
    return _col
        .doc(prayerId)
        .collection('prayedBy')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  /// Mark a prayer answered (rules restrict this to the author).
  Future<void> markAnswered(String prayerId) =>
      _col.doc(prayerId).update({'answered': true});

  /// Turn an answered request into a testimony on the shared wall.
  Future<void> markAnsweredAsTestimony(String prayerId) =>
      _col.doc(prayerId).set({
        'answered': true,
        'kind': PrayerKind.testimony,
      }, SetOptions(merge: true));
}
