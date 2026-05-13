import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/features/birthdays/data/birthday_cache_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('BirthdayCacheEntry', () {
    test('isFresh true within TTL', () {
      final e = BirthdayCacheEntry(
        dob: '1990-05-15',
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      expect(e.isFresh, isTrue);
    });

    test('isFresh false past TTL', () {
      final e = BirthdayCacheEntry(
        dob: '1990-05-15',
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
      );
      expect(e.isFresh, isFalse);
    });

    test('round-trips through JSON', () {
      final original = BirthdayCacheEntry(
        dob: '1990-05-15',
        fetchedAt: DateTime.utc(2026, 1, 1, 12),
      );
      final decoded = BirthdayCacheEntry.fromJson(original.toJson());
      expect(decoded, isNotNull);
      expect(decoded!.dob, '1990-05-15');
      expect(decoded.fetchedAt, original.fetchedAt);
    });

    test('null dob round-trips as null (negative cache)', () {
      final original = BirthdayCacheEntry(
        dob: null,
        fetchedAt: DateTime.utc(2026, 1, 1),
      );
      final decoded = BirthdayCacheEntry.fromJson(original.toJson());
      expect(decoded?.dob, isNull);
    });
  });

  group('BirthdayCacheStorage', () {
    test('saves and loads entries for owner', () async {
      const storage = BirthdayCacheStorage();
      final entries = {
        'uA': BirthdayCacheEntry(
          dob: '1990-05-15',
          fetchedAt: DateTime.utc(2026, 1, 1),
        ),
        'uB': BirthdayCacheEntry(
          dob: null,
          fetchedAt: DateTime.utc(2026, 1, 1),
        ),
      };

      await storage.save('owner-1', entries);
      final loaded = await storage.load('owner-1');

      expect(loaded.length, 2);
      expect(loaded['uA']?.dob, '1990-05-15');
      expect(loaded['uB']?.dob, isNull);
    });

    test('returns empty map when no data', () async {
      const storage = BirthdayCacheStorage();
      final loaded = await storage.load('owner-empty');
      expect(loaded, isEmpty);
    });

    test('returns empty map for blank owner id', () async {
      const storage = BirthdayCacheStorage();
      expect(await storage.load(''), isEmpty);
    });
  });

  group('BannerDismissedDate', () {
    test('round-trips YYYY-MM-DD', () async {
      expect(await loadBirthdayBannerDismissedDate(), isNull);
      await saveBirthdayBannerDismissedDate('2026-05-13');
      expect(await loadBirthdayBannerDismissedDate(), '2026-05-13');
    });
  });
}
