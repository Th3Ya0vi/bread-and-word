import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/block_service.dart';
import '../../services/firebase/fellowship_repository.dart';
import '../../services/firebase/user_profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/paper_grain.dart';

/// The people you've blocked — with the ability to unblock. (People who blocked
/// you stay hidden and aren't listed here.)
class BlockedAccountsScreen extends StatelessWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('Blocked', style: AppType.display(24)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: BlockService.instance.watchMyBlocks(),
                  builder: (context, snap) {
                    final uids = snap.data ?? const <String>[];
                    if (uids.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'You haven’t blocked anyone.',
                            style: AppType.flourish(16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: uids.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _BlockedRow(uid: uids[i]),
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
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1),
        color: AppColors.paperDeep,
      ),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<UserProfile>(
              stream: FellowshipRepository.instance.watchProfile(uid),
              builder: (context, snap) => Text(
                snap.data?.displayName ?? 'A member',
                style: AppType.body(17, color: AppColors.ink),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => BlockService.instance.unblock(uid),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.ink)),
              child: Text('UNBLOCK',
                  style: AppType.mono(10,
                      color: AppColors.ink, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
