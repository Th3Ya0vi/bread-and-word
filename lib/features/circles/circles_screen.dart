import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/social_repository.dart';
import '../../services/reading_progress.dart';
import '../../services/youversion/youversion_client.dart';
import '../../services/youversion/youversion_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _CirclesBackBar()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'Circles',
                        title: 'Read Together',
                        subline:
                            'Small groups for Scripture, prayer, and testimony.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: BwButton(
                              label: 'New circle',
                              icon: PhosphorIconsRegular.plus,
                              expand: true,
                              onPressed: () => _presentCreate(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BwButton(
                              label: 'Join',
                              icon: PhosphorIconsRegular.ticket,
                              expand: true,
                              primary: false,
                              onPressed: () => _presentJoin(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<CircleDoc>>(
                stream: SocialRepository.instance.watchMyCircles(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _message('Circles are resting. Try again shortly.');
                  }
                  if (!snap.hasData) return _message('Gathering circles...');
                  final circles = snap.data!;
                  if (circles.isEmpty) {
                    return _message(
                      'Start a circle for your family, church friends, or team.',
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList.separated(
                      itemCount: circles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _CircleCard(circle: circles[i]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _message(String text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Center(
        child: Text(
          text,
          style: AppType.flourish(16),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  static Future<void> _presentCreate(BuildContext context) async {
    if (!await requireAccount(context, action: 'create a circle')) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      builder: (_) => const _CircleNameSheet(),
    );
  }

  static Future<void> _presentJoin(BuildContext context) async {
    if (!await requireAccount(context, action: 'join a circle')) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      builder: (_) => const _JoinCircleSheet(),
    );
  }
}

class _CirclesBackBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                PhosphorIconsRegular.arrowLeft,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          Text('BACK TO PRAYER WALL', style: AppType.mono(10)),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});
  final CircleDoc circle;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperBright,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CircleDetailScreen(circle: circle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('INVITE ${circle.inviteCode}', style: AppType.mono(9)),
              const Spacer(),
              Text(
                '${circle.memberCount} MEMBERS',
                style: AppType.mono(9, color: AppColors.inkFaded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(circle.name, style: AppType.display(24)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 6, height: 6, color: AppColors.accent),
              const SizedBox(width: 7),
              Text(
                'TODAY’S SHARED REFLECTION',
                style: AppType.mono(9, color: AppColors.accent),
              ),
              const Spacer(),
              Text('→', style: AppType.display(18, color: AppColors.inkFaded)),
            ],
          ),
        ],
      ),
    );
  }
}

class CircleDetailScreen extends StatefulWidget {
  const CircleDetailScreen({super.key, required this.circle});
  final CircleDoc circle;

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  final _controller = TextEditingController();
  final _yv = YouVersionClient();
  bool _sending = false;

  // Always renderable: start on the fallback, swap to live data as it
  // arrives (same pattern as Today — no spinner, no stuck loading state).
  Passage _verse = const Passage(
    id: 'PSA.133.1',
    reference: 'Psalm 133:1',
    text:
        'Behold, how good and how pleasant it is for brethren to dwell '
        'together in unity!',
  );

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    try {
      final verse = await _yv.verseOfDay().timeout(
        const Duration(seconds: 8),
      );
      if (mounted) setState(() => _verse = verse);
    } catch (_) {
      // keep fallback
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _yv.close();
    super.dispose();
  }

  Future<void> _share() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await SocialRepository.instance.addReflection(widget.circle.id, text);
      _controller.clear();
    } catch (_) {
      // Keep the text so the member can retry.
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = ReadingProgress.easternDateKey();
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          PhosphorIconsRegular.arrowLeft,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.circle.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.mono(10, color: AppColors.ink),
                      ),
                    ),
                    Text(
                      'INVITE ${widget.circle.inviteCode}',
                      style: AppType.mono(9, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    SectionHeader(
                      eyebrow: dateKey,
                      title: 'Read Today’s Word Together',
                      subline:
                          'One passage for the whole circle, then share what '
                          'God is showing you.',
                    ),
                    const SizedBox(height: 14),
                    _SharedPassageCard(verse: _verse),
                    const SizedBox(height: 22),
                    const RuleLabel('Your reflection'),
                    const SizedBox(height: 14),
                    _ReflectionComposer(
                      controller: _controller,
                      sending: _sending,
                      onShare: _share,
                    ),
                    const SizedBox(height: 22),
                    const RuleLabel('Circle reflections'),
                    const SizedBox(height: 14),
                    StreamBuilder<List<CircleReflection>>(
                      stream: SocialRepository.instance.watchTodayReflections(
                        widget.circle.id,
                      ),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return _note('Reflections are resting.');
                        }
                        if (!snap.hasData) {
                          return _note('Gathering reflections...');
                        }
                        final reflections = snap.data!;
                        if (reflections.isEmpty) {
                          return _note('Be the first to share today.');
                        }
                        return Column(
                          children: [
                            for (final r in reflections) ...[
                              _ReflectionCard(reflection: r),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
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

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Text(
        text,
        style: AppType.flourish(15),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _SharedPassageCard extends StatelessWidget {
  const _SharedPassageCard({required this.verse});
  final Passage verse;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: AppColors.accent),
              const SizedBox(width: 7),
              Text(
                'TODAY’S SHARED PASSAGE',
                style: AppType.mono(9, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(verse.text, style: AppType.body(17, height: 1.55)),
          const SizedBox(height: 10),
          Text(
            '— ${verse.reference.toUpperCase()}',
            style: AppType.mono(10, color: AppColors.inkFaded),
          ),
        ],
      ),
    );
  }
}

class _ReflectionComposer extends StatelessWidget {
  const _ReflectionComposer({
    required this.controller,
    required this.sending,
    required this.onShare,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperBright,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 360,
            cursorColor: AppColors.accent,
            style: AppType.body(16, color: AppColors.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: 'A verse, a conviction, a comfort, or a next step...',
              hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
            ),
          ),
          const SizedBox(height: 10),
          BwButton(
            label: sending ? 'Sharing...' : 'Share reflection',
            icon: PhosphorIconsRegular.paperPlaneRight,
            expand: true,
            onPressed: sending ? null : onShare,
          ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.reflection});
  final CircleReflection reflection;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reflection.author.toUpperCase(), style: AppType.mono(9)),
              const Spacer(),
              Icon(
                PhosphorIconsRegular.chatCircleText,
                size: 14,
                color: AppColors.inkFaded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(reflection.body, style: AppType.body(16, height: 1.5)),
        ],
      ),
    );
  }
}

