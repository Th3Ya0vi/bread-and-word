import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/models.dart';
import '../../services/firebase/block_service.dart';
import '../../services/firebase/rooms_repository.dart';
import '../../services/firebase/stage_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';
import 'compose_room_sheet.dart';
import 'recording_player.dart';
import 'room_screen.dart';
import 'room_share.dart';

/// Live rooms — true community in Christ. Members create rooms to pray
/// together or read the Bible together; a red marker means people are there now.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'Gather',
                      title: 'Rooms',
                      subline: 'Where two or three are gathered together.',
                    ),
                    const SizedBox(height: 16),
                    BwButton(
                      label: 'Open a room',
                      icon: PhosphorIconsRegular.plus,
                      expand: true,
                      onPressed: () async {
                        if (await requireAccount(context,
                            action: 'open a room')) {
                          if (context.mounted) composeRoom(context);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<RoomDoc>>(
              stream: RoomsRepository.instance.watch(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _message('Rooms are resting. Try again shortly.');
                }
                if (!snap.hasData) {
                  return _message('Finding rooms…');
                }
                final rooms = snap.data!
                    .where((r) => !BlockService.instance.isBlocked(r.createdBy))
                    .toList();
                if (rooms.isEmpty) {
                  return _message('No rooms yet. Open the first gathering.');
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverList.separated(
                    itemCount: rooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _RoomCard(room: rooms[i]),
                  ),
                );
              },
            ),
            // The member's own ended rooms — with recordings.
            StreamBuilder<List<RoomDoc>>(
              stream: RoomsRepository.instance.watchMyPastRooms(),
              builder: (context, snap) {
                final past = snap.data ?? const <RoomDoc>[];
                if (past.isEmpty) {
                  return const SliverPadding(padding: EdgeInsets.only(bottom: 40));
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverList.list(children: [
                    const RuleLabel('Your past gatherings'),
                    const SizedBox(height: 14),
                    for (final r in past) ...[
                      _PastRoomCard(room: r),
                      const SizedBox(height: 12),
                    ],
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Center(
            child: Text(text, style: AppType.flourish(16),
                textAlign: TextAlign.center),
          ),
        ),
      );
}

class _PastRoomCard extends StatelessWidget {
  const _PastRoomCard({required this.room});
  final RoomDoc room;

  @override
  Widget build(BuildContext context) {
    final hasRecording = room.recordingUrl.isNotEmpty;
    return BwCard(
      color: AppColors.paperDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(room.kind.toUpperCase(),
                  style: AppType.mono(9, color: AppColors.inkFaded)),
              const Spacer(),
              Text('ENDED · ${agoLabel(room.createdAt)}',
                  style: AppType.mono(9, color: AppColors.inkFaded)),
            ],
          ),
          const SizedBox(height: 8),
          Text(room.title, style: AppType.display(22)),
          const SizedBox(height: 12),
          if (hasRecording) ...[
            Text('SESSION RECORDING', style: AppType.mono(9, color: AppColors.accent)),
            const SizedBox(height: 8),
            RecordingPlayer(url: room.recordingUrl),
          ] else
            Text('NO RECORDING SAVED', style: AppType.mono(9)),
        ],
      ),
    );
  }
}

/// Open-duration · here-now · on-stage — shown on the card before entering.
class _RoomStatsRow extends StatelessWidget {
  const _RoomStatsRow({required this.room});
  final RoomDoc room;

  String _openFor() {
    final start = room.createdAt;
    if (start == null) return 'JUST OPENED';
    final d = DateTime.now().difference(start);
    if (d.inMinutes < 1) return 'JUST OPENED';
    if (d.inMinutes < 60) return 'OPEN ${d.inMinutes}M';
    return 'OPEN ${d.inHours}H ${d.inMinutes % 60}M';
  }

  Widget _stat(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkFaded),
          const SizedBox(width: 5),
          Text(label, style: AppType.mono(9, color: AppColors.inkFaded)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _stat(PhosphorIconsRegular.clock, _openFor()),
        const SizedBox(width: 14),
        StreamBuilder<int>(
          stream: RoomsRepository.instance.hereNow(room.id),
          builder: (context, snap) =>
              _stat(PhosphorIconsRegular.users, '${snap.data ?? 0} HERE'),
        ),
        const SizedBox(width: 14),
        StreamBuilder<List<StageMember>>(
          stream: RoomsRepository.instance.watchStage(room.id),
          builder: (context, snap) {
            final speakers =
                (snap.data ?? const <StageMember>[]).where((m) => m.isSpeaker);
            return _stat(
                PhosphorIconsRegular.microphoneStage, '${speakers.length} ON STAGE');
          },
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final RoomDoc room;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(room.kind.toUpperCase(),
                  style: AppType.mono(9, color: AppColors.inkFaded)),
              const Spacer(),
              StreamBuilder<int>(
                stream: RoomsRepository.instance.hereNow(room.id),
                builder: (context, snap) {
                  final here = snap.data ?? 0;
                  if (here <= 0) {
                    return Text('QUIET', style: AppType.mono(9));
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('LIVE · $here HERE NOW',
                          style: AppType.mono(9, color: AppColors.accent,
                              weight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(room.title, style: AppType.display(24)),
          if (room.blurb.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(room.blurb, style: AppType.body(16, color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 12),
          _RoomStatsRow(room: room),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => shareRoom(room),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.shareNetwork,
                        size: 14, color: AppColors.inkFaded),
                    const SizedBox(width: 6),
                    Text('SHARE',
                        style: AppType.mono(9, color: AppColors.inkFaded,
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text('ENTER',
                  style: AppType.mono(10, color: AppColors.ink,
                      weight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('→', style: AppType.display(18, color: AppColors.ink)),
            ],
          ),
        ],
      ),
    );
  }
}
