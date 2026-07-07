import 'package:flutter/material.dart';

import '../../services/firebase/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/section_header.dart';

/// Paper-styled sheet for changing your account name.
Future<void> editName(BuildContext context, {String initial = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _EditName(initial: initial),
  );
}

class _EditName extends StatefulWidget {
  const _EditName({required this.initial});
  final String initial;

  @override
  State<_EditName> createState() => _EditNameState();
}

class _EditNameState extends State<_EditName> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateName(name);
      navigator.pop();
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
            eyebrow: 'Your Account',
            title: 'Your Name',
            subline: 'The name others see across the community.',
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
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              cursorColor: AppColors.accent,
              style: AppType.body(17, color: AppColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Your name',
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
