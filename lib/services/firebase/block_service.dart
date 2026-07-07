import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Mutual blocking. When A blocks B, neither can see the other's prayers,
/// responses, rooms, profile, chat, or presence — anywhere in the app.
///
/// Stored in two halves so either side can be undone independently:
///   users/{me}/blocks/{them}      — people I chose to block
///   users/{them}/blocked_by/{me}  — written by me so they hide me too
///
/// The effective hidden set for a user is blocks ∪ blocked_by, kept live in
/// [blocked] so every list can filter against it and react instantly.
class BlockService {
  BlockService._();
  static final BlockService instance = BlockService._();

  final _db = FirebaseFirestore.instance;

  /// The uids the current user must not see (either direction).
  final ValueNotifier<Set<String>> blocked = ValueNotifier<Set<String>>({});

  Set<String> _blocks = {};
  Set<String> _blockedBy = {};
  StreamSubscription? _blocksSub;
  StreamSubscription? _blockedBySub;

  CollectionReference<Map<String, dynamic>> _blocksCol(String uid) =>
      _db.collection('users').doc(uid).collection('blocks');
  CollectionReference<Map<String, dynamic>> _blockedByCol(String uid) =>
      _db.collection('users').doc(uid).collection('blocked_by');

  bool isBlocked(String uid) => uid.isNotEmpty && blocked.value.contains(uid);

  /// Begin watching the current user's block lists. Call after sign-in.
  void start() {
    final me = AuthService.instance.uid;
    if (me.isEmpty) return;
    _blocksSub?.cancel();
    _blockedBySub?.cancel();
    _blocksSub = _blocksCol(me).snapshots().listen((s) {
      _blocks = s.docs.map((d) => d.id).toSet();
      _recompute();
    });
    _blockedBySub = _blockedByCol(me).snapshots().listen((s) {
      _blockedBy = s.docs.map((d) => d.id).toSet();
      _recompute();
    });
  }

  void _recompute() => blocked.value = {..._blocks, ..._blockedBy};

  /// Block [otherUid] both ways. Idempotent.
  Future<void> block(String otherUid) async {
    final me = AuthService.instance.uid;
    if (me.isEmpty || otherUid.isEmpty || otherUid == me) return;
    final now = FieldValue.serverTimestamp();
    await _blocksCol(me).doc(otherUid).set({'at': now});
    // Mark myself in their blocked_by so they hide me too.
    await _blockedByCol(otherUid).doc(me).set({'at': now});
  }

  /// Undo a block I created (leaves intact any block they placed on me).
  Future<void> unblock(String otherUid) async {
    final me = AuthService.instance.uid;
    if (me.isEmpty || otherUid.isEmpty) return;
    await _blocksCol(me).doc(otherUid).delete().catchError((_) {});
    await _blockedByCol(otherUid).doc(me).delete().catchError((_) {});
  }

  /// The people I actively blocked (for an unblock list).
  Stream<List<String>> watchMyBlocks() {
    final me = AuthService.instance.uid;
    if (me.isEmpty) return Stream.value(const []);
    return _blocksCol(me).snapshots().map((s) => s.docs.map((d) => d.id).toList());
  }
}
