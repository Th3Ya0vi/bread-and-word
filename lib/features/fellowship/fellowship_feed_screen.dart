import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/block_service.dart';
import '../../services/firebase/fellowship_repository.dart';
import '../../services/firebase/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';

/// The fellowship feed — prayers from those you walk with (people you follow).
class FellowshipFeedScreen extends StatelessWidget {
  const FellowshipFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SectionHeader(
                  eyebrow: 'Fellowship',
                  title: 'Those You Walk With',
                  subline: 'Prayers from the people you follow.',
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Prayer>>(
                  stream:
                      FellowshipRepository.instance.watchFellowshipPrayers(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _message(
                          'Fellowship is resting. Try again shortly.');
                    }
                    if (!snap.hasData) {
                      return _message('Gathering their prayers…');
                    }
                    final prayers = snap.data!
                        .where((p) =>
                            !BlockService.instance.isBlocked(p.authorUid))
                        .toList();
                    if (prayers.isEmpty) {
                      return _message(
                          'Follow others to see their prayers here.');
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      itemCount: prayers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) =>
                          FellowshipPrayerCard(prayer: prayers[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft,
                color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text('Fellowship', style: AppType.display(24)),
        ],
      ),
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
        child: Center(
          child: Text(text,
              style: AppType.flourish(16), textAlign: TextAlign.center),
        ),
      );
}

/// A simplified, read-only prayer card for the fellowship feed — same visual
/// language as the prayer wall, without the praying / answer actions.
class FellowshipPrayerCard extends StatelessWidget {
  const FellowshipPrayerCard({super.key, required this.prayer});
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final p = prayer;
    final markerColor = p.answered ? AppColors.green : AppColors.accent;
    return BwCard(
      dashed: p.answered,
      borderColor: p.answered ? AppColors.green : AppColors.ink,
      color: AppColors.paperDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.author.toUpperCase(),
                  style: AppType.mono(10, color: AppColors.ink)),
              const SizedBox(width: 8),
              Text('· ${agoLabel(p.createdAt)}', style: AppType.mono(9)),
              const Spacer(),
              if (p.answered) ...[
                Icon(PhosphorIconsRegular.check,
                    size: 12, color: AppColors.green),
                const SizedBox(width: 4),
                Text('ANSWERED',
                    style: AppType.mono(9,
                        color: AppColors.green, weight: FontWeight.w600)),
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
              Text('${p.prayingCount} PRAYING',
                  style: AppType.mono(9, color: markerColor)),
            ],
          ),
        ],
      ),
    );
  }
}
