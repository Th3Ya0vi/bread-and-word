import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_shell.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/youversion/versions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/auth_sheet.dart';

const onboardingDoneKey = 'onboarding_complete_v1';

/// A warm, four-step welcome: who you are before God, what you're seeking,
/// and an invitation to join — or simply look around.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  String? _journeyStage;
  final Set<String> _seeking = {};
  int _versionId = 3034; // BSB by default

  static const _stepCount = 5;

  static const _stages = [
    ('New to faith', 'Exploring, with honest questions'),
    ('Returning', 'Coming back after time away'),
    ('Walking steadily', 'Seeking to go deeper'),
    ('Leading others', 'Shepherding family or community'),
  ];

  static const _seekingOptions = [
    'Daily time in the Word',
    'A praying community',
    'To pray for others',
    'Peace & healing',
    'To read Scripture with others',
    'Accountability',
  ];

  void _next() {
    if (_index < _stepCount - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish({required bool createAccount}) async {
    // Save the journey answers + chosen Bible version.
    BiblePrefs.instance.setVersion(_versionId);
    AuthService.instance.saveProfile(
      journeyStage: _journeyStage,
      seeking: _seeking.toList(),
    );

    if (createAccount) {
      final joined = await presentAuthSheet(
        context,
        reason: 'Save your journey and join the community.',
      );
      if (joined) AuthService.instance.saveProfile(); // refresh isMember
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDoneKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _welcome(),
                    _journey(),
                    _seekingStep(),
                    _versionStep(),
                    _account(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _dots(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Step 1 — Welcome
  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EST. TODAY', style: AppType.mono(10, color: AppColors.accent)),
          const SizedBox(height: 12),
          Text('Bread\n& Word', style: AppType.display(56)),
          const SizedBox(height: 18),
          Container(width: 60, height: 1, color: AppColors.ink),
          const SizedBox(height: 18),
          Text(
            'A place to walk with God — together. Daily bread for your soul, '
            'and a community to pray and gather with.',
            style: AppType.body(18, height: 1.5),
          ),
          const SizedBox(height: 28),
          BwButton(label: 'Begin', icon: null, onPressed: _next),
        ],
      ),
    );
  }

  // Step 2 — Journey stage
  Widget _journey() {
    return _stepScaffold(
      eyebrow: 'A Gentle Question',
      title: 'Where are you in your journey?',
      subline: 'However you answer, you are welcome here.',
      child: Column(
        children: [
          for (final s in _stages) ...[
            _ChoiceCard(
              title: s.$1,
              subtitle: s.$2,
              selected: _journeyStage == s.$1,
              onTap: () => setState(() => _journeyStage = s.$1),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      cta: 'Continue',
      enabled: _journeyStage != null,
      onCta: _next,
    );
  }

  // Step 3 — Seeking (multi)
  Widget _seekingStep() {
    return _stepScaffold(
      eyebrow: 'What Draws You',
      title: 'What are you seeking?',
      subline: 'Choose as many as you like.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final o in _seekingOptions)
            _Chip(
              label: o,
              selected: _seeking.contains(o),
              onTap: () => setState(() {
                _seeking.contains(o) ? _seeking.remove(o) : _seeking.add(o);
              }),
            ),
        ],
      ),
      cta: 'Continue',
      enabled: _seeking.isNotEmpty,
      onCta: _next,
    );
  }

  // Step 4 — Account or look around
  Widget _account() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const SectionHeader(
            eyebrow: 'Welcome, Friend',
            title: 'Make it yours',
            subline: 'Create an account to save your journey, pray for others, '
                'and gather in rooms.',
          ),
          const Spacer(),
          BwButton(
            label: 'Create your account',
            expand: true,
            onPressed: () => _finish(createAccount: true),
          ),
          const SizedBox(height: 12),
          BwButton(
            label: 'Just look around',
            primary: false,
            expand: true,
            onPressed: () => _finish(createAccount: false),
          ),
          const SizedBox(height: 12),
          Text(
            'You can read everything and post a prayer request as a guest. '
            'Creating an account unlocks praying, plans, and rooms.',
            style: AppType.flourish(14),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Step 4 — Bible version
  Widget _versionStep() {
    return _stepScaffold(
      eyebrow: 'Your Bible',
      title: 'Pick a translation',
      subline: 'You can change this anytime in the Bible tab.',
      child: Column(
        children: [
          for (final v in kBibleVersions) ...[
            _ChoiceCard(
              title: v.abbreviation,
              subtitle: v.title,
              selected: _versionId == v.id,
              onTap: () => setState(() => _versionId = v.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      cta: 'Continue',
      enabled: true,
      onCta: _next,
    );
  }

  Widget _stepScaffold({
    required String eyebrow,
    required String title,
    required String subline,
    required Widget child,
    required String cta,
    required bool enabled,
    required VoidCallback onCta,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: eyebrow, title: title, subline: subline),
          const SizedBox(height: 22),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 12),
          BwButton(
            label: cta,
            expand: true,
            onPressed: enabled ? onCta : null,
          ),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _stepCount; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 16 : 6,
            height: 6,
            color: i == _index ? AppColors.accent : AppColors.inkGhost,
          ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paperBright,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppType.display(22,
                    color: selected ? AppColors.paperBright : AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppType.flourish(15,
                    color: selected ? AppColors.paperDeep : AppColors.inkFaded)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Text(
          label,
          style: AppType.body(15,
              color: selected ? AppColors.paperBright : AppColors.ink,
              weight: FontWeight.w600),
        ),
      ),
    );
  }
}
