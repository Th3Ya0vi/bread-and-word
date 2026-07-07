import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/firebase/block_service.dart';
import '../../services/firebase/models.dart';
import '../../services/firebase/prayer_response_models.dart';
import '../../services/firebase/prayer_responses_repository.dart';
import '../../services/gloo/encouragement_writer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';
import '../moderation/report_sheet.dart';
import '../moderation/content_actions.dart';

/// One prayer request in full, with the community's responses beneath it and a
/// composer pinned at the bottom — write a word, or record a spoken prayer.
class PrayerDetailScreen extends StatelessWidget {
  const PrayerDetailScreen({super.key, required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _DetailBar(prayer: prayer),
              Expanded(
                child: StreamBuilder<List<PrayerResponse>>(
                  stream: PrayerResponsesRepository.instance.watch(prayer.id),
                  builder: (context, snap) {
                    final responses = (snap.data ?? const <PrayerResponse>[])
                        .where((r) => !BlockService.instance.isBlocked(r.uid))
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _PrayerHeaderCard(prayer: prayer),
                        const SizedBox(height: 20),
                        RuleLabel(
                          prayer.isTestimony ? 'Responses' : 'Responses',
                        ),
                        const SizedBox(height: 16),
                        if (snap.hasError)
                          _Note('The responses are resting. Try again shortly.')
                        else if (!snap.hasData)
                          _Note('Gathering responses…')
                        else if (responses.isEmpty)
                          _Note(
                            prayer.isTestimony
                                ? 'Be the first to give thanks with them.'
                                : 'Be the first to pray a word over this request.',
                          )
                        else
                          for (final r in responses) ...[
                            _ResponseTile(prayerId: prayer.id, response: r),
                            const SizedBox(height: 12),
                          ],
                      ],
                    );
                  },
                ),
              ),
              _Composer(prayer: prayer),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBar extends StatelessWidget {
  const _DetailBar({required this.prayer});
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final mine = prayer.authorUid == AuthService.instance.uid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                PhosphorIconsRegular.arrowLeft,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            prayer.isTestimony ? 'TESTIMONY' : 'PRAYER REQUEST',
            style: AppType.mono(10, color: AppColors.ink),
          ),
          const Spacer(),
          if (!mine)
            MoreButton(
              actions: [
                ContentAction(
                  icon: PhosphorIconsRegular.flag,
                  label: 'Report',
                  onTap: () => presentReportSheet(
                    context,
                    targetType: 'prayer',
                    targetId: prayer.id,
                    targetPath: 'prayers/${prayer.id}',
                    reportedUid: prayer.authorUid,
                    label: prayer.isTestimony
                        ? 'this testimony'
                        : 'this prayer',
                  ),
                ),
                blockUserAction(context, uid: prayer.authorUid),
              ],
            ),
        ],
      ),
    );
  }
}

class _PrayerHeaderCard extends StatelessWidget {
  const _PrayerHeaderCard({required this.prayer});
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final p = prayer;
    final markerColor = p.isTestimony || p.answered
        ? AppColors.green
        : AppColors.accent;

