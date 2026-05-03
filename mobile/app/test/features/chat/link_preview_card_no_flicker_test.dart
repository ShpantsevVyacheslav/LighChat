import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-тест, который инструментирует ИМЕННО то поведение, что давало
/// «дёрганье» ленты чата вокруг ссылок:
///
/// 1. `_BrokenCache` — старая логика: для уже зарезолвенного URL отдаёт
///    `Future.value(...)` каждый раз заново. Это поведение — точная копия
///    pre-fix `LinkPreviewMetadataCache.get` (см. git show 10c8d04^).
///
/// 2. `_FixedCache` — новая логика: хранит тот же `Future` после ресолва
///    и переиспользует его. Это поведение текущего файла
///    `link_preview_metadata.dart` после фикса.
///
/// Проверяем: на каждом парент-ребилде «сломанная» версия гонит
/// `FutureBuilder` обратно в `ConnectionState.waiting` — это и есть
/// мерцание skeleton↔content, которое визуально выглядит как «дёрганье».
/// «Починенная» версия НЕ должна возвращаться в waiting после первого
/// ресолва.
void main() {
  testWidgets(
    'BROKEN cache: FutureBuilder возвращается в waiting на каждом парент-ребилде',
    (tester) async {
      final cache = _BrokenCache<String>(value: 'data');
      final stats = await _runRebuildScenario(tester, cache.get);

      // На «сломанном» кеше каждый ребилд парента (мы делаем 4) приводит
      // к одному кадру skeleton + одному кадру content. Итого:
      // initial: 1 waiting + 1 done = 2 frames
      // 4 rebuilds × 2 frames each = 8
      // Всего минимум 4 раза увидим waiting (после initial).
      expect(stats.waitingFrames, greaterThanOrEqualTo(5),
          reason: 'broken cache must re-enter waiting on every rebuild');
      expect(stats.skeletonShownAfterInitialResolve, isTrue,
          reason: 'broken cache: skeleton снова показывается после ресолва — это и есть баг');
    },
  );

  testWidgets(
    'FIXED cache: FutureBuilder НЕ возвращается в waiting после первого ресолва',
    (tester) async {
      final cache = _FixedCache<String>(value: 'data');
      final stats = await _runRebuildScenario(tester, cache.get);

      // На «починенном» кеше: 1 waiting (initial) + N×done (rebuilds).
      expect(stats.waitingFrames, equals(1),
          reason: 'fixed cache must show waiting only once (initial frame)');
      expect(stats.skeletonShownAfterInitialResolve, isFalse,
          reason: 'fixed cache: после первого ресолва skeleton больше не показывается');
      expect(stats.doneFrames, greaterThanOrEqualTo(5),
          reason: 'после ресолва каждый парент-ребилд должен оставлять FutureBuilder в done');
    },
  );

  testWidgets(
    'FIXED cache: высота карточки стабильна на всех парент-ребилдах',
    (tester) async {
      // Здесь поверх той же логики проверяем, что физическая высота
      // финального содержимого не прыгает. Берём последовательные
      // высоты на каждом кадре после ресолва.
      final cache = _FixedCache<String>(value: 'data');
      final heights = await _captureHeightsAcrossRebuilds(tester, cache.get);

      // Всё после ресолва должно иметь одинаковую (контентную) высоту.
      // Убираем первый кадр (skeleton 24px), оставляем content (60px).
      final stable = heights.skip(1).toSet();
      expect(stable.length, 1,
          reason: 'после первого ресолва высота карточки не должна меняться');
    },
  );

  testWidgets(
    'BROKEN cache: высота карточки прыгает skeleton↔content на каждом парент-ребилде',
    (tester) async {
      final cache = _BrokenCache<String>(value: 'data');
      final heights = await _captureHeightsAcrossRebuilds(tester, cache.get);

      // На сломанном кеше встречаются обе высоты skeleton (24) и content (60).
      expect(heights.toSet().length, greaterThan(1),
          reason: 'broken cache: высота должна осциллировать');
    },
  );
}

class _Stats {
  int waitingFrames = 0;
  int doneFrames = 0;
  bool skeletonShownAfterInitialResolve = false;
}

