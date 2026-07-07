import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';
import 'prayer_response_models.dart';

/// Responses to a prayer request, backed by Firestore
/// `prayers/{prayerId}/responses` and Firebase Storage for audio.
class PrayerResponsesRepository {
  PrayerResponsesRepository._();
  static final PrayerResponsesRepository instance =
      PrayerResponsesRepository._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _col(String prayerId) =>
      _db.collection('prayers').doc(prayerId).collection('responses');

  /// Oldest first — responses read like a conversation under the request.
  Stream<List<PrayerResponse>> watch(String prayerId) {
    return _col(prayerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(PrayerResponse.fromDoc).toList());
  }

  /// A written word of encouragement.
  Future<void> addText(String prayerId, String text) async {
    final auth = AuthService.instance;
    await _col(prayerId).add({
      'uid': auth.uid,
      'author': auth.displayName,
      'type': 'text',
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// A recorded spoken prayer. Uploads the local .m4a to Storage, then writes
  /// the Firestore doc referencing the download URL.
  Future<void> addAudio(
    String prayerId,
    String localFilePath,
    int durationMs,
  ) async {
    final auth = AuthService.instance;
    final fileName =
        '${auth.uid}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref('prayer_responses/$prayerId/$fileName');

    await ref.putFile(
      File(localFilePath),
      SettableMetadata(contentType: 'audio/m4a'),
    );
    final audioUrl = await ref.getDownloadURL();

    await _col(prayerId).add({
      'uid': auth.uid,
      'author': auth.displayName,
      'type': 'audio',
      'audioUrl': audioUrl,
      'durationMs': durationMs,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete one of your own responses. Removes the Firestore doc and, for an
  /// audio response, the stored recording too.
  Future<void> delete(String prayerId, PrayerResponse response) async {
    await _col(prayerId).doc(response.id).delete();
    final url = response.audioUrl;
    if (response.isAudio && url != null && url.isNotEmpty) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // The doc is gone; an orphaned file is harmless and rules-gated.
      }
    }
  }
}
