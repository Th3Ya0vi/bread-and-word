import 'package:flutter/material.dart';

import '../../services/firebase/models.dart';
import '../../services/firebase/prayers_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/section_header.dart';

/// Paper-styled modal sheet for sharing a prayer request.
Future<void> composePrayer(
  BuildContext context, {
  PrayerKind kind = PrayerKind.prayer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _ComposePrayer(kind: kind),
  );
}

class _ComposePrayer extends StatefulWidget {
  const _ComposePrayer({required this.kind});

  final PrayerKind kind;

  @override
  State<_ComposePrayer> createState() => _ComposePrayerState();
}

class _ComposePrayerState extends State<_ComposePrayer> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await PrayersRepository.instance.add(
        body: text,
        anonymous: _anonymous,
        kind: widget.kind,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isTestimony = widget.kind == PrayerKind.testimony;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: isTestimony ? 'Share a Testimony' : 'Share a Request',
            title: isTestimony ? 'Tell What God Has Done' : 'Lift It Up',
            subline: isTestimony
                ? 'Give thanks and strengthen someone’s faith.'
                : 'The community will pray with you.',
            titleSize: 24,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 1),
              color: AppColors.paperBright,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              cursorColor: AppColors.accent,
              style: AppType.body(16, color: AppColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: isTestimony
                    ? 'What wonder has God done?'
                    : 'What shall we pray for?',
                hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _anonymous = !_anonymous),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _anonymous ? AppColors.ink : Colors.transparent,
                    border: Border.all(color: AppColors.ink, width: 1),
                  ),
                  child: _anonymous
                      ? const Icon(
                          Icons.check,
                          size: 13,
                          color: AppColors.paper,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text('POST ANONYMOUSLY', style: AppType.mono(10)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          BwButton(
            label: _sending
                ? 'Sharing…'
                : (isTestimony
                      ? 'Share your testimony'
                      : 'Share with the community'),
            expand: true,
            onPressed: _sending ? null : _share,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
