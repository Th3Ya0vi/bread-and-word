import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// Site-wide moderation reports. Clients can only write; the team reviews
/// reports in the Firebase console. Backed by Firestore `reports`.
class ReportsRepository {
  ReportsRepository._();
  static final ReportsRepository instance = ReportsRepository._();

  final _db = FirebaseFirestore.instance;

  /// File a report against any piece of content.
  ///
  /// [targetType] is a coarse label like 'prayer', 'prayer_response', 'room',
  /// 'room_message', or 'user'. [targetPath] is the Firestore path when known,
  /// so a moderator can jump straight to it.
  Future<void> submit({
    required String targetType,
    required String targetId,
    String targetPath = '',
    required String reason,
    String details = '',
    String reportedUid = '',
  }) async {
    await _db.collection('reports').add({
      'reporterUid': AuthService.instance.uid,
      'targetType': targetType,
      'targetId': targetId,
      'targetPath': targetPath,
      'reportedUid': reportedUid,
      'reason': reason,
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