Future<_Stats> _runRebuildScenario(
  WidgetTester tester,
  Future<String?> Function() getFuture,
) async {
  final stats = _Stats();
  bool initialResolved = false;
  final rebuildKey = GlobalKey<_RebuildHostState>();

  Widget probe(BuildContext _, AsyncSnapshot<String?> snap) {
    if (snap.connectionState != ConnectionState.done) {
      stats.waitingFrames++;
      if (initialResolved) stats.skeletonShownAfterInitialResolve = true;
      return const SizedBox(key: ValueKey('skeleton'), height: 24);
    }
    stats.doneFrames++;
    return const SizedBox(key: ValueKey('content'), height: 60);
  }

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: _RebuildHost(
        key: rebuildKey,
        child: (_) => FutureBuilder<String?>(future: getFuture(), builder: probe),
      ),
    ),
  ));

  // Первый кадр — waiting (skeleton).
  expect(stats.waitingFrames, 1);

  // Дожидаемся ресолва Future.
  await tester.pumpAndSettle();
  initialResolved = true;
  expect(stats.doneFrames, greaterThanOrEqualTo(1));

  // 4 парент-ребилда — это эквивалент того, что делает чат-лента
  // во время скролла (sticky-day update, ScrollNotification и т.п.).
  for (var i = 0; i < 4; i++) {
    rebuildKey.currentState!.bump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  return stats;
}

Future<List<double>> _captureHeightsAcrossRebuilds(
  WidgetTester tester,
  Future<String?> Function() getFuture,
) async {
  final heights = <double>[];
  final rebuildKey = GlobalKey<_RebuildHostState>();
  final probeKey = GlobalKey();

  Widget probe(BuildContext _, AsyncSnapshot<String?> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return SizedBox(key: probeKey, height: 24);
    }
    return SizedBox(key: probeKey, height: 60);
  }

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: _RebuildHost(
        key: rebuildKey,
        child: (_) => FutureBuilder<String?>(future: getFuture(), builder: probe),
      ),
    ),
  ));
  heights.add(tester.getSize(find.byKey(probeKey)).height);

  await tester.pumpAndSettle();
  heights.add(tester.getSize(find.byKey(probeKey)).height);

  for (var i = 0; i < 4; i++) {
    rebuildKey.currentState!.bump();
    await tester.pump();
    heights.add(tester.getSize(find.byKey(probeKey)).height);
  }

  return heights;
}

// ────────────────────────────────────────────────────────────────────────────
// Имитация «сломанного» / «починенного» кеша. Не зависим от http — внутри
// просто Future, чтобы изолировать суть бага: identity widget.future в
// FutureBuilder.

class _BrokenCache<T> {
  _BrokenCache({required this.value});
  final T? value;
  final _completer = Completer<T?>();
  bool _resolved = false;

  Future<T?> get() {
    if (_resolved) {
      // Старая логика: НОВЫЙ Future для каждого вызова после ресолва.
      return Future.value(value);
    }
    // Первый вызов: запустить «асинхронный fetch» через микротаску.
    if (!_completer.isCompleted) {
      Future.microtask(() {
        _completer.complete(value);
        _resolved = true;
      });
    }
    return _completer.future;
  }
}

class _FixedCache<T> {
  _FixedCache({required this.value});
  final T? value;
  Future<T?>? _future;

  Future<T?> get() {
    return _future ??= Future<T?>.microtask(() => value);
  }
}

class _RebuildHost extends StatefulWidget {
  const _RebuildHost({super.key, required this.child});
  final WidgetBuilder child;

  @override
  State<_RebuildHost> createState() => _RebuildHostState();
}

class _RebuildHostState extends State<_RebuildHost> {
  int _bumps = 0;

  void bump() {
    setState(() => _bumps++);
  }

  @override
  Widget build(BuildContext context) {
    // bumps в дереве отдельной строкой — чтобы родитель FutureBuilder
    // менял что-то в каждом ребилде (имитируем sticky-day label etc).
    return Column(
      children: [
        Text('bumps: $_bumps'),
        widget.child(context),
      ],
    );
  }
}
