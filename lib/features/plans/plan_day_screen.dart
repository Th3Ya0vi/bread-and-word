import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/firebase/models.dart';
import '../../services/firebase/plans_repository.dart';
import '../../services/firebase/rooms_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/paper_grain.dart';
import '../auth/require_account.dart';
import '../rooms/room_screen.dart';
import 'passage_view.dart';
import 'plan_catalog.dart';

/// One day of a plan: the passage, a reflection prompt, and two ways to
/// respond — mark it read, or open a live room to read it together.
class PlanDayScreen extends StatefulWidget {
  const PlanDayScreen({
    super.key,
    required this.plan,
    required this.dayIndex,
  });

  final ReadingPlan plan;
  final int dayIndex;

  @override
  State<PlanDayScreen> createState() => _PlanDayScreenState();
}

class _PlanDayScreenState extends State<PlanDayScreen> {
  bool _opening = false;

  ReadingPlan get plan => widget.plan;
  PlanDay get day => plan.days[widget.dayIndex];
  String get _dayLabel => 'Day ${widget.dayIndex + 1} · ${day.title}';

  @override
  Widget build(BuildContext context) {
    final hasNext = widget.dayIndex + 1 < plan.days.length;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _bar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                  children: [
                    Text('DAY ${widget.dayIndex + 1} OF ${plan.length}',
                        style: AppType.mono(9, color: AppColors.accent)),
                    const SizedBox(height: 6),
                    Text(day.title, style: AppType.display(30)),
                    const SizedBox(height: 4),
                    Text(plan.title, style: AppType.flourish(15)),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppColors.ink),
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.ink),
                    const SizedBox(height: 22),
                    PassageView(references: day.references),
                    if (day.prompt != null) ...[
                      const SizedBox(height: 26),
                      _prompt(day.prompt!),
                    ],
                    const SizedBox(height: 28),
                    // Read together — the Agora live-room tie-in.
                    BwButton(
                      label: _opening ? 'Opening room…' : 'Read this together',
                      icon: PhosphorIconsRegular.usersThree,
                      primary: false,
                      expand: true,
                      onPressed: _opening ? null : () => _readTogether(context),
                    ),
                    const SizedBox(height: 12),
                    // Mark complete.
                    StreamBuilder<PlanProgress>(
                      stream: PlansRepository.instance.watch(plan.id),
                      builder: (context, snap) {
                        final done = (snap.data ?? PlanProgress.empty)
                            .isDayDone(widget.dayIndex);
                        return BwButton(
                          label: done ? 'Marked as read ✓' : 'Mark as read',
                          icon: done
                              ? PhosphorIconsRegular.checkCircle
                              : PhosphorIconsRegular.check,
                          expand: true,
                          onPressed: () => _toggleDone(done, hasNext),
                        );
                      },
                    ),
                  ],
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
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft,
                color: AppColors.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(day.label,
                style: AppType.mono(10, color: AppColors.inkFaded)),
          ),
        ],
      ),
    );
  }

  Widget _prompt(String text) {
    return Container(
      width: double.infinity,
      color: AppColors.paperDeep,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TO SIT WITH', style: AppType.mono(9, color: AppColors.accent)),
          const SizedBox(height: 8),
          Text(text, style: AppType.flourish(18)),
        ],
      ),
    );
  }

  Future<void> _toggleDone(bool done, bool hasNext) async {
    final repo = PlansRepository.instance;
    if (done) {
      await repo.unmarkDay(plan.id, widget.dayIndex);
      return;
    }
    await repo.markDay(plan.id, widget.dayIndex);
    if (!mounted) return;
    // Gently offer the next day.
    if (hasNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          content: Text('Day ${widget.dayIndex + 1} complete. Well done.',
              style: AppType.body(15, color: AppColors.paperBright)),
          action: SnackBarAction(
            label: 'NEXT',
            textColor: AppColors.paperBright,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PlanDayScreen(
                      plan: plan, dayIndex: widget.dayIndex + 1),
                ),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          content: Text('You finished “${plan.title}.” Praise God.',
              style: AppType.body(15, color: AppColors.paperBright)),
        ),
      );
    }
  }

  /// Open a live audio room seeded with this plan day, so the passage shows in
  /// the room and people can read and pray it together.
  Future<void> _readTogether(BuildContext context) async {
    // Capture before any await so we never touch context across async gaps.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await requireAccount(context, action: 'read together')) return;
    if (!mounted) return;
    setState(() => _opening = true);
    try {
      final repo = RoomsRepository.instance;
      final roomId = await repo.create(
        title: '${plan.title} — ${day.title}',
        kind: 'Bible Study',
        blurb: 'Reading ${day.label} together.',
        planId: plan.id,
        planTitle: plan.title,
        planDayLabel: _dayLabel,
        planReferences: day.references,
      );
      final room = RoomDoc(
        id: roomId,
        title: '${plan.title} — ${day.title}',
        kind: 'Bible Study',
        blurb: 'Reading ${day.label} together.',
        hereNow: 0,
        createdBy: AuthService.instance.uid,
        planId: plan.id,
        planTitle: plan.title,
        planDayLabel: _dayLabel,
        planReferences: day.references,
      );
      if (!mounted) return;
      await navigator.push(
        MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('Could not open the room. Try again.',
              style: AppType.body(15, color: AppColors.paperBright)),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}
