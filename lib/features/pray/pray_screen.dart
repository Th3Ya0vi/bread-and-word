import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/firebase/block_service.dart';
import '../../services/firebase/models.dart';
import '../../services/firebase/prayers_repository.dart';
import '../auth/require_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../../services/firebase/prayer_response_models.dart';
import '../../services/firebase/prayer_responses_repository.dart';
import '../../services/reading_progress.dart';
import '../circles/circles_screen.dart';
import 'compose_prayer_sheet.dart';
import 'prayer_detail_screen.dart';

/// The prayer wall, live from Firestore. Members share requests; the community
/// prays. "Praying now" markers use accent red; answered prayers turn green.
class PrayScreen extends StatefulWidget {
  const PrayScreen({super.key});

  @override
  State<PrayScreen> createState() => _PrayScreenState();
}

class _PrayScreenState extends State<PrayScreen> {
  PrayerKind _kind = PrayerKind.prayer;

  @override
  Widget build(BuildContext context) {
    final showingTestimonies = _kind == PrayerKind.testimony;
    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: BlockService.instance.blocked,
          builder: (context, blocked, _) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dailyPrayerCard(),
                      const SizedBox(height: 24),
                      const SectionHeader(
                        eyebrow: 'The Prayer Wall',
                        title: 'Bear One Another',
                        subline: 'Share a request, or tell what God has done.',
                      ),
                      const SizedBox(height: 16),
                      BwButton(
                        label: 'Open your circles',
                        icon: PhosphorIconsRegular.usersThree,
                        expand: true,
                        primary: false,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CirclesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WallSwitch(
                        kind: _kind,
                        onChanged: (kind) => setState(() => _kind = kind),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BwButton(
                              label: 'Prayer request',
                              icon: PhosphorIconsRegular.plus,
                              expand: true,
                              onPressed: () => composePrayer(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BwButton(
                              label: 'Testimony',
                              icon: PhosphorIconsRegular.check,
                              expand: true,
                              primary: false,
                              onPressed: () => composePrayer(
                                context,
                                kind: PrayerKind.testimony,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<Prayer>>(
                stream: PrayersRepository.instance.watch(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _message('The wall is resting. Try again shortly.');
                  }
                  if (!snap.hasData) {
                    return _message(
                      showingTestimonies
                          ? 'Gathering testimonies…'
                          : 'Gathering today’s prayers…',
                    );
                  }
                  final prayers = snap.data!
                      .where((p) => !blocked.contains(p.authorUid))
                      .where(
                        (p) => _kind == PrayerKind.testimony
                            ? p.isTestimony || p.answered
                            : !p.isTestimony && !p.answered,
                      )
                      .toList();
                  if (prayers.isEmpty) {
                    return _message(
                      showingTestimonies
                          ? 'Be the first to share what God has done.'
                          : 'Be the first to share a request this morning.',
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList.separated(
                      itemCount: prayers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _PrayerCard(prayer: prayers[i]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A classic prayer for today, chosen by the day of the year.
  static const _dailyPrayers = [
    (
      'Prayer of St. Francis',
      'Lord, make me an instrument of your peace. Where there is hatred, let '
          'me sow love; where there is injury, pardon; where there is doubt, '
          'faith; where there is despair, hope.',
    ),
    (
      'A Morning Prayer',
      'O Lord, let me not live to be useless. As the day begins, set my heart '
          'toward you, that all I do may be done in love and to your glory.',
    ),
    (
      'For a Quiet Trust',
      'Be still, my soul, and rest in him. Lord, quiet the noise within me, '
          'and let me trust that you hold this day, and me, in your hands.',
    ),
    (
      'A Prayer for Mercy',
      'Lord Jesus Christ, Son of God, have mercy on me, a sinner. Wash me, '
          'lead me, and keep me close to you this day.',
    ),
    (
      'For Those We Carry',
      'Father, I lift to you the ones on my heart today. Comfort the hurting, '
          'steady the weary, and let your nearness be felt by all who wait.',
    ),
    (
      'An Evening Prayer',
      'Lighten our darkness, Lord, and by your great mercy defend us from all '
          'the perils and dangers of this night, for the love of your Son.',
    ),
    (
      'A Prayer of Surrender',
      'Take, Lord, and receive all that I am and all that I have. You have '
          'given it to me; to you I return it. Your love and grace are enough.',
    ),
  ];

  Widget _dailyPrayerCard() {
    final day = ReadingProgress.easternDayOfYear() - 1;
    final p = _dailyPrayers[day % _dailyPrayers.length];
    return BwCard(
      color: AppColors.paperBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.handsPraying,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 7),
              Text('PRAYER OF THE DAY', style: AppType.eyebrow()),
            ],
          ),
          const SizedBox(height: 10),
          Text(p.$1, style: AppType.display(22)),
          const SizedBox(height: 8),
          Text(p.$2, style: AppType.body(16, height: 1.55, italic: true)),
          const SizedBox(height: 12),
          Text('— PRAY IT SLOWLY', style: AppType.mono(9)),
        ],
      ),
    );
  }

  Widget _message(String text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Center(
        child: Text(
          text,
          style: AppType.flourish(16),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _WallSwitch extends StatelessWidget {
  const _WallSwitch({required this.kind, required this.onChanged});

  final PrayerKind kind;
  final ValueChanged<PrayerKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1),
        color: AppColors.paperBright,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _WallSwitchItem(
            label: 'Prayer Requests',
            active: kind == PrayerKind.prayer,
            onTap: () => onChanged(PrayerKind.prayer),
          ),
          _WallSwitchItem(
            label: 'Testimonies',
            active: kind == PrayerKind.testimony,
            onTap: () => onChanged(PrayerKind.testimony),
          ),
        ],
      ),
    );
  }
}

class _WallSwitchItem extends StatelessWidget {
  const _WallSwitchItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: active ? AppColors.ink : Colors.transparent,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppType.mono(
                10,
                color: active ? AppColors.paperBright : AppColors.inkFaded,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.prayer});
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final p = prayer;
    final isAuthor = p.authorUid == AuthService.instance.uid;
    final markerColor = p.isTestimony || p.answered
        ? AppColors.green
        : AppColors.accent;

    return BwCard(
      dashed: p.isTestimony || p.answered,
      borderColor: p.isTestimony || p.answered
          ? AppColors.green
          : AppColors.ink,
      color: p.isTestimony ? AppColors.paperBright : AppColors.paperDeep,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PrayerDetailScreen(prayer: p)),
      ),
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
          Text(p.body, style: AppType.body(16, height: 1.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 6, height: 6, color: markerColor),
              const SizedBox(width: 7),
              Text(
                p.isTestimony ? 'WONDER SHARED' : '${p.prayingCount} PRAYING',
                style: AppType.mono(9, color: markerColor),
              ),
              _ResponseCount(prayerId: p.id),
              const Spacer(),
              if (p.isTestimony)
                Text(
                  'RESPOND',
                  style: AppType.mono(
                    10,
                    color: AppColors.green,
                    weight: FontWeight.w600,
                  ),
                )
              else if (p.answered)
                const SizedBox.shrink()
              else if (isAuthor)
                GestureDetector(
                  onTap: () =>
                      PrayersRepository.instance.markAnsweredAsTestimony(p.id),
                  child: Text(
                    'MAKE TESTIMONY',
                    style: AppType.mono(
                      10,
                      color: AppColors.green,
                      weight: FontWeight.w600,
                    ),
                  ),
                )
              else
                _PrayButton(prayerId: p.id),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small "· N RESPONSES" marker pulled live from the responses subcollection.
class _ResponseCount extends StatelessWidget {
  const _ResponseCount({required this.prayerId});
  final String prayerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrayerResponse>>(
      stream: PrayerResponsesRepository.instance.watch(prayerId),
      builder: (context, snap) {
        final n = snap.data?.length ?? 0;
        if (n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            '· $n ${n == 1 ? 'RESPONSE' : 'RESPONSES'}',
            style: AppType.mono(9, color: AppColors.inkFaded),
          ),
        );
      },
    );
  }
}

class _PrayButton extends StatelessWidget {
  const _PrayButton({required this.prayerId});
  final String prayerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: PrayersRepository.instance.watchPrayed(prayerId),
      builder: (context, snap) {
        final prayed = snap.data ?? false;
        return GestureDetector(
          onTap: prayed
              ? null
              : () async {
                  if (await requireAccount(
                    context,
                    action: 'pray for others',
                  )) {
                    await PrayersRepository.instance.pray(prayerId);
                  }
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prayed) ...[
                Icon(
                  PhosphorIconsRegular.check,
                  size: 12,
                  color: AppColors.inkFaded,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                prayed ? 'PRAYED' : 'I PRAYED',
                style: AppType.mono(
                  10,
                  color: prayed ? AppColors.inkFaded : AppColors.accent,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
