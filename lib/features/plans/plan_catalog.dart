import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A single day of a reading plan: a short title, one or more YouVersion
/// passage references (e.g. "PRO.3.5-6", "JHN.15.9-17"), and an optional
/// reflection prompt to sit with.
class PlanDay {
  const PlanDay({
    required this.title,
    required this.references,
    this.prompt,
  });

  final String title;
  final List<String> references;
  final String? prompt;

  /// A compact display reference for headers and room banners, e.g.
  /// "Proverbs 3:5-6 · Psalm 32:8".
  String get label => references.map(prettyRef).join(' · ');
}

/// A curated reading plan. Content lives in the app (the YouVersion API
/// doesn't expose plans) while the passages are read live from YouVersion.
class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.about,
    required this.glyph,
    required this.icon,
    required this.days,
  });

  final String id;
  final String title;
  final String subtitle;
  final String about;

  /// A single serif character used as the plan's mark (no images, by design).
  final String glyph;
  final IconData icon;
  final List<PlanDay> days;

  int get length => days.length;
}

ReadingPlan? planById(String id) {
  for (final p in kReadingPlans) {
    if (p.id == id) return p;
  }
  return null;
}

/// Turn a YouVersion reference like "JHN.1" or "PRO.3.5-6" into something
/// readable: "John 1", "Proverbs 3:5-6".
String prettyRef(String ref) {
  final parts = ref.split('.');
  if (parts.isEmpty) return ref;
  final book = _bookNames[parts[0].toUpperCase()] ?? parts[0];
  if (parts.length == 1) return book;
  if (parts.length == 2) return '$book ${parts[1]}';
  return '$book ${parts[1]}:${parts.sublist(2).join('-').replaceAll('.', ':')}';
}

const _bookNames = <String, String>{
  'GEN': 'Genesis', 'EXO': 'Exodus', 'DEU': 'Deuteronomy', 'JOS': 'Joshua',
  'PSA': 'Psalm', 'PRO': 'Proverbs', 'ECC': 'Ecclesiastes', 'SNG': 'Song',
  'ISA': 'Isaiah', 'JER': 'Jeremiah', 'LAM': 'Lamentations',
  'NEH': 'Nehemiah', 'HAB': 'Habakkuk', 'ZEP': 'Zephaniah',
  'MAT': 'Matthew', 'MRK': 'Mark', 'LUK': 'Luke', 'JHN': 'John',
  'ACT': 'Acts', 'ROM': 'Romans', '1CO': '1 Corinthians',
  '2CO': '2 Corinthians', 'GAL': 'Galatians', 'EPH': 'Ephesians',
  'PHP': 'Philippians', 'COL': 'Colossians', '1TH': '1 Thessalonians',
  '2TI': '2 Timothy', 'HEB': 'Hebrews', 'JAS': 'James', '1PE': '1 Peter',
  '2PE': '2 Peter', '1JN': '1 John', 'REV': 'Revelation',
};

