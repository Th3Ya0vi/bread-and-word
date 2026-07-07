import 'package:flutter/material.dart';

import '../../services/firebase/models.dart';
import '../../services/firebase/rooms_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/section_header.dart';
import 'room_screen.dart';

/// Paper-styled sheet for opening a new room. On success it drops the member
/// straight into the room they created.
Future<void> composeRoom(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => const _ComposeRoom(),
  );
}

class _ComposeRoom extends StatefulWidget {
  const _ComposeRoom();

  @override
  State<_ComposeRoom> createState() => _ComposeRoomState();
}

class _ComposeRoomState extends State<_ComposeRoom> {
  final _title = TextEditingController();
  final _blurb = TextEditingController();
  String _kind = 'Prayer';
  bool _creating = false;

  static const _kinds = ['Prayer', 'Bible Study'];

  @override
  void dispose() {
    _title.dispose();
    _blurb.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty || _creating) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _creating = true);
    try {
      final id = await RoomsRepository.instance.create(
        title: title,
        kind: _kind,
        blurb: _blurb.text,
      );
      if (!mounted) return;
      final room = RoomDocLite(id: id, title: title, kind: _kind,
          blurb: _blurb.text.trim());
      navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (_) => RoomScreen(room: room.toRoomDoc())),
      );
    } catch (e) {
      if (mounted) setState(() => _creating = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.ink,
        content: Text('Couldn’t open the room: ${_friendly(e)}',
            style: AppType.body(15, color: AppColors.paperBright)),
      ));
    }
  }

  String _friendly(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('unauthorized')) {
      return 'you may need to sign in first.';
    }
    return 'please try again.';
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
            eyebrow: 'Open a Room',
            title: 'Gather Others',
            subline: 'Pray together, or read the Word together.',
            titleSize: 24,
          ),
          const SizedBox(height: 16),
          _field(_title, 'Room name', autofocus: true),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final k in _kinds) ...[
                _KindChip(
                  label: k,
                  selected: _kind == k,
                  onTap: () => setState(() => _kind = k),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _field(_blurb, 'A short description (optional)'),
          const SizedBox(height: 18),
          BwButton(
            label: _creating ? 'Opening…' : 'Open the room',
            expand: true,
            onPressed: _creating ? null : _create,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool autofocus = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1),
        color: AppColors.paperBright,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: c,
        autofocus: autofocus,
        maxLength: 80,
        cursorColor: AppColors.accent,
        style: AppType.body(16, color: AppColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppType.mono(10,
              color: selected ? AppColors.paperBright : AppColors.ink,
              weight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Tiny helper to construct a RoomDoc for immediate navigation after create.
class RoomDocLite {
  RoomDocLite({
    required this.id,
    required this.title,
    required this.kind,
    required this.blurb,
  });
  final String id;
  final String title;
  final String kind;
  final String blurb;

  RoomDoc toRoomDoc() => RoomDoc(
        id: id,
        title: title,
        kind: kind,
        blurb: blurb,
        hereNow: 0,
        createdAt: DateTime.now(),
      );
}
