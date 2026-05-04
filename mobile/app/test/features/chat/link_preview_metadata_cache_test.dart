import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/link_preview_metadata.dart';

/// Регресс-тест: кеш обязан возвращать **одну и ту же** ссылку на `Future`
/// при повторных `get(url)` — иначе `FutureBuilder` сбрасывает `_snapshot`
/// в `ConnectionState.waiting` на каждом ребилде ленты, и карточка ссылки
/// мерцает skeleton↔content, ломая высоту строки в `CustomScrollView`.
void main() {
  group('LinkPreviewMetadataCache.get identity', () {
    test('returns the same Future instance for the same URL while in flight', () {
      final cache = LinkPreviewMetadataCache();
      // Используем заведомо невалидный сайт — http-запрос провалится по таймауту,
      // нам важна идентичность Future до резолва, не результат.
      final f1 = cache.get('https://example.invalid/some-page');
      final f2 = cache.get('https://example.invalid/some-page');
      expect(identical(f1, f2), isTrue);
    });

    test('returns the same Future instance after URL resolves', () async {
      final cache = LinkPreviewMetadataCache();
      final url = 'https://example.invalid/some-page';
      final f1 = cache.get(url);
      // Дожидаемся завершения (с null-результатом — фейл fetch),
      // имитируя «карточка уже видела данные».
      await f1;
      final f2 = cache.get(url);
      expect(
        identical(f1, f2),
        isTrue,
        reason:
            'After resolution, the cache must keep returning the SAME Future instance '
            'so FutureBuilder.widget.future stays stable across rebuilds.',
      );
    });

    test('different URLs get different Futures', () {
      final cache = LinkPreviewMetadataCache();
      final f1 = cache.get('https://example.invalid/a');
      final f2 = cache.get('https://example.invalid/b');
      expect(identical(f1, f2), isFalse);
    });

    test('clear() drops cached Futures, next get returns a fresh one', () async {
      final cache = LinkPreviewMetadataCache();
      final url = 'https://example.invalid/c';
      final f1 = cache.get(url);
      await f1;
      cache.clear();
      final f2 = cache.get(url);
      expect(identical(f1, f2), isFalse);
    });

    test('invalid URL returns Future<null> without caching', () {
      final cache = LinkPreviewMetadataCache();
      final f1 = cache.get('not-a-url');
      final f2 = cache.get('not-a-url');
      // Невалидный URL не попадает в кеш — каждый вызов отдаёт свежий Future.value(null).
      // Это не критично для UI, т.к. карточка не строит превью для пустых URL.
      expect(identical(f1, f2), isFalse);
    });
  });

  group('LinkPreviewMetadataCache.peekResolved (sync path)', () {
    test('возвращает (false, null) до первого запроса', () {
      final cache = LinkPreviewMetadataCache();
      final r = cache.peekResolved('https://example.invalid/a');
      expect(r.isResolved, isFalse);
      expect(r.data, isNull);
    });

    test('возвращает (false, null) пока запрос в полёте', () async {
      final cache = LinkPreviewMetadataCache();
      // Не await — Future ещё не зарезолвен.
      final inflight = cache.get('https://example.invalid/b');
      final r = cache.peekResolved('https://example.invalid/b');
      expect(r.isResolved, isFalse);
      expect(r.data, isNull);
      await inflight; // на всякий случай дожидаемся, чтобы тест не висел
    });

    test('возвращает (true, null) после неуспешного резолва', () async {
      final cache = LinkPreviewMetadataCache();
      final url = 'https://example.invalid/c';
      await cache.get(url); // зарезолвится в null (host lookup fail)
      final r = cache.peekResolved(url);
      expect(r.isResolved, isTrue);
      expect(r.data, isNull);
    });

    test('peekResolved нечувствителен к фрагменту/трейлинг-слешу нормализации',
        () async {
      final cache = LinkPreviewMetadataCache();
      // Кеш нормализует (отбрасывает fragment) — поэтому оба URL должны
      // указывать на один и тот же ключ.
      await cache.get('https://example.invalid/d#fragment');
      final r = cache.peekResolved('https://example.invalid/d');
      expect(r.isResolved, isTrue);
    });

    test('clear() сбрасывает sync-кеш', () async {
      final cache = LinkPreviewMetadataCache();
      final url = 'https://example.invalid/e';
      await cache.get(url);
      expect(cache.peekResolved(url).isResolved, isTrue);
      cache.clear();
      expect(cache.peekResolved(url).isResolved, isFalse);
    });
  });
}
