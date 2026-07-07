import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'models.dart';
import 'user_profile_models.dart';

/// The Fellowship layer — a follow graph (no direct messaging).
///
/// The graph is written in mirrored pairs:
///   users/{me}/following/{them} = {since}
///   users/{them}/followers/{me} = {since}
///
/// Whom you follow shapes your fellowship feed (their prayers).
class FellowshipRepository {
  FellowshipRepository._();
  static final FellowshipRepository instance = FellowshipRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> _following(String uid) =>
      _users.doc(uid).collection('following');

  CollectionReference<Map<String, dynamic>> _followers(String uid) =>
      _users.doc(uid).collection('followers');

  /// Whether you can follow people — members only.
  bool get _canFollow => AuthService.instance.isMember;

  // ── Follow / unfollow ──

  /// Begin walking with [uid]: writes both the following and followers docs.
  /// Members only; a no-op for guests or following yourself.
  Future<void> follow(String uid) async {
    final me = AuthService.instance.uid;
    if (!_canFollow || me.isEmpty || uid.isEmpty || uid == me) return;
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(_following(me).doc(uid), {'since': now});
    batch.set(_followers(uid).doc(me), {'since': now});
    await batch.commit();
  }

  /// Stop walking with [uid]: deletes both mirrored docs.
  Future<void> unfollow(String uid) async {
    final me = AuthService.instance.uid;
    if (me.isEmpty || uid.isEmpty) return;
    final batch = _db.batch();
    batch.delete(_following(me).doc(uid));
    batch.delete(_followers(uid).doc(me));
    await batch.commit();
  }

  /// Whether the current user already follows [uid].
  Stream<bool> watchIsFollowing(String uid) {
    final me = AuthService.instance.uid;
    if (me.isEmpty || uid.isEmpty) return Stream.value(false);
    return _following(me).doc(uid).snapshots().map((d) => d.exists);
  }

  /// How many people walk with [uid] (their followers).
  Stream<int> followerCount(String uid) =>
      _followers(uid).snapshots().map((s) => s.docs.length);

  /// How many people [uid] walks with (those they follow).
  Stream<int> followingCount(String uid) =>
      _following(uid).snapshots().map((s) => s.docs.length);

  // ── Profile ──

  /// The public profile for [uid], with live fellowship / rooms counts folded in.
  Stream<UserProfile> watchProfile(String uid) {
    return _users.doc(uid).snapshots().asyncMap((doc) async {
      final profile = UserProfile.fromDoc(doc);
      final results = await Future.wait([
        _followers(uid).get(),
        _following(uid).get(),
        _db.collection('rooms').where('createdBy', isEqualTo: uid).get(),
      ]);
      return profile.copyWith(
        fellowshipCount: results[0].docs.length,
        followingCount: results[1].docs.length,
        roomsHosted: results[2].docs.length,
      );
    });
  }

  /// Set the current user's bio (merge — leaves the rest of the doc intact).
  Future<void> updateBio(String bio) async {
    final me = AuthService.instance.uid;
    if (me.isEmpty) return;
    await _users.doc(me).set({'bio': bio.trim()}, SetOptions(merge: true));
  }

  // ── Feeds ──

  /// Prayers authored by the people the current user follows.
  ///
  /// Firestore `whereIn` accepts at most 10 values, so if you follow more than
  /// ten people this feed reflects only the first ten following uids.
  Stream<List<Prayer>> watchFellowshipPrayers() {
    final me = AuthService.instance.uid;
    if (me.isEmpty) return Stream.value(const []);
    return _following(me).snapshots().asyncExpand((followingSnap) {
      final uids = followingSnap.docs.map((d) => d.id).toList();
      if (uids.isEmpty) return Stream.value(<Prayer>[]);
      // whereIn caps at 10; take the first ten followed uids.
      final scope = uids.take(10).toList();
      return _db
          .collection('prayers')
          .where('authorUid', whereIn: scope)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Prayer.fromDoc).toList());
    });
  }

  /// How many rooms [uid] has hosted (created).
  Stream<int> roomsHosted(String uid) {
    return _db
        .collection('rooms')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Prayers authored by [uid], newest first.
  Stream<List<Prayer>> prayersBy(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .collection('prayers')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Prayer.fromDoc).toList());
  }
}
