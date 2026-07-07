import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/plans_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import 'plan_catalog.dart';
import 'plan_detail_screen.dart';

/// The reading-plan library — curated journeys through Scripture, read alone
/// or together in a live room.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(PhosphorIconsRegular.arrowLeft,
                            color: AppColors.ink),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: SectionHeader(
                          eyebrow: 'Journeys',
                          title: 'Reading Plans',
                          subline: 'A passage a day — alone or together.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverList.separated(
                  itemCount: kReadingPlans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _PlanCard(plan: kReadingPlans[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperBright,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Serif glyph mark in an inked square.
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 1),
                color: AppColors.paper,
              ),
              child: Text(plan.glyph,
                  style: AppType.display(28, color: AppColors.accent)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title, style: AppType.display(21)),
                  const SizedBox(height: 2),
                  Text(plan.subtitle.toUpperCase(),
                      style: AppType.mono(9, color: AppColors.inkFaded)),
                  const SizedBox(height: 8),
                  StreamBuilder<PlanProgress>(
                    stream: PlansRepository.instance.watch(plan.id),
                    builder: (context, snap) {
                      final p = snap.data ?? PlanProgress.empty;
                      if (!p.started) {
                        return Text('Not started',
                            style: AppType.flourish(14));
                      }
                      final done = p.completedDays.length;
                      final label = p.isComplete(plan.length)
                          ? 'Completed · all ${plan.length} days'
                          : 'In progress · $done of ${plan.length} days';
                      return Row(
                        children: [
                          Icon(
                            p.isComplete(plan.length)
                                ? PhosphorIconsRegular.checkCircle
                                : PhosphorIconsRegular.bookmarkSimple,
                            size: 13,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: 5),
                          Text(label.toUpperCase(),
                              style:
                                  AppType.mono(9, color: AppColors.green)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('→', style: AppType.display(20, color: AppColors.inkFaded)),
          ],
        ),
      ),
    );
  }
}
