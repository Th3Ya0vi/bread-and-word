import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/youversion/bible_cache.dart';
import '../../services/youversion/books.dart';
import '../../services/youversion/versions.dart';
import '../../services/youversion/youversion_client.dart';
import '../../services/youversion/youversion_models.dart';
import '../../services/firebase/social_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../auth/require_account.dart';

/// Chapter picker for a book — a grid of chapter numbers.
class BibleBookScreen extends StatelessWidget {
  const BibleBookScreen({super.key, required this.book});
  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackBar(title: book.name),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: book.chapters,
                  itemBuilder: (_, i) {
                    final chapter = i + 1;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BibleReaderScreen(book: book, chapter: chapter),
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink, width: 1),
                          color: AppColors.paperBright,
                        ),
                        child: Text(
                          '$chapter',
                          style: AppType.display(20, color: AppColors.ink),
                        ),
                      ),
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

/// The reader — fetches a chapter (numbered verses) in the chosen version,
/// with prev/next navigation across book boundaries.
class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
  });
  final BibleBook book;
  final int chapter;

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final _yv = YouVersionClient();
  final _scroll = ScrollController();
  late BibleBook _book = widget.book;
  late int _chapterNum = widget.chapter;
  Chapter? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    BiblePrefs.instance.versionId.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bibleId = BiblePrefs.instance.versionId.value;
    final ref = '${_book.usfm}.$_chapterNum';
    // Serve from the on-device cache when it's fresh (chapters rarely change).
    final cached = await BibleCache.get(bibleId, ref);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _data = cached;
        _loading = false;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    try {
      final c = await _yv.chapterVerses(ref, bibleId: bibleId);
      BibleCache.put(bibleId, ref, c);
      if (!mounted) return;
      setState(() {
        _data = c;
        _loading = false;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _yv.isConfigured
            ? 'Could not load this chapter. Tap to try again.'
            : 'Scripture isn’t set up on this build — run with '
                  '--dart-define-from-file=dart_defines.local.json.';
      });
    }
  }

  bool get _hasPrev =>
      !(_book.usfm == kBibleBooks.first.usfm && _chapterNum == 1);
  bool get _hasNext =>
      !(_book.usfm == kBibleBooks.last.usfm && _chapterNum == _book.chapters);

  void _go(int delta) {
    var idx = kBibleBooks.indexWhere((b) => b.usfm == _book.usfm);
    var ch = _chapterNum + delta;
    if (ch < 1) {
      idx -= 1;
      if (idx < 0) return;
      _book = kBibleBooks[idx];
      ch = _book.chapters;
    } else if (ch > _book.chapters) {
      idx += 1;
      if (idx >= kBibleBooks.length) return;
      _book = kBibleBooks[idx];
      ch = 1;
    }
    setState(() => _chapterNum = ch);
    _load();
  }

  @override
  void dispose() {
    BiblePrefs.instance.versionId.removeListener(_load);
    _yv.close();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              _BackBar(title: _book.name, trailing: const _VersionPill()),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHAPTER', style: AppType.eyebrow()),
                      const SizedBox(height: 2),
                      Text(
                        '${_book.name} $_chapterNum',
                        style: AppType.display(32),
                      ),
                      const SizedBox(height: 6),
                      const DoubleRule(),
                      const SizedBox(height: 18),
                      if (_loading)
                        Text(
                          'Opening the page…',
                          style: AppType.flourish(
                            16,
                            color: AppColors.inkGhost,
                          ),
                        )
                      else if (_error != null)
                        GestureDetector(
                          onTap: _load,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppType.flourish(16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                PhosphorIconsRegular.arrowClockwise,
                                size: 16,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        )
                      else
                        _verseBody(_data?.verses ?? const []),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              _navBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verseBody(List<Verse> verses) {
    if (verses.isEmpty) return const SizedBox.shrink();
    final bibleId = BiblePrefs.instance.versionId.value;
    // One verse per line — a leading verse number and roomy, readable text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final v in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.top,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 9, top: 3),
                          child: Text(
                            '${v.number}',
                            style: AppType.mono(
                              11,
                              color: AppColors.accent,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: v.text,
                        style: AppType.body(
                          20,
                          color: AppColors.ink,
                          height: 1.62,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _VerseReactions(
                  verseKey:
                      '${bibleId}_${_book.usfm}_${_chapterNum}_${v.number}',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _navBar() {
    // No band — just the controls on the page, so reading feels natural.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(
            'Previous',
            PhosphorIconsRegular.arrowLeft,
            enabled: _hasPrev,
            onTap: () => _go(-1),
            leading: true,
          ),
          Text('${_book.usfm} $_chapterNum', style: AppType.mono(9)),
          _navButton(
            'Next',
            PhosphorIconsRegular.arrowRight,
            enabled: _hasNext,
            onTap: () => _go(1),
            leading: false,
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    String label,
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
    required bool leading,
  }) {
    final color = enabled ? AppColors.ink : AppColors.inkGhost;
    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(
        label.toUpperCase(),
        style: AppType.mono(10, color: color, weight: FontWeight.w600),
      ),
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading ? children : children.reversed.toList(),
      ),
    );
  }
}

class _VerseReactions extends StatelessWidget {
  const _VerseReactions({required this.verseKey});

  final String verseKey;

  static const _items = [
    ('comforted', 'Comforted', PhosphorIconsRegular.heart),
    ('convicted', 'Convicted', PhosphorIconsRegular.fire),
    ('question', 'Question', PhosphorIconsRegular.question),
    ('memorizing', 'Memorizing', PhosphorIconsRegular.bookmarkSimple),
  ];

  Future<void> _react(BuildContext context, String kind) async {
    if (!await requireAccount(context, action: 'react to Scripture')) return;
    await SocialRepository.instance.reactToVerse(verseKey, kind);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: SocialRepository.instance.watchVerseReactionCounts(verseKey),
      builder: (context, countSnap) {
        final counts = countSnap.data ?? const <String, int>{};
        return StreamBuilder<String?>(
          stream: SocialRepository.instance.watchMyVerseReaction(verseKey),
          builder: (context, mineSnap) {
            final mine = mineSnap.data;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _items)
                  _VerseReactionChip(
                    label: item.$2,
                    icon: item.$3,
                    count: counts[item.$1] ?? 0,
                    active: mine == item.$1,
                    onTap: () => _react(context, item.$1),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VerseReactionChip extends StatelessWidget {
  const _VerseReactionChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.inkFaded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? AppColors.accent : AppColors.inkFaded,
          ),
          color: active ? AppColors.paperBright : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label.toUpperCase(), style: AppType.mono(8, color: color)),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text('$count', style: AppType.mono(8, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable version label (e.g. "BSB ▾") that opens the version picker.
class _VersionPill extends StatelessWidget {
  const _VersionPill();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BiblePrefs.instance.versionId,
      builder: (context, id, _) {
        return GestureDetector(
          onTap: () => presentVersionPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  versionById(id).abbreviation,
                  style: AppType.mono(
                    10,
                    color: AppColors.ink,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  PhosphorIconsRegular.caretDown,
                  size: 11,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet to choose a Bible version.
Future<void> presentVersionPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24 + MediaQuery.of(sheetContext).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Translation',
            title: 'Bible Version',
            subline: 'Choose how Scripture reads for you.',
            titleSize: 22,
          ),
          const SizedBox(height: 16),
          for (final v in kBibleVersions)
            ValueListenableBuilder<int>(
              valueListenable: BiblePrefs.instance.versionId,
              builder: (context, id, _) {
                final selected = id == v.id;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    BiblePrefs.instance.setVersion(v.id);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : AppColors.paperBright,
                      border: Border.all(color: AppColors.ink, width: 1),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            v.abbreviation,
                            style: AppType.mono(
                              11,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.accent,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            v.title,
                            style: AppType.body(
                              16,
                              color: selected
                                  ? AppColors.paperBright
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            PhosphorIconsRegular.check,
                            size: 15,
                            color: AppColors.paperBright,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Same paper as the page (no contrasting band), and no rule here — the
    // chapter heading below carries the divider, so the header blends in.
    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(8, 2, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.arrowLeft,
              color: AppColors.ink,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Text(title, style: AppType.display(22))),
          ?trailing,
        ],
      ),
    );
  }
}
