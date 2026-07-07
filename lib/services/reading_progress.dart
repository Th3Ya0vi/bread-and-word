import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which of TODAY's devotional items the member has completed.
///
/// Completion is keyed to the current calendar date (yyyy-MM-dd) so it resets
/// automatically each day: on [load], if the stored date no longer matches
/// today, the set is cleared.
///
/// Item keys are stable strings: 'verse', 'reflection', and 'reading_0',
/// 'reading_1', 'reading_2' for the three reading-plan passages.
class ReadingProgress {
  ReadingProgress._();
  static final ReadingProgress instance = ReadingProgress._();

  static const _dateKey = 'reading_progress_date';
  static const _doneKey = 'reading_progress_done';

  /// Observable set of completed item keys for today. Screens listen to this
  /// so the UI reacts the moment an item is marked read.
  final ValueNotifier<Set<String>> completedToday = ValueNotifier<Set<String>>(
    <String>{},
  );

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final storedDate = p.getString(_dateKey);
      final today = _today();
      if (storedDate != today) {
        // A new day — wipe yesterday's progress.
        await p.setString(_dateKey, today);
        await p.remove(_doneKey);
        completedToday.value = <String>{};
        return;
      }
      completedToday.value = (p.getStringList(_doneKey) ?? const <String>[])
          .toSet();
    } catch (_) {
      completedToday.value = <String>{};
    }
  }

  bool isDone(String key) => completedToday.value.contains(key);

  /// Mark [key] complete for today and persist it. Idempotent.
  Future<void> setDone(String key) async {
    if (completedToday.value.contains(key)) return;
    final next = {...completedToday.value, key};
    completedToday.value = next;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_dateKey, _today());
      await p.setStringList(_doneKey, next.toList());
    } catch (_) {}
  }

  static String _today() => easternDateKey();

  /// Calendar date in US Eastern time. The app's devotional day turns over at
  /// midnight in New York, independent of the member's device timezone.
  static String easternDateKey([DateTime? now]) {
    final eastern = easternNow(now);
    final mm = eastern.month.toString().padLeft(2, '0');
    final dd = eastern.day.toString().padLeft(2, '0');
    return '${eastern.year}-$mm-$dd';
  }

  static int easternDayOfYear([DateTime? now]) {
    final eastern = easternNow(now);
    return eastern.difference(DateTime(eastern.year, 1, 1)).inDays + 1;
  }

  static DateTime easternNow([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    final offset = _isEasternDaylightTime(utc)
        ? const Duration(hours: -4)
        : const Duration(hours: -5);
    return utc.add(offset);
  }

  static bool _isEasternDaylightTime(DateTime utc) {
    final year = utc.year;
    final start = DateTime.utc(year, 3, _nthSunday(year, 3, 2), 7);
    final end = DateTime.utc(year, 11, _nthSunday(year, 11, 1), 6);
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  static int _nthSunday(int year, int month, int n) {
    final first = DateTime.utc(year, month, 1);
    final daysUntilSunday = DateTime.sunday - first.weekday;
    final firstSunday =
        1 + (daysUntilSunday < 0 ? daysUntilSunday + 7 : daysUntilSunday);
    return firstSunday + ((n - 1) * 7);
  }
}
