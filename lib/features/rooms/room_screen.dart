import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/agora_service.dart';
import '../../services/foldr_service.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/block_service.dart';
import '../../services/firebase/models.dart';
import '../../services/firebase/rooms_repository.dart';
import '../../services/firebase/stage_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';
import '../moderation/content_actions.dart';
import '../moderation/report_sheet.dart';
import '../plans/passage_view.dart';
import 'room_share.dart';

/// Inside a room — a LIVE AUDIO STAGE. A host and speakers are on stage;
/// the audience can raise a hand to speak and the host approves. Text chat and
/// "here now" presence stay alongside, beneath a Chat toggle.
///
/// On enter the member joins Agora (host → broadcaster, others → audience),
/// sets presence, and — if they created the room — claims the host seat.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.room});
  final RoomDoc room;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _repo = RoomsRepository.instance;
  final _agora = AgoraService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  void Function()? _leavePresence;
  StreamSubscription<bool>? _banSub;
  StreamSubscription<bool>? _closedSub;
  bool _isCreator = false;
  bool _muted = false;
  bool _hostMuted = false; // forced muted by the host
  bool _showChat = false;
  bool _live = false; // currently publishing audio (broadcaster)
  bool _recording = false;
  bool _ending = false;
  String? _recordingPath;

  String get _roomId => widget.room.id;
  String get _myUid => AuthService.instance.uid;

  @override
  void initState() {
    super.initState();
    _enter();
    // If the host removes us from the room, leave immediately.
    _banSub = _repo.watchBanned(_roomId).listen((banned) {
      if (banned && mounted) {
        _toast('You were removed from this room.');
        Navigator.of(context).maybePop();
      }
    });
    // If the host ends the room, everyone leaves.
    _closedSub = _repo.watchClosed(_roomId).listen((closed) {
      if (closed && mounted) {
        if (!_isCreator) _toast('The host ended this room.');
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _handleBack() async {
    // A host doesn't "leave" — they end the room (closing the live session).
    if (_isCreator) {
      if (await _confirmEnd()) await _endRoom();
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Host ends the session: finalize + upload the recording, then close.
  Future<void> _endRoom() async {
    if (_ending) return;
    if (mounted) setState(() => _ending = true);
    if (_recording) {
      await _agora.stopRecording();
      _recording = false;
      final path = _recordingPath;
      if (path != null && FoldrService.instance.isConfigured) {
        if (mounted) _toast('Saving the recording…');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final file = await FoldrService.instance.upload(path);
        if (file != null) {
          // Direct file URL — public + range-streamable for in-app playback.
          await _repo.setRecordingUrl(_roomId, file.downloadUrl);
        }
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
    }
    await _repo.closeRoom(_roomId);
  }

  Future<bool> _confirmEnd() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.paperBright,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('End this room?', style: AppType.display(24)),
              const SizedBox(height: 4),
              Text(
                'The live session closes for everyone. Only you will be able to '
                'return to it afterward.',
                style: AppType.flourish(15),
              ),
              const SizedBox(height: 18),
              _StageButton(
                label: 'End room',
                icon: PhosphorIconsRegular.stop,
                filled: true,
                onTap: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 10),
              _StageButton(
                label: 'Keep going',
                icon: PhosphorIconsRegular.x,
                onTap: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Keep our mic in sync with a host-imposed mute.
  void _syncHostMute(StageMember? me) {
    final muted = me?.muted ?? false;
    if (muted == _hostMuted) return;
    _hostMuted = muted;
    if (muted && _live && !_muted) {
      _agora.setMuted(true);
      if (mounted) setState(() => _muted = true);
    }
  }

  Future<void> _enter() async {
    // Presence (existing behaviour).
    _repo.joinPresence(_roomId).then((leave) {
      if (mounted) {
        _leavePresence = leave;
      } else {
        leave();
      }
    });

    final creator = await _repo.roomCreator(_roomId);
    // Only a signed-in member can be the host (guests are always audience).
    _isCreator = creator.isNotEmpty &&
        creator == _myUid &&
        AuthService.instance.isMember;

    if (_isCreator) {
      // The creator hosts: claim the host seat and go live as broadcaster.
      await _repo.setHost(_roomId);
      final granted = await _ensureMic();
      await _agora.join(_roomId, asBroadcaster: granted);
      if (mounted) setState(() => _live = granted);
      // Record the session so the host can revisit it.
      if (granted && FoldrService.instance.isConfigured) {
        _recordingPath =
            '${Directory.systemTemp.path}/room_${_roomId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recording = await _agora.startRecording(_recordingPath!);
      }
    } else {
      await _agora.join(_roomId, asBroadcaster: false);
    }
  }

  Future<bool> _ensureMic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ── Stage actions ──

  Future<void> _requestToSpeak() async {
    if (!await requireAccount(context, action: 'join the stage')) return;
    await _repo.requestStage(_roomId);
  }

  Future<void> _goLiveAsSpeaker() async {
    final granted = await _ensureMic();
    if (!granted) {
      if (mounted) _toast('Microphone permission is needed to speak.');
      return;
    }
    await _agora.setBroadcaster(true);
    if (mounted) {
      setState(() {
        _live = true;
        _muted = false;
      });
    }
  }

  Future<void> _leaveStage() async {
    await _repo.leaveStage(_roomId);
    await _agora.setBroadcaster(false);
    if (mounted) setState(() => _live = false);
  }

  Future<void> _toggleMute() async {
    if (_hostMuted && _muted) {
      _toast('The host has muted you.');
      return;
    }
    final next = !_muted;
    await _agora.setMuted(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _promote(StageMember m) async {
    await _repo.promote(_roomId, m.uid);
  }

  Future<void> _removeFromStage(StageMember m) async {
    if (m.uid == _myUid) {
      await _leaveStage();
      return;
    }
    await _repo.removeFromStage(_roomId, m.uid);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.ink,
      content: Text(text, style: AppType.body(15, color: AppColors.paperBright)),
    ));
  }

  // ── Chat ──

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!await requireAccount(context, action: 'speak in a room')) return;
    _controller.clear();
    await _repo.send(_roomId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _banSub?.cancel();
    _closedSub?.cancel();
    _leavePresence?.call();
    if (!_isCreator) {
      // Hosts keep their seat (room belongs to them); others step off cleanly.
      _repo.leaveStage(_roomId);
    } else {
      _repo.removeFromStage(_roomId, _myUid);
    }
    _agora.leave();
    _agora.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: StreamBuilder<List<StageMember>>(
            stream: _repo.watchStage(_roomId),
            builder: (context, snap) {
              final stage = (snap.data ?? const <StageMember>[])
                  .where((m) =>
                      m.uid == _myUid || !BlockService.instance.isBlocked(m.uid))
                  .toList();
              final me = _meIn(stage);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _syncHostMute(me));
              final amHost = me?.isHost ?? false;
              final amSpeaker = me?.isSpeaker ?? false;
              final speakers =
                  stage.where((m) => m.isSpeaker).toList(growable: false);
              final requests =
                  stage.where((m) => m.isRequesting).toList(growable: false);

              return Column(
                children: [
                  _header(context),
                  if (widget.room.hasPlan) _planBanner(context),
                  Expanded(
                    child: _showChat
                        ? _chatList()
                        : _stagePanel(
                            speakers: speakers,
                            requests: requests,
                            amHost: amHost,
                            amSpeaker: amSpeaker,
                            me: me,
                          ),
                  ),
                  if (_showChat) _composer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  StageMember? _meIn(List<StageMember> stage) {
    for (final m in stage) {
      if (m.uid == _myUid) return m;
    }
    return null;
  }

  // ── Header ──

  Widget _header(BuildContext context) {
    final room = widget.room;
    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft,
                    color: AppColors.ink),
                onPressed: _handleBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: AppType.display(20)),
                    StreamBuilder<int>(
                      stream: _repo.hereNow(room.id),
                      builder: (context, snap) {
                        final here = snap.data ?? 0;
                        final live = here > 0;
                        return Row(
                          children: [
                            if (live) ...[
                              Container(
                                  width: 5, height: 5, color: AppColors.accent),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              live
                                  ? '$here here now'.toUpperCase()
                                  : room.kind.toUpperCase(),
                              style: AppType.mono(9,
                                  color: live
                                      ? AppColors.accent
                                      : AppColors.inkFaded),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => shareRoom(widget.room),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(PhosphorIconsRegular.userPlus,
                      size: 20, color: AppColors.ink),
                ),
              ),
              if (!_isCreator)
                MoreButton(
                  actions: [
                    ContentAction(
                      icon: PhosphorIconsRegular.flag,
                      label: 'Report this room',
                      onTap: () => presentReportSheet(
                        context,
                        targetType: 'room',
                        targetId: room.id,
                        targetPath: 'rooms/${room.id}',
                        reportedUid: room.createdBy,
                        label: 'this room',
                      ),
                    ),
                    if (room.createdBy.isNotEmpty)
                      blockUserAction(context, uid: room.createdBy),
                  ],
                ),
              _chatToggle(),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.inkFaded),
        ],
      ),
    );
  }

  /// "Now reading" strip shown when the room was opened to read a plan day
  /// together. Tap to open the passage so everyone can follow along.
  Widget _planBanner(BuildContext context) {
    final room = widget.room;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPlanPassage(context),
      child: Container(
        width: double.infinity,
        color: AppColors.paperBright,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(PhosphorIconsRegular.bookOpen,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('NOW READING — TAP TO OPEN',
                    style: AppType.mono(9, color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              room.planDayLabel.isNotEmpty
                  ? room.planDayLabel
                  : room.planReferences.join(' · '),
              style: AppType.body(16, color: AppColors.ink),
            ),
            if (room.planTitle.isNotEmpty)
              Text(room.planTitle, style: AppType.flourish(13)),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.inkFaded),
          ],
        ),
      ),
    );
  }

  void _openPlanPassage(BuildContext context) {
    final room = widget.room;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => SafeArea(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.planDayLabel.isNotEmpty
                          ? room.planDayLabel
                          : 'Reading together',
                      style: AppType.display(24),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x,
                        color: AppColors.ink),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PassageView(references: room.planReferences),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showChat = !_showChat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _showChat ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showChat
                  ? PhosphorIconsRegular.microphone
                  : PhosphorIconsRegular.chatCircle,
              size: 14,
              color: _showChat ? AppColors.paperBright : AppColors.ink,
            ),
            const SizedBox(width: 6),
            Text(
              _showChat ? 'STAGE' : 'CHAT',
              style: AppType.mono(9,
                  color: _showChat ? AppColors.paperBright : AppColors.ink,
                  weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stage panel ──

  Widget _stagePanel({
    required List<StageMember> speakers,
    required List<StageMember> requests,
    required bool amHost,
    required bool amSpeaker,
    StageMember? me,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const SectionHeader(
          eyebrow: 'On stage',
          title: 'The circle',
          subline: 'Speak a word, or simply listen and pray.',
          titleSize: 22,
        ),
        const SizedBox(height: 14),
        _statsRow(speakers.length),
        const SizedBox(height: 18),
        if (speakers.isEmpty)
          Text('No one is on stage yet.', style: AppType.flourish(15))
        else
          ValueListenableBuilder<Set<int>>(
            valueListenable: _agora.activeSpeakers,
            builder: (context, active, _) {
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final s in speakers)
                    _StageSeat(
                      member: s,
                      isMe: s.uid == _myUid,
                      speaking: _isSpeaking(s, active),
                      onTap: amHost && s.uid != _myUid
                          ? () => _hostControls(s)
                          : null,
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 24),
        if (amHost && requests.isNotEmpty) ...[
          const RuleLabel('Raised hands'),
          const SizedBox(height: 12),
          for (final r in requests) _requestRow(r),
          const SizedBox(height: 24),
        ],
        _primaryAction(amSpeaker: amSpeaker, amHost: amHost, me: me),
      ],
    );
  }

  // ── Stats / duration ──

  String _openFor() {
    final start = widget.room.createdAt;
    if (start == null) return 'JUST OPENED';
    final d = DateTime.now().difference(start);
    if (d.inMinutes < 1) return 'JUST OPENED';
    if (d.inMinutes < 60) return 'OPEN ${d.inMinutes}M';
    return 'OPEN ${d.inHours}H ${d.inMinutes % 60}M';
  }

  Widget _statsRow(int speakerCount) {
    return Row(
      children: [
        _stat(PhosphorIconsRegular.clock, _openFor()),
        _statDivider(),
        StreamBuilder<int>(
          stream: _repo.hereNow(_roomId),
          builder: (context, snap) =>
              _stat(PhosphorIconsRegular.users, '${snap.data ?? 0} HERE'),
        ),
        _statDivider(),
        _stat(PhosphorIconsRegular.microphoneStage, '$speakerCount ON STAGE'),
      ],
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.inkFaded),
        const SizedBox(width: 5),
        Text(label, style: AppType.mono(9, color: AppColors.inkFaded)),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 11,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.inkFaded,
      );

  bool _isSpeaking(StageMember s, Set<int> active) {
    if (active.isEmpty) return false;
    // Agora reports our own audio under uid 0 in the volume callback.
    if (s.uid == _myUid) return _live && !_muted && active.contains(0);
    return active.contains(AgoraService.uidFromAuthString(s.uid));
  }

  Widget _requestRow(StageMember r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: AppColors.paperDeep,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(r.author,
                  style: AppType.body(16, color: AppColors.ink)),
            ),
            GestureDetector(
              onTap: () => _promote(r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                color: AppColors.ink,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.check,
                        size: 13, color: AppColors.paperBright),
                    const SizedBox(width: 6),
                    Text('APPROVE',
                        style: AppType.mono(9,
                            color: AppColors.paperBright,
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction({
    required bool amSpeaker,
    required bool amHost,
    StageMember? me,
  }) {
    // Speaker / host: mute toggle + leave stage.
    if (amSpeaker) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StageButton(
                  label: _muted ? 'Unmute' : 'Mute',
                  icon: _muted
                      ? PhosphorIconsRegular.microphoneSlash
                      : PhosphorIconsRegular.microphone,
                  filled: _muted,
                  onTap: _live ? _toggleMute : _goLiveAsSpeaker,
                ),
              ),
              if (!amHost) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _StageButton(
                    label: 'Leave stage',
                    icon: PhosphorIconsRegular.signOut,
                    onTap: _leaveStage,
                  ),
                ),
              ],
            ],
          ),
          if (!_live) ...[
            const SizedBox(height: 8),
            Text('Tap to turn on your microphone.',
                style: AppType.flourish(13)),
          ],
          if (amHost) ...[
            const SizedBox(height: 12),
            _StageButton(
              label: _ending ? 'Ending…' : 'End room',
              icon: PhosphorIconsRegular.stop,
              filled: true,
              onTap: () async {
                if (!_ending && await _confirmEnd()) await _endRoom();
              },
            ),
          ],
        ],
      );
    }

    // Pending request.
    if (me?.isRequesting ?? false) {
      return _StageButton(
        label: 'Cancel request',
        icon: PhosphorIconsRegular.handPalm,
        onTap: _leaveStage,
      );
    }

    // Audience.
    return _StageButton(
      label: 'Request to speak',
      icon: PhosphorIconsRegular.hand,
      filled: true,
      onTap: _requestToSpeak,
    );
  }

  void _hostControls(StageMember s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paperBright,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.author, style: AppType.display(22)),
              const SizedBox(height: 2),
              Text('HOST CONTROLS', style: AppType.mono(9)),
              const SizedBox(height: 18),
              _StageButton(
                label: s.muted ? 'Unmute speaker' : 'Mute speaker',
                icon: s.muted
                    ? PhosphorIconsRegular.microphone
                    : PhosphorIconsRegular.microphoneSlash,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _repo.setMuted(_roomId, s.uid, !s.muted);
                },
              ),
              const SizedBox(height: 10),
              _StageButton(
                label: 'Remove from stage',
                icon: PhosphorIconsRegular.userMinus,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeFromStage(s);
                },
              ),
              const SizedBox(height: 10),
              _StageButton(
                label: 'Remove from room',
                icon: PhosphorIconsRegular.prohibit,
                filled: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _repo.kick(_roomId, s.uid);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat (preserved) ──

  Widget _chatList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _repo.messages(_roomId),
      builder: (context, snap) {
        final messages = (snap.data ?? const <ChatMessage>[])
            .where((m) => !BlockService.instance.isBlocked(m.uid))
            .toList();
        if (snap.hasData && messages.isEmpty) {
          return Center(
            child: Text(
              'Be the first to speak a word here.',
              style: AppType.flourish(16),
            ),
          );
        }
        final myUid = _myUid;
        return ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final m = messages[messages.length - 1 - i];
            return _MessageRow(msg: m, mine: m.uid == myUid);
          },
        );
      },
    );
  }

  Widget _composer() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.inkFaded, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 1),
                color: AppColors.paperBright,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                style: AppType.body(16, color: AppColors.ink),
                cursorColor: AppColors.accent,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Write a word…',
                  hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(13),
              color: AppColors.ink,
              child: Text('→',
                  style: AppType.display(18, color: AppColors.paperBright)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bordered paper seat for one stage member.
class _StageSeat extends StatelessWidget {
  const _StageSeat({
    required this.member,
    required this.isMe,
    required this.speaking,
    this.onTap,
  });

  final StageMember member;
  final bool isMe;
  final bool speaking;
  final VoidCallback? onTap;

  String get _initials {
    final parts = member.author
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ring = speaking ? AppColors.accent : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.paperDeep,
                border: Border.all(color: ring, width: speaking ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: Text(_initials, style: AppType.display(22)),
            ),
            const SizedBox(height: 7),
            Text(
              isMe ? 'YOU' : member.author.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppType.mono(9, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 3),
            if (member.isHost)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsRegular.crown,
                      size: 11, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('HOST',
                      style: AppType.mono(8,
                          color: AppColors.accent, weight: FontWeight.w600)),
                ],
              )
            else if (speaking)
              Text('SPEAKING',
                  style: AppType.mono(8, color: AppColors.accent))
            else
              Text('SPEAKER', style: AppType.mono(8)),
          ],
        ),
      ),
    );
  }
}

/// A flat rectangular stage action button (separate from BwButton so it can
/// carry mic state colour without touching the shared widget).
class _StageButton extends StatelessWidget {
  const _StageButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.paperBright : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: filled ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(label.toUpperCase(),
                style: AppType.mono(11, color: fg, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.msg, required this.mine});
  final ChatMessage msg;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            mine ? 'YOU' : msg.author.toUpperCase(),
            style: AppType.mono(9,
                color: mine ? AppColors.accent : AppColors.inkFaded),
          ),
          const SizedBox(height: 3),
          Text(
            msg.text,
            textAlign: mine ? TextAlign.right : TextAlign.left,
            style: AppType.body(16, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
