import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/youversion/books.dart';
import '../../services/youversion/versions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_card.dart';
import '../../widgets/paper_grain.dart';
import '../../widgets/section_header.dart';
import '../plans/plans_screen.dart';
import 'bible_reader_screen.dart';

/// The Bible — a browsable canon surface backed by YouVersion Scripture.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  bool _oldTestament = true;

  @override
  Widget build(BuildContext context) {
    final books = _oldTestament ? oldTestamentBooks : newTestamentBooks;
    final groups = _oldTestament ? _oldGroups : _newGroups;

    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  oldTestament: _oldTestament,
                  onChanged: (v) => setState(() => _oldTestament = v),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(child: _FeatureRow(books: books)),
            ),
            for (final group in groups)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _BookGroup(
                    title: group.title,
                    caption: group.caption,
                    books: group.books,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.oldTestament, required this.onChanged});

  final bool oldTestament;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SectionHeader(
                eyebrow: 'Holy Scripture',
                title: 'The Bible',
                subline: 'Browse by movement, then settle into the chapter.',
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<int>(
                valueListenable: BiblePrefs.instance.versionId,
                builder: (context, id, _) => GestureDetector(
                  onTap: () => presentVersionPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TestamentSwitch(oldTestament: oldTestament, onChanged: onChanged),
      ],
    );
  }
}

class _TestamentSwitch extends StatelessWidget {
  const _TestamentSwitch({required this.oldTestament, required this.onChanged});

  final bool oldTestament;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1),
        color: AppColors.paperBright,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _SwitchItem(
            label: 'Old Testament',
            active: oldTestament,
            onTap: () => onChanged(true),
          ),
          _SwitchItem(
            label: 'New Testament',
            active: !oldTestament,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: active ? AppColors.ink : Colors.transparent,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppType.mono(
                10,
                color: active ? AppColors.paperBright : AppColors.inkFaded,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.books});

  final List<BibleBook> books;

  @override
  Widget build(BuildContext context) {
    final first = books.first;
    final psalms = kBibleBooks.firstWhere((b) => b.usfm == 'PSA');

    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: PhosphorIconsRegular.bookOpen,
            title: 'Start Reading',
            label: first.name,
            onTap: () => _openBook(context, first),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: PhosphorIconsRegular.path,
            title: 'Reading Plans',
            label: 'Guided journeys',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlansScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: PhosphorIconsRegular.bookmarkSimple,
            title: 'The Psalms',
            label: 'Prayer book',
            onTap: () => _openBook(context, psalms),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperBright,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      onTap: onTap,
      child: SizedBox(
        height: 94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.mono(9, color: AppColors.ink),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.body(14, color: AppColors.inkSoft, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookGroup extends StatelessWidget {
  const _BookGroup({
    required this.title,
    required this.caption,
    required this.books,
  });

  final String title;
  final String caption;
  final List<BibleBook> books;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppType.mono(10, color: AppColors.accent),
                  ),
                  const SizedBox(height: 3),
                  Text(caption, style: AppType.flourish(14)),
                ],
              ),
            ),
            Text(
              '${books.length} BOOKS',
              style: AppType.mono(9, color: AppColors.inkFaded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.ink),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 2;
            return GridView.builder(
              itemCount: books.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 1.35 : 1.55,
              ),
              itemBuilder: (context, i) => _BookTile(book: books[i]),
            );
          },
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});
  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    return BwCard(
      color: AppColors.paperDeep,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      onTap: () => _openBook(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.usfm, style: AppType.mono(9, color: AppColors.inkFaded)),
          const Spacer(),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.body(
              17,
              color: AppColors.ink,
              weight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${book.chapters} CH', style: AppType.mono(8)),
              const Spacer(),
              Text('→', style: AppType.display(16, color: AppColors.inkFaded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookGroupData {
  const _BookGroupData(this.title, this.caption, this.books);
  final String title;
  final String caption;
  final List<BibleBook> books;
}

void _openBook(BuildContext context, BibleBook book) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => BibleBookScreen(book: book)));
}

List<BibleBook> _books(List<String> usfms) {
  return usfms.map((u) => kBibleBooks.firstWhere((b) => b.usfm == u)).toList();
}

final _oldGroups = <_BookGroupData>[
  _BookGroupData(
    'The Law',
    'Origins, covenant, and wilderness.',
    _books(['GEN', 'EXO', 'LEV', 'NUM', 'DEU']),
  ),
  _BookGroupData(
    'History',
    'Promise, kings, exile, and return.',
    _books([
      'JOS',
      'JDG',
      'RUT',
      '1SA',
      '2SA',
      '1KI',
      '2KI',
      '1CH',
      '2CH',
      'EZR',
      'NEH',
      'EST',
    ]),
  ),
  _BookGroupData(
    'Wisdom and Worship',
    'Prayer, poetry, suffering, and counsel.',
    _books(['JOB', 'PSA', 'PRO', 'ECC', 'SNG']),
  ),
  _BookGroupData(
    'Major Prophets',
    'Judgment, hope, and restoration.',
    _books(['ISA', 'JER', 'LAM', 'EZK', 'DAN']),
  ),
  _BookGroupData(
    'Minor Prophets',
    'Twelve shorter prophetic witnesses.',
    _books([
      'HOS',
      'JOL',
      'AMO',
      'OBA',
      'JON',
      'MIC',
      'NAM',
      'HAB',
      'ZEP',
      'HAG',
      'ZEC',
      'MAL',
    ]),
  ),
];

final _newGroups = <_BookGroupData>[
  _BookGroupData(
    'Gospels',
    'The life, words, death, and resurrection of Jesus.',
    _books(['MAT', 'MRK', 'LUK', 'JHN']),
  ),
  _BookGroupData(
    'Church Beginnings',
    'The Spirit sends the church into the world.',
    _books(['ACT']),
  ),
  _BookGroupData(
    'Pauline Letters',
    'Grace, formation, and life together.',
    _books([
      'ROM',
      '1CO',
      '2CO',
      'GAL',
      'EPH',
      'PHP',
      'COL',
      '1TH',
      '2TH',
      '1TI',
      '2TI',
      'TIT',
      'PHM',
    ]),
  ),
  _BookGroupData(
    'General Letters',
    'Faith, endurance, love, and holiness.',
    _books(['HEB', 'JAS', '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD']),
  ),
  _BookGroupData(
    'Apocalypse',
    'The Lamb, the church, and the coming kingdom.',
    _books(['REV']),
  ),
];
