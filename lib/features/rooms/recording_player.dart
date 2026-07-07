import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A compact, paper-styled in-app player for a room's session recording.
class RecordingPlayer extends StatefulWidget {
  const RecordingPlayer({super.key, required this.url});
  final String url;

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Text('RECORDING UNAVAILABLE', style: AppType.mono(9));
    }
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        final completed = snap.data?.processingState == ProcessingState.completed;
        return Row(
          children: [
            GestureDetector(
              onTap: !_ready
                  ? null
                  : () {
                      if (completed) {
                        _player.seek(Duration.zero);
                        _player.play();
                      } else if (playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.ink, width: 1),
                ),
                child: Icon(
                  playing
                      ? PhosphorIconsRegular.pause
                      : PhosphorIconsRegular.play,
                  size: 16,
                  color: AppColors.paperBright,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;
                  final frac = total.inMilliseconds == 0
                      ? 0.0
                      : (pos.inMilliseconds / total.inMilliseconds)
                          .clamp(0.0, 1.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3,
                        color: AppColors.paperDeep,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: frac,
                          child: Container(color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ready
                            ? '${_fmt(pos)} / ${_fmt(total)}'
                            : 'LOADING…',
                        style: AppType.mono(9, color: AppColors.inkFaded),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