class _CircleNameSheet extends StatefulWidget {
  const _CircleNameSheet();

  @override
  State<_CircleNameSheet> createState() => _CircleNameSheetState();
}

class _CircleNameSheetState extends State<_CircleNameSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await SocialRepository.instance.createCircle(name);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TextSheet(
      title: 'New Circle',
      subline: 'Name your small group.',
      hint: 'Family devotion, Youth group, Men’s breakfast...',
      controller: _controller,
      sending: _sending,
      buttonLabel: 'Create circle',
      onSubmit: _create,
    );
  }
}

class _JoinCircleSheet extends StatefulWidget {
  const _JoinCircleSheet();

  @override
  State<_JoinCircleSheet> createState() => _JoinCircleSheetState();
}

class _JoinCircleSheetState extends State<_JoinCircleSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final circle = await SocialRepository.instance.joinByInviteCode(
        _controller.text,
      );
      if (!mounted) return;
      if (circle == null) {
        setState(() {
          _sending = false;
          _error = 'No circle found for that code.';
        });
        return;
      }
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CircleDetailScreen(circle: circle)),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Could not join. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TextSheet(
      title: 'Join Circle',
      subline: 'Enter the six-character invite code.',
      hint: 'ABC123',
      controller: _controller,
      sending: _sending,
      buttonLabel: 'Join circle',
      error: _error,
      onSubmit: _join,
    );
  }
}

class _TextSheet extends StatelessWidget {
  const _TextSheet({
    required this.title,
    required this.subline,
    required this.hint,
    required this.controller,
    required this.sending,
    required this.buttonLabel,
    required this.onSubmit,
    this.error,
  });

  final String title;
  final String subline;
  final String hint;
  final TextEditingController controller;
  final bool sending;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final String? error;

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
          SectionHeader(
            eyebrow: 'Circles',
            title: title,
            subline: subline,
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
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              cursorColor: AppColors.accent,
              style: AppType.body(16, color: AppColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: AppType.body(14, color: AppColors.accent)),
          ],
          const SizedBox(height: 18),
          BwButton(
            label: sending ? 'Working...' : buttonLabel,
            expand: true,
            onPressed: sending ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
