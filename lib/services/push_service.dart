import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase/auth_service.dart';

/// Push notifications: asks permission and registers this device's FCM token on
/// the member's profile. Foreground banners are presented natively by iOS via
/// [setForegroundNotificationPresentationOptions]; background/closed messages
/// are shown by the OS from the FCM payload.
///
/// Delivery on iOS also requires an APNs Auth Key uploaded to Firebase
/// (Console → Project settings → Cloud Messaging) plus the push capability —
/// the app code and entitlement are ready for both.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _fcm = FirebaseMessaging.instance;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      // Show banners even while the app is in the foreground (iOS).
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
      _fcm.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      debugPrint('PushService: init failed — $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = AuthService.instance.uid;
    if (uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PushService: save token failed — $e');
    }
  }
}
