import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/gloo/devotional_writer.dart';
import '../../services/reading_progress.dart';
import '../../services/youversion/books.dart';
import '../../services/youversion/youversion_client.dart';
import '../../services/youversion/youversion_models.dart';
import '../bible/bible_reader_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';

/// "Give us this day our daily bread." The devotional home —
/// verse of the day (live from YouVersion), a reflection, and the reading plan.
///
/// The reflection is placeholder copy; it plugs into Gloo AI next. The reading
/// plan plugs into YouVersion reading plans next.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _yv = YouVersionClient();
  final _writer = DevotionalWriter();
  final _progress = ReadingProgress.instance;

  // Stable completion keys for today's items.
  static const _verseKey = 'verse';
  static const _reflectionKey = 'reflection';
  static String _readingKey(int i) => 'reading_$i';

  // A short word to keep — chosen by day-of-year, revealed only once
  // everything is complete. Seven so it rotates through the week.
  static const _blessings = [
    'Go gently. The One who began a good work in you will carry it home.',
    'You are kept, named, and led. Let that be enough for today.',
    'Grace went before you this morning; it will meet you again tonight.',
    'Carry the quiet of these pages into the noise of the hours ahead.',
    'Whatever the day asks, you do not face it alone. Be still and trust.',
    'The word you read becomes the word you live. Walk in it.',
    'Rest in this: mercy is new every morning, and morning always comes.',
  ];

  // Always hold renderable content: start on the fallbacks, swap to live
  // data via setState as it arrives. No spinner, no stuck "loading" state.
  late Passage _verse;
  late ({String title, String body}) _reflection;

  // Fallback shown if YouVersion isn't configured or the network fails,
  // so the screen always reads well.
  static const _fallback = Passage(
    id: 'PSA.23.1',
    reference: 'Psalm 23:1–2',
    text:
        'The Lord is my shepherd; I shall not want. He maketh me to lie down '
        'in green pastures: he leadeth me beside the still waters.',
  );

  // Today's three passages, rotating by day-of-year so the reading is fresh
  // each morning (cycles through a three-week arc). Shape: (label, reference,
  // book USFM, chapter).
  List<(String, String, String, int)> get _reading =>
      _dailyReadings[(_dayOfYear() - 1) % _dailyReadings.length];

  static const _dailyReadings = <List<(String, String, String, int)>>[
    [
      ('Old Testament', 'Psalm 1', 'PSA', 1),
      ('Gospel', 'Matthew 5', 'MAT', 5),
      ('Epistle', 'James 1', 'JAS', 1),
    ],
    [
      ('Old Testament', 'Psalm 23', 'PSA', 23),
      ('Gospel', 'John 10', 'JHN', 10),
      ('Epistle', '1 Peter 5', '1PE', 5),
    ],
    [
      ('Old Testament', 'Genesis 1', 'GEN', 1),
      ('Gospel', 'John 1', 'JHN', 1),
      ('Epistle', 'Colossians 1', 'COL', 1),
    ],
    [
      ('Old Testament', 'Psalm 91', 'PSA', 91),
      ('Gospel', 'Matthew 6', 'MAT', 6),
      ('Epistle', 'Philippians 4', 'PHP', 4),
    ],
    [
      ('Old Testament', 'Proverbs 3', 'PRO', 3),
      ('Gospel', 'Luke 15', 'LUK', 15),
      ('Epistle', '1 John 4', '1JN', 4),
    ],
    [
      ('Old Testament', 'Isaiah 40', 'ISA', 40),
      ('Gospel', 'John 14', 'JHN', 14),
      ('Epistle', 'Romans 8', 'ROM', 8),
    ],
    [
      ('Old Testament', 'Psalm 103', 'PSA', 103),
      ('Gospel', 'Mark 10', 'MRK', 10),
      ('Epistle', 'Ephesians 2', 'EPH', 2),
    ],
    [
      ('Old Testament', 'Psalm 27', 'PSA', 27),
      ('Gospel', 'Matthew 11', 'MAT', 11),
      ('Epistle', 'Hebrews 4', 'HEB', 4),
    ],
    [
      ('Old Testament', 'Exodus 14', 'EXO', 14),
      ('Gospel', 'John 6', 'JHN', 6),
      ('Epistle', '1 Corinthians 13', '1CO', 13),
    ],
    [
      ('Old Testament', 'Psalm 46', 'PSA', 46),
      ('Gospel', 'Luke 6', 'LUK', 6),
      ('Epistle', 'Galatians 5', 'GAL', 5),
    ],
    [
      ('Old Testament', 'Isaiah 53', 'ISA', 53),
      ('Gospel', 'John 19', 'JHN', 19),
      ('Epistle', '2 Corinthians 4', '2CO', 4),
    ],
    [
      ('Old Testament', 'Psalm 51', 'PSA', 51),
      ('Gospel', 'Luke 7', 'LUK', 7),
      ('Epistle', '1 John 1', '1JN', 1),
    ],
    [
      ('Old Testament', 'Proverbs 4', 'PRO', 4),
      ('Gospel', 'Matthew 7', 'MAT', 7),
      ('Epistle', 'James 3', 'JAS', 3),
    ],
    [
      ('Old Testament', 'Psalm 121', 'PSA', 121),
      ('Gospel', 'John 15', 'JHN', 15),
      ('Epistle', 'Romans 12', 'ROM', 12),
    ],
    [
      ('Old Testament', 'Daniel 6', 'DAN', 6),
      ('Gospel', 'Mark 4', 'MRK', 4),
      ('Epistle', 'Philippians 2', 'PHP', 2),
    ],
    [
      ('Old Testament', 'Psalm 139', 'PSA', 139),
      ('Gospel', 'Luke 10', 'LUK', 10),
      ('Epistle', 'Ephesians 4', 'EPH', 4),
    ],
    [
      ('Old Testament', 'Joshua 1', 'JOS', 1),
      ('Gospel', 'Matthew 14', 'MAT', 14),
      ('Epistle', 'Hebrews 11', 'HEB', 11),
    ],
    [
      ('Old Testament', 'Psalm 34', 'PSA', 34),
      ('Gospel', 'John 8', 'JHN', 8),
      ('Epistle', '1 Peter 1', '1PE', 1),
    ],
    [
      ('Old Testament', 'Isaiah 55', 'ISA', 55),
      ('Gospel', 'Luke 12', 'LUK', 12),
      ('Epistle', 'Colossians 3', 'COL', 3),
    ],
    [
      ('Old Testament', 'Psalm 84', 'PSA', 84),
      ('Gospel', 'Matthew 13', 'MAT', 13),
      ('Epistle', '2 Timothy 2', '2TI', 2),
    ],
    [
      ('Old Testament', 'Ecclesiastes 3', 'ECC', 3),
      ('Gospel', 'John 11', 'JHN', 11),
      ('Epistle', 'Romans 5', 'ROM', 5),
    ],
  ];

  // Static reflection shown when Gloo isn't configured or generation fails.
  static const _fallbackReflection = (
    title: 'Beside Still Waters',
    body:
        'Rest is not idleness. The shepherd does not drive the flock through '
        'the valley without first leading it to water. Before the day asks '
        'anything of you, let it be enough that you are kept, named, and led. '
        'Want gives way to trust the moment you remember whose you are.',
  );

  @override
  void initState() {
    super.initState();
    _verse = _fallback;
    _reflection = _fallbackReflection;
    _progress.load();
    _load();
  }

  Future<void> _load() async {
    // 1) Verse of the day from YouVersion.
    Passage verse = _fallback;
    try {
      verse = await _yv.verseOfDay();
    } catch (_) {
      // keep fallback
    }
    if (!mounted) return;
    setState(() => _verse = verse);

    // 2) Faith-tuned reflection on that verse from Gloo (if configured).
    if (_writer.isAvailable) {
      try {
        final r = await _writer.reflect(
          reference: verse.reference,
          verseText: verse.text,
        );
        if (!mounted) return;
        setState(() => _reflection = r);
      } catch (_) {
        // keep fallback reflection
      }
    }
  }

  @override
  void dispose() {
    _yv.close();
    _writer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Staggered entrance for a more alive feel.
    Widget animated(int i, Widget child) => child
        .animate()
        .fadeIn(duration: 420.ms, delay: (90 * i).ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);

    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              sliver: SliverList.list(
                children: [
                  // The whole devotional reacts to today's progress, so a check
                  // anywhere updates the hero, reflection, rows and reward.
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _progress.completedToday,
                    builder: (context, done, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          animated(0, _heroVerse(done.contains(_verseKey))),
                          const SizedBox(height: 16),
                          animated(1, _continueCard()),
                          const SizedBox(height: 28),
                          animated(
                            2,
                            _reflectionSection(done.contains(_reflectionKey)),
                          ),
                          const SizedBox(height: 28),
                          animated(3, _readingPlan(done)),
                          if (_allComplete(done)) ...[
                            const SizedBox(height: 28),
                            _wordToKeep(),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          PhosphorIconsRegular.cross,
                          size: 18,
                          color: AppColors.inkGhost,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '“Give us this day our daily bread.”',
                          style: AppType.flourish(15),
                        ),
                        const SizedBox(height: 2),
                        Text('Matthew 6:11', style: AppType.mono(9)),
                      ],
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _header() {
    final day = _dayOfYear();
    final progress = (day / 365).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formattedDate().toUpperCase(),
            style: AppType.mono(9, color: AppColors.inkFaded),
          ),
          const SizedBox(height: 4),
          Text(_greeting(), style: AppType.display(34)),
          const SizedBox(height: 16),
          // Journey progress, front and centre.
          Row(
            children: [
              Text(
                'DAY $day',
                style: AppType.mono(
                  10,
                  color: AppColors.accent,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 3,
                  color: AppColors.paperDeep,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('OF 365', style: AppType.mono(9, color: AppColors.inkFaded)),
            ],
          ),
          const SizedBox(height: 12),
          const DoubleRule(),
        ],
      ),
    );
  }

  // Bold hero verse — the centrepiece of the morning.
  Widget _heroVerse(bool done) {
    final p = _verse;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.paperBright,
        border: Border.all(color: AppColors.ink, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: AppColors.accent),
              const SizedBox(width: 7),
              Text('TODAY’S VERSE', style: AppType.eyebrow()),
            ],
          ),
          const SizedBox(height: 16),
          _heroScripture(p.text),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '— ${p.reference.toUpperCase()}',
                  style: AppType.mono(10, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              _MarkAsRead(
                done: done,
                onTap: () => _progress.setDone(_verseKey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroScripture(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final first = text.substring(0, 1);
    final rest = text.substring(1);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: first,
            style: AppType.display(
              58,
              color: AppColors.accent,
            ).copyWith(height: 0.8),
          ),
          TextSpan(
            text: rest,
            style: AppType.body(23, color: AppColors.ink, height: 1.5),
          ),
        ],
      ),
    );
  }

  // "Continue" — pick up today's first reading.
  Widget _continueCard() {
    final r = _reading.first;
    final book = kBibleBooks.firstWhere(
      (b) => b.usfm == r.$3,
      orElse: () => kBibleBooks.first,
    );
    return BwCard(
      color: AppColors.paperDeep,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BibleReaderScreen(book: book, chapter: r.$4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.bookmarkSimple,
            size: 22,
            color: AppColors.accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTINUE YOUR READING', style: AppType.eyebrow()),
                const SizedBox(height: 3),
                Text(r.$2, style: AppType.display(22)),
              ],
            ),
          ),
          Text('→', style: AppType.display(22, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _reflectionSection(bool done) {
    final data = _reflection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Daily Reflection',
          title: data.title,
          subline: 'A short word for this morning',
        ),
        const SizedBox(height: 14),
        Text(data.body, style: AppType.body(17, height: 1.55)),
        const SizedBox(height: 16),
        _MarkAsRead(done: done, onTap: () => _progress.setDone(_reflectionKey)),
      ],
    );
  }

  Widget _readingPlan(Set<String> done) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: "Today's Reading",
          title: 'Walk Through Scripture',
          subline: 'Three passages — about twelve minutes',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _reading.length; i++) ...[
          _ReadingRow(
            label: _reading[i].$1,
            ref: _reading[i].$2,
            usfm: _reading[i].$3,
            chapter: _reading[i].$4,
            done: done.contains(_readingKey(i)),
            onToggle: () => _progress.setDone(_readingKey(i)),
          ),
          if (i < _reading.length - 1)
            const Divider(color: AppColors.inkFaded, height: 1),
        ],
      ],
    );
  }

  // Every item of today's devotional accounted for.
  bool _allComplete(Set<String> done) {
    if (!done.contains(_verseKey)) return false;
    if (!done.contains(_reflectionKey)) return false;
    for (var i = 0; i < _reading.length; i++) {
      if (!done.contains(_readingKey(i))) return false;
    }
    return true;
  }

  // The reward: a single line to carry into the day, revealed only once
  // everything has been read. Chosen by day-of-year so it changes daily.
  Widget _wordToKeep() {
    final blessing = _blessings[(_dayOfYear() - 1) % _blessings.length];
    return BwCard(
      color: AppColors.paperBright,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.check,
                size: 16,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A WORD TO KEEP WITH YOU TODAY',
                  style: AppType.eyebrow(color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            blessing,
            style: AppType.body(20, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 16),
          const DoubleRule(),
          const SizedBox(height: 10),
          Text(
            'TODAY’S READING COMPLETE',
            style: AppType.mono(9, color: AppColors.inkFaded),
          ),
        ],
      ),
    );
  }

  static int _dayOfYear() {
    return ReadingProgress.easternDayOfYear();
  }

  static String _formattedDate() {
    final now = ReadingProgress.easternNow();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.label,
    required this.ref,
    required this.usfm,
    required this.chapter,
    required this.done,
    required this.onToggle,
  });
  final String label;
  final String ref;
  final String usfm;
  final int chapter;
  // Completion is owned by ReadingProgress so it persists per day; the row is
  // a pure view that reports taps back up via [onToggle].
  final bool done;
  final VoidCallback onToggle;

  void _open(BuildContext context) {
    final book = kBibleBooks.firstWhere(
      (b) => b.usfm == usfm,
      orElse: () => kBibleBooks.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BibleReaderScreen(book: book, chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Checkbox — its own tap target to mark the reading complete.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: done ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.green : AppColors.inkFaded,
                  width: 1,
                ),
              ),
              child: done
                  ? const Icon(
                      PhosphorIconsRegular.check,
                      size: 12,
                      color: AppColors.paper,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // The passage — tap to open and read it.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppType.mono(9, color: AppColors.accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ref,
                    style: AppType.body(
                      18,
                      color: done ? AppColors.inkFaded : AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(context),
            child: Text(
              '→',
              style: AppType.display(20, color: AppColors.inkFaded),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "Mark as read" affordance that flips to a green check + "READ"
/// once the item is done. Once read, it stays read for the day.
class _MarkAsRead extends StatelessWidget {
  const _MarkAsRead({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.check, size: 14, color: AppColors.green),
          const SizedBox(width: 6),
          Text('READ', style: AppType.mono(9, color: AppColors.green)),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.check, size: 13, color: AppColors.ink),
            const SizedBox(width: 6),
            Text('MARK AS READ', style: AppType.mono(9, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
