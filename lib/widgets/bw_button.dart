import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Rectangular buttons. Mono uppercase labels with letter-spacing.
/// No radius, no shadow. Primary inverts to accent red on press.
class BwButton extends StatefulWidget {
  const BwButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final bool expand;

  @override
  State<BwButton> createState() => _BwButtonState();
}

class _BwButtonState extends State<BwButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final Color bg;
    final Color fg;

    if (widget.primary) {
      bg = _pressed ? AppColors.accent : AppColors.ink;
      fg = AppColors.paperBright;
    } else {
      bg = _pressed ? AppColors.paperDeep : Colors.transparent;
      fg = AppColors.ink;
    }

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: enabled ? bg : AppColors.inkGhost.withValues(alpha: 0.25),
        border: Border.all(color: AppColors.ink, width: 1),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 16, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label.toUpperCase(),
            style: AppType.mono(11, color: fg, weight: FontWeight.w600),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: child,
    );
  }
}
