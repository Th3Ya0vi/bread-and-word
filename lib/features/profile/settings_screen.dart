import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/profile_prefs.dart';
import '../../services/youversion/versions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/auth_sheet.dart';
import '../bible/bible_reader_screen.dart';
import 'blocked_accounts_screen.dart';
import 'edit_name_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    _streakCard(),
                    const SizedBox(height: 24),
                    const RuleLabel('Preferences'),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: BiblePrefs.instance.versionId,
                      builder: (context, id, _) => _tile(
                        icon: PhosphorIconsRegular.bookOpen,
                        title: 'Bible version',
                        value: versionById(id).abbreviation,
                        onTap: () => presentVersionPicker(context),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: ProfilePrefs.instance.anonymous,
                      builder: (context, anon, _) => _toggleTile(
                        icon: PhosphorIconsRegular.maskHappy,
                        title: 'Appear anonymously',
                        subtitle:
                            'Show a pseudonym in prayers, rooms, and chat.',
                        value: anon,
                        onChanged: ProfilePrefs.instance.setAnonymous,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const RuleLabel('Account'),
                    const SizedBox(height: 12),
                    if (auth.isMember) ...[
                      _tile(
                        icon: PhosphorIconsRegular.userCircle,
                        title: 'Your name',
                        value: auth.accountName,
                        onTap: () async {
                          await editName(context, initial: auth.accountName);
                          if (mounted) setState(() {});
                        },
                      ),
                      _tile(
                        icon: PhosphorIconsRegular.signOut,
                        title: 'Sign out',
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ] else
                      _tile(
                        icon: PhosphorIconsRegular.userPlus,
                        title: 'Create an account',
                        onTap: () => presentAuthSheet(context),
                      ),
                    _tile(
                      icon: PhosphorIconsRegular.prohibit,
                      title: 'Blocked accounts',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockedAccountsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _tile(
                      icon: PhosphorIconsRegular.trash,
                      title: 'Delete my account',
                      danger: true,
                      onTap: _confirmDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft,
                color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text('Settings', style: AppType.display(24)),
        ],
      ),
    );
  }

  Widget _streakCard() {
    return ValueListenableBuilder<int>(
      valueListenable: ProfilePrefs.instance.streak,
      builder: (context, streak, _) {
        final day =
            DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
        return BwCard(
          color: AppColors.paperBright,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streak', style: AppType.display(44, color: AppColors.accent)),
                  Text('DAY STREAK', style: AppType.mono(9)),
                ],
              ),
              const SizedBox(width: 24),
              Container(width: 1, height: 44, color: AppColors.inkFaded),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$day', style: AppType.display(44, color: AppColors.ink)),
                  Text('JOURNEY DAY', style: AppType.mono(9)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? value,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    final color = danger ? AppColors.accent : AppColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: AppColors.paperDeep,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppType.body(17, color: color))),
            if (value != null)
              Text(value.toUpperCase(),
                  style: AppType.mono(10, color: AppColors.inkFaded)),
            const SizedBox(width: 8),
            Text('→', style: AppType.display(18, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppType.flourish(14)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Hard-edged switch.
            Container(
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 1),
                color: value ? AppColors.ink : Colors.transparent,
              ),
              child: Align(
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  color: value ? AppColors.paperBright : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
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
              Text('Delete your account?', style: AppType.display(24)),
              const SizedBox(height: 4),
              Text(
                'This permanently removes your account and profile. Your prayers '
                'and rooms remain for the community. This cannot be undone.',
                style: AppType.flourish(15),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  color: AppColors.accent,
                  child: Text('DELETE PERMANENTLY',
                      style: AppType.mono(11, color: AppColors.paperBright,
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
                  child: Text('KEEP MY ACCOUNT',
                      style: AppType.mono(11, weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthService.instance.deleteAccount();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'requires-recent-login'
          ? 'Please sign in again, then delete your account.'
          : 'Could not delete your account. Try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(msg, style: AppType.body(15, color: AppColors.paperBright)),
        ));
      }
    }
  }
}
