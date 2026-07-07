import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../features/today/today_screen.dart';
import '../features/pray/pray_screen.dart';
import '../features/rooms/rooms_screen.dart';
import '../features/bible/bible_screen.dart';
import '../features/profile/profile_screen.dart';

/// The five pillars of Bread & Word.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static final _tabs = <_TabSpec>[
    _TabSpec('Today', PhosphorIconsRegular.sun, const TodayScreen()),
    _TabSpec('Pray', PhosphorIconsRegular.handsPraying, const PrayScreen()),
    _TabSpec('Rooms', PhosphorIconsRegular.usersThree, const RoomsScreen()),
    _TabSpec('Bible', PhosphorIconsRegular.bookOpen, const BibleScreen()),
    _TabSpec('Me', PhosphorIconsRegular.user, const ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: _PaperNavBar(
        tabs: _tabs,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}

class _PaperNavBar extends StatelessWidget {
  const _PaperNavBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<_TabSpec> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paperBright,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3px double rule above the bar
            Container(height: 1, color: AppColors.ink),
            const SizedBox(height: 2),
            Container(height: 1, color: AppColors.ink),
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        spec: tabs[i],
                        active: i == index,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.inkFaded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sliding accent indicator above the active tab.
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: active ? 18 : 0,
            height: 2,
            color: AppColors.accent,
          ),
          const SizedBox(height: 6),
          AnimatedScale(
            scale: active ? 1.14 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(spec.icon, size: 21, color: color),
          ),
          const SizedBox(height: 5),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppType.mono(9, color: color,
                weight: active ? FontWeight.w600 : FontWeight.w400),
            child: Text(spec.label.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
