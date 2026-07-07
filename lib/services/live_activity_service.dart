import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the iOS Live Activity (Dynamic Island + lock screen) that shows
/// when the member is in a live room, with tap-to-return.
///
/// The native side is an ActivityKit widget extension wired to the
/// `breadandword/live_activity` method channel (see LIVE_ACTIVITY_SETUP.md).
/// Until that target is added, every call simply no-ops — safe on any build,
/// and on Android (which has no Live Activities).
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  static const _channel = MethodChannel('breadandword/live_activity');

  String? _activeRoomId;

  bool get isShowing => _activeRoomId != null;

  /// Start (or replace) the Live Activity for a room the member just joined.
  Future<void> start({
    required String roomId,
    required String title,
    required String kind,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod('start', {
        'roomId': roomId,
        'title': title,
        'kind': kind,
      });
      _activeRoomId = roomId;
    } catch (e) {
      // No widget extension yet, or below iOS 16.1 — fine, just skip.
      debugPrint('LiveActivity: start skipped — $e');
    }
  }

  /// Update the live count or state shown in the island.
  Future<void> update({required int hereNow}) async {
    if (_activeRoomId == null) return;
    try {
      await _channel.invokeMethod('update', {'hereNow': hereNow});
    } catch (_) {}
  }

  /// End the Live Activity when the member leaves the room.
  Future<void> end() async {
    if (_activeRoomId == null) return;
    _activeRoomId = null;
    try {
      await _channel.invokeMethod('end');
    } catch (_) {}
  }
}