    return BwCard(
      dashed: p.isTestimony || p.answered,
      borderColor: p.isTestimony || p.answered
          ? AppColors.green
          : AppColors.ink,
      color: p.isTestimony ? AppColors.paperBright : AppColors.paperDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                p.author.toUpperCase(),
                style: AppType.mono(10, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              Text('· ${agoLabel(p.createdAt)}', style: AppType.mono(9)),
              const Spacer(),
              if (p.isTestimony) ...[
                Icon(
                  PhosphorIconsRegular.check,
                  size: 12,
                  color: AppColors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'TESTIMONY',
                  style: AppType.mono(
                    9,
                    color: AppColors.green,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
              if (!p.isTestimony && p.answered) ...[
                Icon(
                  PhosphorIconsRegular.check,
                  size: 12,
                  color: AppColors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'ANSWERED',
                  style: AppType.mono(
                    9,
                    color: AppColors.green,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(p.body, style: AppType.body(17, height: 1.55)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 6, height: 6, color: markerColor),
              const SizedBox(width: 7),
              Text(
                p.isTestimony ? 'WONDER SHARED' : '${p.prayingCount} PRAYING',
                style: AppType.mono(9, color: markerColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          text,
          style: AppType.flourish(15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Response tiles ──────────────────────────────────────────────────────────

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({required this.prayerId, required this.response});
  final String prayerId;
  final PrayerResponse response;

  bool get _mine => response.uid == AuthService.instance.uid;

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDestructive(
      context,
      title: response.isAudio ? 'Delete this recording?' : 'Delete this reply?',
      body: 'This removes it for everyone. It cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await PrayerResponsesRepository.instance.delete(prayerId, response);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'Couldn’t delete that. Try again.',
            style: AppType.body(15, color: AppColors.paperBright),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = response;
    return BwCard(
      color: AppColors.paperBright,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.author.toUpperCase(),
                style: AppType.mono(9, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              Text('· ${agoLabel(r.createdAt)}', style: AppType.mono(8)),
              const Spacer(),
              MoreButton(
                actions: _mine
                    ? [
                        ContentAction(
                          icon: PhosphorIconsRegular.trash,
                          label: 'Delete',
                          danger: true,
                          onTap: () => _delete(context),
                        ),
                      ]
                    : [
                        ContentAction(
                          icon: PhosphorIconsRegular.flag,
                          label: 'Report',
                          onTap: () => presentReportSheet(
                            context,
                            targetType: 'prayer_response',
                            targetId: r.id,
                            targetPath: 'prayers/$prayerId/responses/${r.id}',
                            reportedUid: r.uid,
                            label: 'this reply',
                          ),
                        ),
                        blockUserAction(context, uid: r.uid),
                      ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (r.isAudio)
            _AudioPlayerBar(url: r.audioUrl, durationMs: r.durationMs)
          else
            Text(r.text ?? '', style: AppType.body(15, height: 1.5)),
        ],
      ),
    );
  }
}

/// A play/pause control for an audio response, with its duration.
class _AudioPlayerBar extends StatefulWidget {
  const _AudioPlayerBar({required this.url, required this.durationMs});
  final String? url;
  final int? durationMs;

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.url;
    if (url == null || url.isEmpty) return;

    if (!_ready) {
      setState(() => _loading = true);
      try {
        await _player.setUrl(url);
        _ready = true;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }

    final playing = _player.playing;
    final ended = _player.processingState == ProcessingState.completed;
    if (playing) {
      await _player.pause();
    } else {
      if (ended) await _player.seek(Duration.zero);
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final ended = state?.processingState == ProcessingState.completed;
        final showPause = playing && !ended;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _loading ? null : _toggle,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1),
                  color: AppColors.paperDeep,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.4,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    : Icon(
                        showPause
                            ? PhosphorIconsRegular.pause
                            : PhosphorIconsRegular.play,
                        size: 16,
                        color: AppColors.accent,
                      ),
              ),
              const SizedBox(width: 12),
              Text('SPOKEN PRAYER', style: AppType.mono(9)),
              const Spacer(),
              if (widget.durationMs != null)
                Text(
                  formatDuration(widget.durationMs),
                  style: AppType.mono(9, color: AppColors.inkFaded),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Composer ────────────────────────────────────────────────────────────────

class _Composer extends StatefulWidget {
  const _Composer({required this.prayer});
  final Prayer prayer;

  @override
  State<_Composer> createState() => _ComposerState();
}

enum _RecState { idle, recording, recorded }

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  final _encouragement = EncouragementWriter();

  _RecState _rec = _RecState.idle;
  bool _sending = false;
  bool _drafting = false;
  bool _permissionDenied = false;

  String? _recordedPath;
  int _recordedMs = 0;
  DateTime? _startedAt;
  Timer? _ticker;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _controller.dispose();
    _ticker?.cancel();
    _recorder.dispose();
    _encouragement.close();
    super.dispose();
  }

  // ── Text ──

  Future<void> _draftEncouragement() async {
    if (_drafting || _sending) return;
    if (!await requireAccount(
      context,
      action: widget.prayer.isTestimony
          ? 'encourage a testimony'
          : 'encourage a prayer',
    )) {
      return;
    }
    setState(() => _drafting = true);
    try {
      final text = _encouragement.isAvailable
          ? await _encouragement.draft(
              postBody: widget.prayer.body,
              testimony: widget.prayer.isTestimony,
            )
          : _fallbackDraft(widget.prayer.isTestimony);
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    } catch (_) {
      final text = _fallbackDraft(widget.prayer.isTestimony);
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    }
    if (mounted) setState(() => _drafting = false);
  }

  static String _fallbackDraft(bool testimony) {
    if (testimony) {
      return 'Thank you for sharing this. I’m giving thanks with you for God’s goodness and praying this strengthens your faith for what is ahead.';
    }
    return 'I’m praying with you. May the Lord give you peace, wisdom, and strength for today, and remind you that you are not carrying this alone.';
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await requireAccount(
      context,
      action: widget.prayer.isTestimony
          ? 'respond to a testimony'
          : 'respond to a prayer',
    )) {
      return;
    }
    setState(() => _sending = true);
    try {
      await PrayerResponsesRepository.instance.addText(widget.prayer.id, text);
      _controller.clear();
    } catch (_) {
      // Leave the text in place so nothing is lost.
    }
    if (mounted) setState(() => _sending = false);
  }

  // ── Recording ──

  Future<void> _startRecording() async {
    if (!await requireAccount(
      context,
      action: widget.prayer.isTestimony
          ? 'respond to a testimony'
          : 'respond to a prayer',
    )) {
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    try {
      final dir = Directory.systemTemp;
      final path =
          '${dir.path}/bw_prayer_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _startedAt = DateTime.now();
      _elapsedMs = 0;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (_startedAt == null) return;
        setState(() {
          _elapsedMs = DateTime.now().difference(_startedAt!).inMilliseconds;
        });
      });
      if (mounted) {
        setState(() {
          _permissionDenied = false;
          _recordedPath = path;
          _rec = _RecState.recording;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _rec = _RecState.idle);
    }
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final ms = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    try {
      final path = await _recorder.stop();
      if (path != null) _recordedPath = path;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _recordedMs = ms;
        _rec = _RecState.recorded;
      });
    }
  }

  Future<void> _discardRecording() async {
    final path = _recordedPath;
    _recordedPath = null;
    _recordedMs = 0;
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    if (mounted) setState(() => _rec = _RecState.idle);
  }

  Future<void> _sendRecording() async {
    final path = _recordedPath;
    if (path == null || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await requireAccount(
      context,
      action: widget.prayer.isTestimony
          ? 'respond to a testimony'
          : 'respond to a prayer',
    )) {
      return;
    }
    setState(() => _sending = true);
    try {
      await PrayerResponsesRepository.instance.addAudio(
        widget.prayer.id,
        path,
        _recordedMs,
      );
      _recordedPath = null;
      _recordedMs = 0;
      if (mounted) setState(() => _rec = _RecState.idle);
    } catch (e) {
      // Keep the recording so it can be retried, and say what went wrong.
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'Couldn’t send your prayer: ${_friendlyError(e)}',
            style: AppType.body(15, color: AppColors.paperBright),
          ),
        ),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  /// Turn a raw exception into something a person can read.
  static String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('unauthorized') || s.contains('permission')) {
      return 'permission was denied. Make sure you’re signed in.';
    }
    if (s.contains('network') || s.contains('timeout')) {
      return 'the connection dropped. Try again.';
    }
    return 'please try again in a moment.';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: switch (_rec) {
        _RecState.recording => _buildRecording(),
        _RecState.recorded => _buildRecorded(),
        _RecState.idle => _buildIdle(),
      },
    );
  }

  Widget _buildIdle() {
    final hint = widget.prayer.isTestimony ? 'Give thanks…' : 'Pray a word…';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_permissionDenied) ...[
          _PermissionNote(onSettings: openAppSettings),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1),
                  color: AppColors.paperBright,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 400,
                  cursorColor: AppColors.accent,
                  style: AppType.body(15, color: AppColors.ink),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    hintText: hint,
                    hintStyle: AppType.flourish(14, color: AppColors.inkGhost),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: PhosphorIconsRegular.microphone,
              onTap: _sending || _drafting ? null : _startRecording,
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: PhosphorIconsRegular.sparkle,
              onTap: _sending || _drafting ? null : _draftEncouragement,
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: PhosphorIconsRegular.paperPlaneRight,
              accent: true,
              onTap: _sending || _drafting ? null : _sendText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecording() {
    return Row(
      children: [
        Container(width: 8, height: 8, color: AppColors.accent),
        const SizedBox(width: 10),
        Text('RECORDING', style: AppType.mono(10, color: AppColors.accent)),
        const SizedBox(width: 8),
        Text(
          formatDuration(_elapsedMs),
          style: AppType.mono(10, color: AppColors.inkFaded),
        ),
        const Spacer(),
        _SquareIconButton(
          icon: PhosphorIconsRegular.stop,
          accent: true,
          onTap: _stopRecording,
        ),
      ],
    );
  }

  Widget _buildRecorded() {
    return Row(
      children: [
        Icon(PhosphorIconsRegular.waveform, size: 16, color: AppColors.ink),
        const SizedBox(width: 10),
        Text('RECORDING READY', style: AppType.mono(10, color: AppColors.ink)),
        const SizedBox(width: 8),
        Text(
          formatDuration(_recordedMs),
          style: AppType.mono(10, color: AppColors.inkFaded),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _sending ? null : _discardRecording,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              'DISCARD',
              style: AppType.mono(10, color: AppColors.inkFaded),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _SquareIconButton(
          icon: PhosphorIconsRegular.paperPlaneRight,
          accent: true,
          onTap: _sending ? null : _sendRecording,
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: AppColors.paperBright,
        ),
        child: Icon(
          icon,
          size: 18,
          color: !enabled
              ? AppColors.inkGhost
              : (accent ? AppColors.accent : AppColors.ink),
        ),
      ),
    );
  }
}

class _PermissionNote extends StatelessWidget {
  const _PermissionNote({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      dashed: true,
      color: AppColors.paperDeep,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.microphoneSlash,
            size: 16,
            color: AppColors.inkFaded,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Microphone access is needed to record a spoken prayer.',
                  style: AppType.body(14, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSettings,
                  child: Text(
                    'OPEN SETTINGS',
                    style: AppType.mono(9, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
