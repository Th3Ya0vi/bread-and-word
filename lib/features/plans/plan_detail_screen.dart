import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/plans_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import 'plan_catalog.dart';
import 'plan_day_screen.dart';

/// A plan's overview: what it is, your progress, and the day-by-day index.
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<PlanProgress>(
            stream: PlansRepository.instance.watch(plan.id),
            builder: (context, snap) {
              final progress = snap.data ?? PlanProgress.empty;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _head(context, progress),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    sliver: SliverList.list(
                      children: [
                        const RuleLabel('The days'),
                        const SizedBox(height: 8),
                        for (var i = 0; i < plan.days.length; i++)
                          _DayRow(
                            plan: plan,
                            index: i,
                            done: progress.isDayDone(i),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _head(BuildContext context, PlanProgress progress) {
    final next = progress.nextDay(plan.length);
    final isNew = !progress.started;
    final complete = progress.isComplete(plan.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(PhosphorIconsRegular.arrowLeft,
                  color: AppColors.ink),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(plan.subtitle.toUpperCase(),
                  style: AppType.mono(9, color: AppColors.inkFaded)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(plan.title, style: AppType.display(34)),
        const SizedBox(height: 12),
        Text(plan.about, style: AppType.body(17, color: AppColors.inkSoft)),
        const SizedBox(height: 20),
        BwButton(
          label: complete
              ? 'Read again'
              : isNew
                  ? 'Begin · Day 1'
                  : 'Continue · Day ${next + 1}',
          icon: PhosphorIconsRegular.bookOpen,
          expand: true,
          onPressed: () => _openDay(context, complete ? 0 : next),
        ),
      ],
    );
  }

  void _openDay(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDayScreen(plan: plan, dayIndex: index),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.plan, required this.index, required this.done});
  final ReadingPlan plan;
  final int index;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final day = plan.days[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlanDayScreen(plan: plan, dayIndex: index),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.inkFaded, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Day number / completion mark.
            SizedBox(
              width: 30,
              child: done
                  ? const Icon(PhosphorIconsRegular.checkCircle,
                      size: 20, color: AppColors.green)
                  : Text('${index + 1}',
                      style: AppType.mono(13, color: AppColors.inkFaded)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.title,
                      style: AppType.body(17, color: AppColors.ink)),
                  Text(day.label.toUpperCase(),
                      style: AppType.mono(9, color: AppColors.inkFaded)),
                ],
              ),
            ),
            Text('→', style: AppType.display(16, color: AppColors.inkFaded)),
          ],
        ),
      ),
    );
  }
}
