import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/auth_service.dart';
import '../../services/firebase/fellowship_repository.dart';
import '../../services/firebase/models.dart';
import '../../services/firebase/user_profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';
import '../moderation/content_actions.dart';
import '../moderation/report_sheet.dart';
import 'edit_bio_sheet.dart';
import 'fellowship_feed_screen.dart';

/// A member's public profile: who they are, the rooms they've hosted, and the
/// prayers they've shared — with a member-gated "Fellowship" follow toggle.
class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.uid});
  final String uid;

  bool get _isSelf => uid == AuthService.instance.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context),
              Expanded(
                child: StreamBuilder<UserProfile>(
                  stream: FellowshipRepository.instance.watchProfile(uid),
                  builder: (context, snap) {
                    final profile = snap.data;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      children: [
                        _header(context, profile),
                        const SizedBox(height: 24),
                        const DoubleRule(),
                        const SizedBox(height: 20),
                        const RuleLabel('Their prayers'),
                        const SizedBox(height: 14),
                        _prayers(),
                      ],
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(8, 2, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft,
                color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(_isSelf ? 'My Profile' : 'Profile', style: AppType.display(24)),
          const Spacer(),
          if (!_isSelf)
            MoreButton(
              actions: [
                ContentAction(
                  icon: PhosphorIconsRegular.flag,
                  label: 'Report this person',
                  onTap: () => presentReportSheet(
                    context,
                    targetType: 'user',
                    targetId: uid,
                    targetPath: 'users/$uid',
                    reportedUid: uid,
                    label: 'this person',
                  ),
                ),
                blockUserAction(context, uid: uid),
              ],
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, UserProfile? profile) {
    final name = profile?.displayName ?? 'Friend in Christ';
    final bio = profile?.bio ?? '';
    return Column(
      children: [
        Center(
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
              Text(name, style: AppType.display(26), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              _miniStats(profile),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(bio,
                    style: AppType.flourish(16), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _action(context, profile),
      ],
    );
  }

  // Compact icon + number stats: followers · following · rooms hosted.
  Widget _miniStats(UserProfile? profile) {
    final followers = profile?.fellowshipCount ?? 0;
    final following = profile?.followingCount ?? 0;
    final rooms = profile?.roomsHosted ?? 0;
    Widget stat(IconData icon, int n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.inkFaded),
            const SizedBox(width: 5),
            Text('$n',
                style: AppType.body(17,
                    color: AppColors.ink, weight: FontWeight.w600)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stat(PhosphorIconsRegular.users, followers),
        const SizedBox(width: 22),
        stat(PhosphorIconsRegular.footprints, following),
        const SizedBox(width: 22),
        stat(PhosphorIconsRegular.microphoneStage, rooms),
      ],
    );
  }

  Widget _action(BuildContext context, UserProfile? profile) {
    if (_isSelf) {
      return _EditBioButton(currentBio: profile?.bio ?? '');
    }
    return _FollowToggle(uid: uid);
  }

  Widget _prayers() {
    return StreamBuilder<List<Prayer>>(
      stream: FellowshipRepository.instance.prayersBy(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text('Gathering their prayers…',
                    style: AppType.flourish(15))),
          );
        }
        final prayers = snap.data!;
        if (prayers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text('No prayers shared yet.',
                    style: AppType.flourish(15))),
          );
        }
        return Column(
          children: [
            for (final p in prayers) ...[
              FellowshipPrayerCard(prayer: p),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

/// The member-gated follow / unfollow button.
class _FollowToggle extends StatelessWidget {
  const _FollowToggle({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FellowshipRepository.instance.watchIsFollowing(uid),
      builder: (context, snap) {
        final following = snap.data ?? false;
        return _BorderButton(
          label: following ? 'In fellowship ✓' : 'Fellowship',
          icon: following ? null : PhosphorIconsRegular.userPlus,
          filled: following,
          onTap: () async {
            final repo = FellowshipRepository.instance;
            if (following) {
              await repo.unfollow(uid);
            } else {
              if (await requireAccount(context, action: 'walk with others')) {
                await repo.follow(uid);
              }
            }
          },
        );
      },
    );
  }
}

class _EditBioButton extends StatelessWidget {
  const _EditBioButton({required this.currentBio});
  final String currentBio;

  @override
  Widget build(BuildContext context) {
    return _BorderButton(
      label: 'Edit bio',
      icon: PhosphorIconsRegular.pencilSimple,
      filled: false,
      onTap: () => editBio(context, initial: currentBio),
    );
  }
}

/// A hard-edged full-width button. Filled (ink) when active, outlined otherwise.
class _BorderButton extends StatelessWidget {
  const _BorderButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.paperBright : AppColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: filled ? AppColors.ink : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label.toUpperCase(),
                style: AppType.mono(11, color: fg, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
