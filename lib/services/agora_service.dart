import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../config/secrets.dart';
import 'firebase/auth_service.dart';

/// Wraps the Agora RTC engine for live audio stages.
///
/// One instance per room session. Tokens are fetched from the `agoraToken`
/// callable Cloud Function (built by another agent — this guards gracefully if
/// it isn't deployed yet). Everything no-ops safely when [AGORA_APP_ID] is
/// empty or any call fails, so the rest of the app never crashes.
class AgoraService {
  AgoraService();

  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: Secrets.agoraAppId,
  );

  RtcEngine? _engine;
  String? _channel;
  int _uid = 0;
  bool _broadcaster = false;
  bool _joined = false;

  /// Remote uids currently in the channel (speakers/hosts you can hear).
  final ValueNotifier<Set<int>> remoteUids = ValueNotifier(<int>{});

  /// Uids speaking right now (local uid included as 0 when you speak).
  final ValueNotifier<Set<int>> activeSpeakers = ValueNotifier(<int>{});

  bool get isAvailable => appId.isNotEmpty;
  int get localUid => _uid;

  /// A stable positive 32-bit int derived from a Firebase uid. Agora uids must
  /// be unsigned 32-bit; we keep it in [1, 2^31) so it never collides with 0
  /// (the "local" sentinel) and is reproducible across reconnects.
  static int uidFromAuthString(String s) {
    if (s.isEmpty) return 0;
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h == 0 ? 1 : h;
  }

  /// The Agora uid for the currently signed-in member.
  static int uidFromAuth() => uidFromAuthString(AuthService.instance.uid);

  Future<String?> _fetchToken({
    required String channelName,
    required bool asBroadcaster,
    required int uid,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('agoraToken');
      final res = await callable.call<Map<String, dynamic>>({
        'channelName': channelName,
        'role': asBroadcaster ? 'publisher' : 'audience',
        'uid': uid,
      });
      final data = res.data;
      final token = data['token'];
      return token is String ? token : null;
    } catch (e) {
      debugPrint('AgoraService: token fetch failed — $e');
      return null;
    }
  }

  /// Join [roomId] as a broadcaster (host/speaker) or audience listener.
  Future<void> join(String roomId, {required bool asBroadcaster}) async {
    if (!isAvailable) {
      debugPrint('AgoraService: AGORA_APP_ID empty — running silent.');
      return;
    }
    if (_joined) return;

    _uid = uidFromAuth();
    _broadcaster = asBroadcaster;

    final token = await _fetchToken(
      channelName: roomId,
      asBroadcaster: asBroadcaster,
      uid: _uid,
    );
    if (token == null) {
      debugPrint('AgoraService: no token — staying offline.');
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _engine = engine;

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _joined = true;
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          remoteUids.value = {...remoteUids.value, remoteUid};
        },
        onUserOffline: (connection, remoteUid, reason) {
          remoteUids.value = {...remoteUids.value}..remove(remoteUid);
          activeSpeakers.value = {...activeSpeakers.value}..remove(remoteUid);
        },
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
          final loud = <int>{};
          for (final s in speakers) {
            final uid = s.uid ?? 0;
            if ((s.volume ?? 0) > 12) loud.add(uid);
          }
          activeSpeakers.value = loud;
        },
        onTokenPrivilegeWillExpire: (connection, token) async {
          final fresh = await _fetchToken(
            channelName: roomId,
            asBroadcaster: _broadcaster,
            uid: _uid,
          );
          if (fresh != null) {
            try {
              await _engine?.renewToken(fresh);
            } catch (e) {
              debugPrint('AgoraService: renewToken failed — $e');
            }
          }
        },
      ));

      await engine.enableAudio();
      await engine.enableAudioVolumeIndication(
        interval: 400,
        smooth: 3,
        reportVad: true,
      );
      await engine.setClientRole(
        role: asBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      _channel = roomId;
      await engine.joinChannel(
        token: token,
        channelId: roomId,
        uid: _uid,
        options: ChannelMediaOptions(
          clientRoleType: asBroadcaster
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          channelProfile:
              ChannelProfileType.channelProfileLiveBroadcasting,
          publishMicrophoneTrack: asBroadcaster,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      debugPrint('AgoraService: join failed — $e');
      await _safeRelease();
    }
  }

  /// Switch between broadcaster and audience, renewing the token for the role.
  Future<void> setBroadcaster(bool value) async {
    final engine = _engine;
    if (engine == null || _channel == null) return;
    if (_broadcaster == value) return;
    _broadcaster = value;

    final token = await _fetchToken(
      channelName: _channel!,
      asBroadcaster: value,
      uid: _uid,
    );
    try {
      if (token != null) await engine.renewToken(token);
      await engine.setClientRole(
        role: value
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
      await engine.updateChannelMediaOptions(ChannelMediaOptions(
        clientRoleType: value
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: value,
        autoSubscribeAudio: true,
      ));
    } catch (e) {
      debugPrint('AgoraService: setBroadcaster failed — $e');
    }
  }

  Future<void> setMuted(bool muted) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (e) {
      debugPrint('AgoraService: setMuted failed — $e');
    }
  }

  /// Record the *mixed* channel audio (all speakers) to a local file.
  /// Returns true if recording started. Call from the host only.
  Future<bool> startRecording(String filePath) async {
    final engine = _engine;
    if (engine == null) return false;
    try {
      await engine.startAudioRecording(AudioRecordingConfiguration(
        filePath: filePath,
        fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
        encode: true,
        sampleRate: 44100,
        quality: AudioRecordingQualityType.audioRecordingQualityMedium,
      ));
      return true;
    } catch (e) {
      debugPrint('AgoraService: startRecording failed — $e');
      return false;
    }
  }

  Future<void> stopRecording() async {
    try {
      await _engine?.stopAudioRecording();
    } catch (e) {
      debugPrint('AgoraService: stopRecording failed — $e');
    }
  }

  Future<void> leave() async {
    final engine = _engine;
    if (engine != null) {
      try {
        await engine.leaveChannel();
      } catch (e) {
        debugPrint('AgoraService: leaveChannel failed — $e');
      }
    }
    await _safeRelease();
  }

  Future<void> _safeRelease() async {
    final engine = _engine;
    _engine = null;
    _joined = false;
    _channel = null;
    remoteUids.value = <int>{};
    activeSpeakers.value = <int>{};
    if (engine != null) {
      try {
        await engine.release();
      } catch (e) {
        debugPrint('AgoraService: release failed — $e');
      }
    }
  }

  void dispose() {
    remoteUids.dispose();
    activeSpeakers.dispose();
  }
}
