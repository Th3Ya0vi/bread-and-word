import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/block_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A reusable "Block" menu action — hides you and [uid] from each other.
ContentAction blockUserAction(BuildContext context, {required String uid}) {
  return ContentAction(
    icon: PhosphorIconsRegular.prohibit,
    label: 'Block',
    danger: true,
    onTap: () async {
      final messenger = ScaffoldMessenger.of(context);
      await BlockService.instance.block(uid);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.ink,
        content: Text('Blocked. You won’t see each other anymore.',
            style: AppType.body(15, color: AppColors.paperBright)),
      ));
    },
  );
}

/// One row in a content "⋯" menu — e.g. Delete or Report.
class ContentAction {
  const ContentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// A small "⋯" button that opens a sheet of [actions]. Used across prayers,
/// responses, rooms, and profiles to keep moderation reachable everywhere.
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.actions, this.size = 18});

  final List<ContentAction> actions;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showContentActions(context, actions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Icon(PhosphorIconsRegular.dotsThree,
            size: size, color: AppColors.ink),
      ),
    );
  }
}

/// Present a paper-styled action sheet. Each action runs after the sheet closes.
Future<void> showContentActions(
  BuildContext context,
  List<ContentAction> actions,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(ctx).pop();
                  a.onTap();
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.ink, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(a.icon,
                          size: 18,
                          color:
                              a.danger ? AppColors.accent : AppColors.ink),
                      const SizedBox(width: 14),
                      Text(a.label,
                          style: AppType.body(16,
                              color: a.danger
                                  ? AppColors.accent
                                  : AppColors.ink)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A reusable destructive-confirm sheet. Returns true if confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
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
            Text(title, style: AppType.display(24)),
            const SizedBox(height: 4),
            Text(body, style: AppType.flourish(15)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                color: AppColors.accent,
                child: Text(confirmLabel.toUpperCase(),
                    style: AppType.mono(11,
                        color: AppColors.paperBright,
                        weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(border: Border.all(color: AppColors.ink)),
                child: Text('CANCEL',
                    style: AppType.mono(11, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}
