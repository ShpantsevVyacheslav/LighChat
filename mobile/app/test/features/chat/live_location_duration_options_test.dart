import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/live_location_duration_options.dart';

/// Bug #8: расширенный sheet long-press показывает гранулярные опции
/// `m5`/`m15`/`m30`/`h1`/`h2`/`h6`/`d1`. Все они должны существовать
/// в `kLiveLocationDurationOptions` (источник истины), иначе sheet
/// рендерит row с лейблом '[id]' — это видимый регресс.
void main() {
  group('liveLocationDurationOptions — Bug #8 granular IDs', () {
    test('канонический набор id присутствует', () {
      final ids = kLiveLocationDurationOptions.map((o) => o.id).toSet();
      for (final id in const ['m5', 'm15', 'm30', 'h1', 'h2', 'h6', 'd1']) {
        expect(ids.contains(id), isTrue, reason: 'отсутствует $id');
      }
    });

    test('durationMs соответствует id (m5=5min, h2=2h, d1=24h)', () {
      final byId = {for (final o in kLiveLocationDurationOptions) o.id: o};
      expect(byId['m5']!.durationMs, 5 * 60 * 1000);
      expect(byId['m15']!.durationMs, 15 * 60 * 1000);
      expect(byId['m30']!.durationMs, 30 * 60 * 1000);
      expect(byId['h1']!.durationMs, 60 * 60 * 1000);
      expect(byId['h2']!.durationMs, 2 * 60 * 60 * 1000);
      expect(byId['h6']!.durationMs, 6 * 60 * 60 * 1000);
      expect(byId['d1']!.durationMs, 24 * 60 * 60 * 1000);
    });

    test('`once` и `forever` имеют durationMs == null', () {
      final byId = {for (final o in kLiveLocationDurationOptions) o.id: o};
      expect(byId['once']?.durationMs, isNull);
      expect(byId['forever']?.durationMs, isNull);
    });
  });

  group('liveLocationExpiresAtForDurationId', () {
    test('`once` и `forever` → null (моментальная отправка / бесконечно)',
        () {
      expect(liveLocationExpiresAtForDurationId('once'), isNull);
      expect(liveLocationExpiresAtForDurationId('forever'), isNull);
    });

    test('m5 → +5 минут (с допуском 5 секунд от now)', () {
      final iso = liveLocationExpiresAtForDurationId('m5');
      expect(iso, isNotNull);
      final dt = DateTime.parse(iso!).toUtc();
      final expected = DateTime.now().toUtc().add(const Duration(minutes: 5));
      expect(
        (dt.difference(expected)).abs().inSeconds < 5,
        isTrue,
        reason: 'дельта = ${dt.difference(expected).inSeconds}с',
      );
    });

    test('h2 → +2 часа (с допуском 5 секунд)', () {
      final dt = DateTime.parse(liveLocationExpiresAtForDurationId('h2')!).toUtc();
      final expected = DateTime.now().toUtc().add(const Duration(hours: 2));
      expect((dt.difference(expected)).abs().inSeconds < 5, isTrue);
    });

    test('d1 → +24 часа', () {
      final dt = DateTime.parse(liveLocationExpiresAtForDurationId('d1')!).toUtc();
      final expected = DateTime.now().toUtc().add(const Duration(hours: 24));
      expect((dt.difference(expected)).abs().inSeconds < 5, isTrue);
    });

    test('until_end_of_day → конец сегодняшнего локального дня', () {
      final iso = liveLocationExpiresAtForDurationId('until_end_of_day');
      expect(iso, isNotNull);
      final dt = DateTime.parse(iso!);
      final localEnd = DateTime.now();
      final endOfDay =
          DateTime(localEnd.year, localEnd.month, localEnd.day, 23, 59, 59);
      // Сравниваем по локальному календарному моменту, не UTC.
      expect(
        (dt.toLocal().difference(endOfDay)).abs().inMinutes < 1,
        isTrue,
      );
    });

    test('неизвестный id → null', () {
      expect(liveLocationExpiresAtForDurationId('bogus'), isNull);
    });
  });

  group('liveLocationDurationActivatesUserShare', () {
    test('`once` НЕ активирует user-live-share', () {
      expect(liveLocationDurationActivatesUserShare('once'), isFalse);
    });

    test('все остальные id (m5/h1/d1/forever/...) активируют', () {
      for (final id in const [
        'm5',
        'm15',
        'm30',
        'h1',
        'h2',
        'h6',
        'd1',
        'forever',
        'until_end_of_day',
      ]) {
        expect(
          liveLocationDurationActivatesUserShare(id),
          isTrue,
          reason: id,
        );
      }
    });
  });
}
