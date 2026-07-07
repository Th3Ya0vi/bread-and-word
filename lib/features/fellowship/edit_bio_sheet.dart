import 'package:flutter/material.dart';

import '../../services/firebase/fellowship_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/section_header.dart';

/// Paper-styled modal sheet for editing your fellowship bio — a single line
/// others see on your public profile.
Future<void> editBio(BuildContext context, {String initial = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _EditBio(initial: initial),
  );
}

class _EditBio extends StatefulWidget {
  const _EditBio({required this.initial});
  final String initial;

  @override
  State<_EditBio> createState() => _EditBioState();
}

class _EditBioState extends State<_EditBio> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FellowshipRepository.instance.updateBio(_controller.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Your Profile',
            title: 'A Word About You',
            subline: 'A line those you walk with will see.',
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
              minLines: 2,
              maxLines: 3,
              maxLength: 160,
              cursorColor: AppColors.accent,
              style: AppType.body(16, color: AppColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterStyle: AppType.mono(9),
                hintText: 'Walking by faith, one day at a time…',
                hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
              ),
            ),
          ),
          const SizedBox(height: 14),
          BwButton(
            label: _saving ? 'Saving…' : 'Save',
            expand: true,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
