import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The three-part section header from the design system:
/// 1. mono uppercase eyebrow (accent)
/// 2. DM Serif Display headline
/// 3. italic Old Standard TT subline
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subline,
    this.titleSize = 26,
  });

  final String eyebrow;
  final String title;
  final String? subline;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppType.eyebrow()),
        const SizedBox(height: 6),
        Text(title, style: AppType.display(titleSize)),
        if (subline != null) ...[
          const SizedBox(height: 4),
          Text(subline!, style: AppType.flourish(15)),
        ],
      ],
    );
  }
}

/// A 3px double rule — the major divider of the system.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key, this.color = AppColors.ink});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: color),
        const SizedBox(height: 2),
        Container(height: 1, color: color),
      ],
    );
  }
}

/// A labeled divider: ─── LABEL ───  (mono, faded).
class RuleLabel extends StatelessWidget {
  const RuleLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.inkFaded, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label.toUpperCase(), style: AppType.mono(9)),
        ),
        const Expanded(child: Divider(color: AppColors.inkFaded, height: 1)),
      ],
    );
  }
}
