import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/block_service.dart';
import '../../services/firebase/reports_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';

const _reasons = <String>[
  'Harmful or abusive',
  'Hate or harassment',
  'Sexual or explicit content',
  'Spam or scam',
  'Self-harm or crisis',
  'Something else',
];

/// Site-wide report sheet. Works for any content type — pass a coarse
/// [targetType] ('prayer', 'prayer_response', 'room', 'room_message', 'user'),
/// the [targetId], and optionally the Firestore [targetPath] and the
/// [reportedUid] of the author so moderators can act quickly.
Future<void> presentReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String targetPath = '',
  String reportedUid = '',
  String label = 'this',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _ReportSheet(
      targetType: targetType,
      targetId: targetId,
      targetPath: targetPath,
      reportedUid: reportedUid,
      label: label,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.targetPath,
    required this.reportedUid,
    required this.label,
  });

  final String targetType;
  final String targetId;
  final String targetPath;
  final String reportedUid;
  final String label;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    try {
      await ReportsRepository.instance.submit(
        targetType: widget.targetType,
        targetId: widget.targetId,
        targetPath: widget.targetPath,
        reportedUid: widget.reportedUid,
        reason: _reason!,
        details: _details.text,
      );
      // Reporting someone also blocks them, both ways.
      final blocked = widget.reportedUid.isNotEmpty;
      if (blocked) {
        await BlockService.instance.block(widget.reportedUid);
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
            blocked
                ? 'Reported. You won’t see each other anymore.'
                : 'Thank you. Our team will review this.',
            style: AppType.body(15, color: AppColors.paperBright)),
      ));
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.ink,
        content: Text('Couldn’t send the report. Please try again.',
            style: AppType.body(15, color: AppColors.paperBright)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REPORT', style: AppType.mono(9, color: AppColors.accent)),
          const SizedBox(height: 6),
          Text('Report ${widget.label}', style: AppType.display(24)),
          const SizedBox(height: 4),
          Text('Tell us what’s wrong. Reports are private.',
              style: AppType.flourish(15)),
          const SizedBox(height: 16),
          for (final r in _reasons) _option(r),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 1),
              color: AppColors.paperBright,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _details,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              cursorColor: AppColors.accent,
              style: AppType.body(15, color: AppColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Add any details (optional)',
                hintStyle: AppType.flourish(14, color: AppColors.inkGhost),
              ),
            ),
          ),
          const SizedBox(height: 14),
          BwButton(
            label: _sending ? 'Sending…' : 'Submit report',
            expand: true,
            onPressed: _reason == null || _sending ? null : _submit,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _option(String reason) {
    final selected = _reason == reason;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _reason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: selected ? AppColors.ink : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsRegular.checkCircle
                  : PhosphorIconsRegular.circle,
              size: 16,
              color: selected ? AppColors.paperBright : AppColors.inkFaded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(reason,
                  style: AppType.body(16,
                      color: selected
                          ? AppColors.paperBright
                          : AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
