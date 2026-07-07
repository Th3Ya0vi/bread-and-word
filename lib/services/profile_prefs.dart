import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local profile preferences: how the member appears in community, and their
/// daily streak. Observable so screens react when they change.
class ProfilePrefs {
  ProfilePrefs._();
  static final ProfilePrefs instance = ProfilePrefs._();

  static const _anonKey = 'profile_anonymous';
  static const _streakKey = 'profile_streak';
  static const _lastOpenKey = 'profile_last_open';
  static const _noteKey = 'profile_note';

  static const defaultNote = 'Be still, and know that I am God.';

  /// When true, the member appears under a gentle pseudonym across the
  /// community instead of their account name.
  final ValueNotifier<bool> anonymous = ValueNotifier<bool>(false);

  /// Consecutive days the app has been opened.
  final ValueNotifier<int> streak = ValueNotifier<int>(0);

  /// A private verse or line the member keeps for themselves on the Me page.
  final ValueNotifier<String> noteToSelf = ValueNotifier<String>(defaultNote);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      anonymous.value = p.getBool(_anonKey) ?? false;
      streak.value = p.getInt(_streakKey) ?? 0;
      noteToSelf.value = p.getString(_noteKey) ?? defaultNote;
    } catch (_) {}
  }

  Future<void> setAnonymous(bool value) async {
    anonymous.value = value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_anonKey, value);
    } catch (_) {}
  }

  Future<void> setNote(String value) async {
    final v = value.trim().isEmpty ? defaultNote : value.trim();
    noteToSelf.value = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_noteKey, v);
    } catch (_) {}
  }

  /// Update the streak on launch: +1 on a consecutive day, reset after a gap.
  Future<void> bumpStreak() async {
    try {
      final p = await SharedPreferences.getInstance();
      final today = _dayStamp(DateTime.now());
      final last = p.getInt(_lastOpenKey);
      var s = p.getInt(_streakKey) ?? 0;
      if (last == today) {
        // already counted today
      } else if (last == today - 1) {
        s += 1;
      } else {
        s = 1;
      }
      await p.setInt(_streakKey, s);
      await p.setInt(_lastOpenKey, today);
      streak.value = s;
    } catch (_) {}
  }

  static int _dayStamp(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
