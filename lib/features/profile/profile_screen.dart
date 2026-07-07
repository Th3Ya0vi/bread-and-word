import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/profile_prefs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../auth/auth_sheet.dart';
import '../fellowship/fellowship_feed_screen.dart';
import '../fellowship/public_profile_screen.dart';
import 'settings_screen.dart';

/// "Me" — the member's journey, kept simple. Account actions (sign out,
/// version, anonymity, delete) live behind the Settings gear. Tap your name
/// to see and edit how others meet you.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int get _journeyDay {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }

  void _openPublicProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(uid: AuthService.instance.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<User?>(
          stream: AuthService.instance.authChanges(),
          builder: (context, _) {
            final auth = AuthService.instance;
            final isMember = auth.isMember;
            final name = auth.displayName;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(PhosphorIconsRegular.gearSix,
                        color: AppColors.ink),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
                // Identity — tap (members) to view & edit your public profile.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isMember ? () => _openPublicProfile(context) : null,
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.ink, width: 1),
                            color: AppColors.paperBright,
                          ),
                          child: Icon(PhosphorIconsRegular.cross,
                              size: 34, color: AppColors.accent),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: AppType.display(26)),
                        const SizedBox(height: 2),
                        Text(
                          isMember ? 'MEMBER' : 'GUEST · JUST LOOKING',
                          style: AppType.mono(9,
                              color: isMember
                                  ? AppColors.accent
                                  : AppColors.inkFaded),
                        ),
                        if (isMember) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('VIEW MY PROFILE',
                                  style: AppType.mono(9,
                                      color: AppColors.inkFaded)),
                              const SizedBox(width: 4),
                              const Icon(PhosphorIconsRegular.arrowRight,
                                  size: 10, color: AppColors.inkFaded),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BwCard(
                  color: AppColors.paperBright,
                  child: Row(
                    children: [
                      Text('$_journeyDay',
                          style:
                              AppType.display(40, color: AppColors.accent)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('JOURNEY DAY', style: AppType.eyebrow()),
                            const SizedBox(height: 2),
                            Text('Your daily walk through Scripture',
                                style: AppType.flourish(15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Editable note to self.
                ValueListenableBuilder<String>(
                  valueListenable: ProfilePrefs.instance.noteToSelf,
                  builder: (context, note, _) => BwCard(
                    dashed: true,
                    onTap: () => _editNote(context, note),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('A NOTE TO SELF', style: AppType.mono(9)),
                            const Spacer(),
                            const Icon(PhosphorIconsRegular.pencilSimple,
                                size: 13, color: AppColors.inkFaded),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(note, style: AppType.typewriter(17)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isMember)
                  BwButton(
                    label: 'Create your account',
                    expand: true,
                    onPressed: () => presentAuthSheet(context,
                        reason: 'Save your journey and join the community.'),
                  )
                else
                  _navTile(
                    context,
                    icon: PhosphorIconsRegular.users,
                    title: 'Fellowship feed',
                    subtitle: 'Prayers from those you walk with',
                    builder: (_) => const FellowshipFeedScreen(),
                  ),
                const SizedBox(height: 12),
                BwButton(
                  label: 'Give',
                  primary: false,
                  expand: true,
                  onPressed: () => launchUrl(
                    Uri.parse('https://breadandword.com/give'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required WidgetBuilder builder,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: builder),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: AppColors.paperDeep,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.body(17, color: AppColors.ink)),
                  if (subtitle != null)
                    Text(subtitle, style: AppType.flourish(14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('→', style: AppType.display(18, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paperBright,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A note to self', style: AppType.display(24)),
            const SizedBox(height: 4),
            Text('A verse or line to keep close — only you see it.',
                style: AppType.flourish(15)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 1),
                color: AppColors.paper,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 160,
                style: AppType.typewriter(17),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 16),
            BwButton(
              label: 'Save',
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(controller.text),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      await ProfilePrefs.instance.setNote(saved);
    }
  }
}