/// The curated catalog — topical journeys for where life actually finds you.
/// Each can be read in a sitting a day, alone or together in a live room.
const kReadingPlans = <ReadingPlan>[
  ReadingPlan(
    id: 'in-uncertainty',
    title: 'In Uncertainty',
    subtitle: '7 days · when the path is unclear',
    about:
        'When you can’t see the next step, Scripture steadies the heart. Seven '
        'days of learning to trust the God who holds your future when you '
        'cannot see it.',
    glyph: 'U',
    icon: PhosphorIconsRegular.compass,
    days: [
      PlanDay(title: 'Trust, Don’t Lean', references: ['PRO.3.5-6'],
          prompt: 'Where are you leaning on your own understanding?'),
      PlanDay(title: 'He Will Guide You', references: ['PSA.32.8']),
      PlanDay(title: 'Higher Than Your Ways', references: ['ISA.55.8-9']),
      PlanDay(title: 'Plans to Give You Hope', references: ['JER.29.11-13'],
          prompt: 'What future are you afraid to hand over?'),
      PlanDay(title: 'Do Not Worry', references: ['MAT.6.25-34']),
      PlanDay(title: 'He Works All Things', references: ['ROM.8.28']),
      PlanDay(title: 'Commit Your Way', references: ['PSA.37.3-7'],
          prompt: 'Name the thing you will entrust to Him today.'),
    ],
  ),
  ReadingPlan(
    id: 'for-joy',
    title: 'For Joy',
    subtitle: '7 days · rediscovering gladness in God',
    about:
        'Joy isn’t the absence of trouble — it’s the presence of God in it. '
        'Seven days to find again the deep, durable gladness Scripture promises.',
    glyph: 'J',
    icon: PhosphorIconsRegular.sun,
    days: [
      PlanDay(title: 'Fullness of Joy', references: ['PSA.16'],
          prompt: 'Where have you been looking for joy apart from Him?'),
      PlanDay(title: 'Rejoice Always', references: ['PHP.4.4-9']),
      PlanDay(title: 'That My Joy May Be in You', references: ['JHN.15.9-17']),
      PlanDay(title: 'Joy Comes in the Morning', references: ['PSA.30']),
      PlanDay(title: 'Filled With Joy and Peace', references: ['ROM.15.13']),
      PlanDay(title: 'Yet I Will Rejoice', references: ['HAB.3.17-19'],
          prompt: 'Can you praise Him even before the harvest?'),
      PlanDay(title: 'A Living Hope', references: ['1PE.1.3-9']),
    ],
  ),
  ReadingPlan(
    id: 'praying-for-breakthrough',
    title: 'Praying for Breakthrough',
    subtitle: '7 days · faith that keeps knocking',
    about:
        'For the prayer you’ve almost stopped praying. Seven days on bold, '
        'persistent, believing prayer — and the God who is able to do far more '
        'than we ask.',
    glyph: 'B',
    icon: PhosphorIconsRegular.door,
    days: [
      PlanDay(title: 'Always Pray, Never Give Up', references: ['LUK.18.1-8'],
          prompt: 'What have you stopped asking God for? Begin again.'),
      PlanDay(title: 'Ask, Seek, Knock', references: ['MAT.7.7-11']),
      PlanDay(title: 'The Prayer of Faith', references: ['JAS.5.13-18']),
      PlanDay(title: 'He Heard My Cry', references: ['PSA.40.1-5']),
      PlanDay(title: 'Far More Than We Ask', references: ['EPH.3.14-21'],
          prompt: 'What would “immeasurably more” look like here?'),
      PlanDay(title: 'Believe You Have Received', references: ['MRK.11.22-25']),
      PlanDay(title: 'A New Thing', references: ['ISA.43.18-19'],
          prompt: 'Where might God be making a way you haven’t seen yet?'),
    ],
  ),
  ReadingPlan(
    id: 'when-anxious',
    title: 'When You’re Anxious',
    subtitle: '7 days · peace over worry',
    about:
        'For the racing mind and the tight chest. Seven days of casting your '
        'cares on the One who cares for you, and receiving a peace that guards '
        'the heart.',
    glyph: 'A',
    icon: PhosphorIconsRegular.wind,
    days: [
      PlanDay(title: 'The Peace That Guards', references: ['PHP.4.4-9'],
          prompt: 'Turn one worry into a specific, thankful prayer.'),
      PlanDay(title: 'Consider the Birds', references: ['MAT.6.25-34']),
      PlanDay(title: 'Cast Your Cares', references: ['1PE.5.6-11']),
      PlanDay(title: 'When Anxiety Was Great', references: ['PSA.94.18-19']),
      PlanDay(title: 'My Peace I Give You', references: ['JHN.14.25-27']),
      PlanDay(title: 'Do Not Fear', references: ['ISA.41.10'],
          prompt: 'Hear Him say it to you by name: do not fear.'),
      PlanDay(title: 'He Will Sustain You', references: ['PSA.55.22']),
    ],
  ),
  ReadingPlan(
    id: 'through-grief',
    title: 'Through Grief',
    subtitle: '7 days · comfort in loss',
    about:
        'Grief is love with nowhere to go. Seven days to bring your sorrow '
        'honestly to the God who is near the brokenhearted and wipes every tear.',
    glyph: 'G',
    icon: PhosphorIconsRegular.handHeart,
    days: [
      PlanDay(title: 'Near the Brokenhearted', references: ['PSA.34.15-22'],
          prompt: 'Tell God plainly where it hurts.'),
      PlanDay(title: 'Blessed Are Those Who Mourn', references: ['MAT.5.1-12']),
      PlanDay(title: 'Jesus Wept', references: ['JHN.11.17-44']),
      PlanDay(title: 'The Lord Is My Shepherd', references: ['PSA.23']),
      PlanDay(title: 'The God of All Comfort', references: ['2CO.1.3-7']),
      PlanDay(title: 'He Heals the Brokenhearted', references: ['PSA.147.1-6']),
      PlanDay(title: 'No More Tears', references: ['REV.21.1-7'],
          prompt: 'Hold on to the promise of all things made new.'),
    ],
  ),
  ReadingPlan(
    id: 'a-grateful-heart',
    title: 'A Grateful Heart',
    subtitle: '5 days · thanksgiving as a way of life',
    about:
        'Gratitude reorders the soul. Five days of counting His mercies and '
        'learning to give thanks in all circumstances.',
    glyph: 'T',
    icon: PhosphorIconsRegular.flowerLotus,
    days: [
      PlanDay(title: 'Forget Not His Benefits', references: ['PSA.103'],
          prompt: 'List three mercies from this week.'),
      PlanDay(title: 'Give Thanks in All Things', references: ['1TH.5.12-24']),
      PlanDay(title: 'Enter With Thanksgiving', references: ['PSA.100']),
      PlanDay(title: 'Let the Word Dwell Richly', references: ['COL.3.12-17']),
      PlanDay(title: 'Content in Him', references: ['PHP.4.10-20'],
          prompt: 'Where can contentment replace comparison today?'),
    ],
  ),
  ReadingPlan(
    id: 'gospel-of-john',
    title: 'The Gospel of John',
    subtitle: '21 days · a deeper journey',
    about:
        'When you’re ready for a longer walk: the fourth Gospel a chapter a '
        'day, from "In the beginning was the Word" to the risen Christ on the '
        'shore.',
    glyph: 'J',
    icon: PhosphorIconsRegular.bookOpenText,
    days: [
      PlanDay(title: 'The Word Made Flesh', references: ['JHN.1']),
      PlanDay(title: 'Water Into Wine', references: ['JHN.2']),
      PlanDay(title: 'Born Again', references: ['JHN.3']),
      PlanDay(title: 'The Woman at the Well', references: ['JHN.4']),
      PlanDay(title: 'Healing at the Pool', references: ['JHN.5']),
      PlanDay(title: 'The Bread of Life', references: ['JHN.6']),
      PlanDay(title: 'Rivers of Living Water', references: ['JHN.7']),
      PlanDay(title: 'The Light of the World', references: ['JHN.8']),
      PlanDay(title: 'The Man Born Blind', references: ['JHN.9']),
      PlanDay(title: 'The Good Shepherd', references: ['JHN.10']),
      PlanDay(title: 'The Raising of Lazarus', references: ['JHN.11']),
      PlanDay(title: 'A Grain of Wheat', references: ['JHN.12']),
      PlanDay(title: 'He Washed Their Feet', references: ['JHN.13']),
      PlanDay(title: 'The Way, the Truth, the Life', references: ['JHN.14']),
      PlanDay(title: 'The True Vine', references: ['JHN.15']),
      PlanDay(title: 'Your Grief Will Turn to Joy', references: ['JHN.16']),
      PlanDay(title: 'That They May Be One', references: ['JHN.17']),
      PlanDay(title: 'Betrayed and Arrested', references: ['JHN.18']),
      PlanDay(title: 'It Is Finished', references: ['JHN.19']),
      PlanDay(title: 'The Empty Tomb', references: ['JHN.20']),
      PlanDay(title: 'Breakfast on the Shore', references: ['JHN.21']),
    ],
  ),
];
