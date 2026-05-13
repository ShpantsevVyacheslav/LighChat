import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/birthdays/data/birthday_date_utils.dart';

void main() {
  group('parseDobString', () {
    test('parses ISO 8601 date', () {
      final d = parseDobString('1990-05-15');
      expect(d, isNotNull);
      expect(d!.year, 1990);
      expect(d.month, 5);
      expect(d.day, 15);
    });

    test('parses ISO with time component', () {
      final d = parseDobString('1990-05-15T00:00:00.000Z');
      expect(d, isNotNull);
      expect(d!.month, 5);
      expect(d.day, 15);
    });

    test('parses legacy DD.MM.YYYY', () {
      final d = parseDobString('15.05.1990');
      expect(d, isNotNull);
      expect(d!.year, 1990);
      expect(d.month, 5);
      expect(d.day, 15);
    });

    test('returns null for null/empty/garbage', () {
      expect(parseDobString(null), isNull);
      expect(parseDobString(''), isNull);
      expect(parseDobString('  '), isNull);
      expect(parseDobString('not a date'), isNull);
    });
  });

  group('isBirthdayToday', () {
    test('matches same month and day', () {
      final dob = DateTime(1990, 5, 15);
      final today = DateTime(2026, 5, 15);
      expect(isBirthdayToday(dob, today), isTrue);
    });

    test('rejects mismatching day', () {
      final dob = DateTime(1990, 5, 15);
      final today = DateTime(2026, 5, 16);
      expect(isBirthdayToday(dob, today), isFalse);
    });

    test('rejects mismatching month', () {
      final dob = DateTime(1990, 5, 15);
      final today = DateTime(2026, 4, 15);
      expect(isBirthdayToday(dob, today), isFalse);
    });

    test('Feb 29 in leap year matches Feb 29', () {
      final dob = DateTime(2000, 2, 29);
      final today = DateTime(2024, 2, 29); // 2024 leap
      expect(isBirthdayToday(dob, today), isTrue);
    });

    test('Feb 29 in non-leap year falls back to Feb 28', () {
      final dob = DateTime(2000, 2, 29);
      final today = DateTime(2026, 2, 28); // 2026 not leap
      expect(isBirthdayToday(dob, today), isTrue);
    });

    test('Feb 29 in non-leap year does NOT match Feb 29 (which does not exist)',
        () {
      final dob = DateTime(2000, 2, 29);
      // DateTime(2026, 2, 29) rolls into Mar 1, so explicit Feb 28 is the test
      final marchFirst = DateTime(2026, 3, 1);
      expect(isBirthdayToday(dob, marchFirst), isFalse);
    });

    test('non-Feb-29 dob does NOT match Feb 28 in non-leap year', () {
      // регресс-тест на правило только для 29 февраля
      final dob = DateTime(1990, 2, 27);
      final feb28 = DateTime(2026, 2, 28);
      expect(isBirthdayToday(dob, feb28), isFalse);
    });
  });

  group('ageInYear', () {
    test('returns calendar-year difference', () {
      expect(ageInYear(DateTime(1990, 5, 15), DateTime(2026, 5, 15)), 36);
    });

    test('returns null for sentinel year < 1900', () {
      expect(ageInYear(DateTime(1899, 5, 15), DateTime(2026, 5, 15)), isNull);
    });
  });

  group('localYmd', () {
    test('pads single-digit month/day', () {
      expect(localYmd(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });
}
