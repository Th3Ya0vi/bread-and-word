import 'package:flutter_test/flutter_test.dart';

import 'package:bread_and_word/services/reading_progress.dart';

void main() {
  group('ReadingProgress eastern date', () {
    test('keeps the previous day before midnight Eastern', () {
      final beforeMidnightEastern = DateTime.utc(2026, 6, 28, 3, 59);

      expect(
        ReadingProgress.easternDateKey(beforeMidnightEastern),
        '2026-06-27',
      );
    });

    test('rolls over at midnight Eastern during daylight time', () {
      final midnightEastern = DateTime.utc(2026, 6, 28, 4);

      expect(ReadingProgress.easternDateKey(midnightEastern), '2026-06-28');
    });

    test('rolls over at midnight Eastern during standard time', () {
      final midnightEastern = DateTime.utc(2026, 12, 15, 5);

      expect(ReadingProgress.easternDateKey(midnightEastern), '2026-12-15');
    });
  });
}
