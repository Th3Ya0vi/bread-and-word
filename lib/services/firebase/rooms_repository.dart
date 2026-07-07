import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'models.dart';
import 'stage_models.dart';

/// Rooms backed by Firestore `rooms`, with chat in `rooms/{id}/messages` and
/// live "here now" presence in `rooms/{id}/presence`.
class RoomsRepository {
  RoomsRepository._();
  static final RoomsRepository instance = RoomsRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('rooms');

  /// A presence entry is "live" if its heartbeat is within this window.
  static const presenceWindow = Duration(seconds: 45);
  static const _heartbeat = Duration(seconds: 20);

  /// Open (live) rooms only — once a host ends a room it disappears here.
  Stream<List<RoomDoc>> watch() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RoomDoc.fromDoc(d))
            .where((r) => !r.closed)
            .toList());
  }

  /// The current member's own past (ended) rooms — only they can see these,
  /// e.g. to revisit a session recording.
  Stream<List<RoomDoc>> watchMyPastRooms() {
    final uid = AuthService.instance.uid;
    return _col
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RoomDoc.fromDoc(d))
            .where((r) => r.closed)
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0))));
  }

  /// Live status of a single room (so participants leave when the host ends it).
  Stream<bool> watchClosed(String roomId) {
    return _col.doc(roomId).snapshots().map((d) => d.data()?['closed'] == true);
  }

  /// Host action: end the room — closes the live session for everyone.
  Future<void> closeRoom(String roomId) async {
    await _col.doc(roomId).set({
      'closed': true,
      'closedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save the uploaded recording link (host only, after a session ends).
  Future<void> setRecordingUrl(String roomId, String url) async {
    await _col.doc(roomId).set(
      {'recordingUrl': url},
      SetOptions(merge: true),
    );
  }

  /// One-shot fetch of a room by id (used by deep links).
  Future<RoomDoc?> getRoom(String roomId) async {
    try {
      final snap = await _col.doc(roomId).get();
      if (!snap.exists) return null;
      return RoomDoc.fromDoc(snap);
    } catch (_) {
      return null;
    }
  }

  Future<String> create({
    required String title,
    required String kind,
    required String blurb,
    String planId = '',
    String planTitle = '',
    String planDayLabel = '',
    List<String> planReferences = const [],
  }) async {
    final ref = await _col.add({
      'title': title.trim(),
      'kind': kind,
      'blurb': blurb.trim(),
      'createdBy': AuthService.instance.uid,
      'closed': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (planReferences.isNotEmpty) ...{
        'planId': planId,
        'planTitle': planTitle,
        'planDayLabel': planDayLabel,
        'planReferences': planReferences,
      },
    });
    return ref.id;
  }

  // ── Chat ──

  Stream<List<ChatMessage>> messages(String roomId, {int limit = 100}) {
    return _col
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList().reversed.toList());
  }

  Future<void> send(String roomId, String text) async {
    final auth = AuthService.instance;
    await _col.doc(roomId).collection('messages').add({
      'uid': auth.uid,
      'author': auth.displayName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Presence ──

  DocumentReference<Map<String, dynamic>> _presenceDoc(String roomId) =>
      _col.doc(roomId).collection('presence').doc(AuthService.instance.uid);

  /// Number of members seen within [presenceWindow].
  Stream<int> hereNow(String roomId) {
    return _col
        .doc(roomId)
        .collection('presence')
        .snapshots()
        .map((s) {
      final cutoff = DateTime.now().subtract(presenceWindow);
      return s.docs.where((d) {
        final ts = (d.data()['lastSeen'] as Timestamp?)?.toDate();
        return ts != null && ts.isAfter(cutoff);
      }).length;
    });
  }

  Future<void> _beat(String roomId) => _presenceDoc(roomId).set({
        'author': AuthService.instance.displayName,
        'lastSeen': FieldValue.serverTimestamp(),
      });

  /// Begin a heartbeat that keeps the member "here". Cancel the returned
  /// callback (e.g. in dispose) to leave the room and clear presence.
  Future<void Function()> joinPresence(String roomId) async {
    await _beat(roomId);
    final timer = Stream.periodic(_heartbeat).listen((_) => _beat(roomId));
    return () {
      timer.cancel();
      _presenceDoc(roomId).delete().catchError((_) {});
    };
  }

  // ── Stage (live audio) ──

  CollectionReference<Map<String, dynamic>> _stageCol(String roomId) =>
      _col.doc(roomId).collection('stage');

  /// The uid of the member who created the room (its host), or '' if unknown.
  Future<String> roomCreator(String roomId) async {
    try {
      final snap = await _col.doc(roomId).get();
      return (snap.data()?['createdBy'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  /// Live roster of everyone on (or requesting) the stage, ordered by when
  /// they joined.
  Stream<List<StageMember>> watchStage(String roomId) {
    return _stageCol(roomId).snapshots().map((s) {
      final list = s.docs.map(StageMember.fromDoc).toList();
      list.sort((a, b) {
        final at = a.since ?? DateTime.now();
        final bt = b.since ?? DateTime.now();
        return at.compareTo(bt);
      });
      return list;
    });
  }

  /// The room creator marks themselves as the host on entering.
  Future<void> setHost(String roomId) async {
    final auth = AuthService.instance;
    await _stageCol(roomId).doc(auth.uid).set({
      'role': 'host',
      'author': auth.displayName,
      'since': FieldValue.serverTimestamp(),
    });
  }

  /// An audience member raises their hand to speak.
  Future<void> requestStage(String roomId) async {
    final auth = AuthService.instance;
    await _stageCol(roomId).doc(auth.uid).set({
      'role': 'requested',
      'author': auth.displayName,
      'since': FieldValue.serverTimestamp(),
    });
  }

  /// Step down from the stage (or withdraw a pending request).
  Future<void> leaveStage(String roomId) async {
    await _stageCol(roomId)
        .doc(AuthService.instance.uid)
        .delete()
        .catchError((_) {});
  }

  /// Host action: promote a requesting member to speaker.
  Future<void> promote(String roomId, String uid) async {
    await _stageCol(roomId).doc(uid).set(
      {'role': 'speaker'},
      SetOptions(merge: true),
    );
  }

  /// Host action: remove a member from the stage (demote to audience).
  Future<void> removeFromStage(String roomId, String uid) async {
    await _stageCol(roomId).doc(uid).delete().catchError((_) {});
  }

  /// Host action: force-mute (or unmute) a speaker.
  Future<void> setMuted(String roomId, String uid, bool muted) async {
    await _stageCol(roomId).doc(uid).set(
      {'muted': muted},
      SetOptions(merge: true),
    );
  }

  // ── Moderation (ban / kick) ──

  CollectionReference<Map<String, dynamic>> _bannedCol(String roomId) =>
      _col.doc(roomId).collection('banned');

  /// Host action: remove someone from the room entirely. They're dropped from
  /// the stage and added to the ban list, which their client watches to leave.
  Future<void> kick(String roomId, String uid) async {
    await _stageCol(roomId).doc(uid).delete().catchError((_) {});
    await _bannedCol(roomId).doc(uid).set({
      'at': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  /// Whether the current user has been removed from this room.
  Stream<bool> watchBanned(String roomId) {
    return _bannedCol(roomId)
        .doc(AuthService.instance.uid)
        .snapshots()
        .map((d) => d.exists);
  }
}
