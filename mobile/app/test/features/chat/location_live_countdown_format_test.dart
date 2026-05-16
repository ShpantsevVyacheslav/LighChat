import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/chat/ui/location_live_countdown.dart';

/// Regression tests для Bug #16 — формат остатка времени.
/// До фикса было mm:ss («688:00»), стало человеко-читаемое
/// «11ч 28м» / «28м» / mm:ss только в финальную минуту.
///
/// `_label()` приватный — проверяем через rendered Text.
void main() {
  Future<String> renderLabel(WidgetTester tester, String iso) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: LocationLiveCountdown(expiresAtIso: iso),
        ),
      ),
    );
    // Первый build уже отрисовал актуальный label.
    final widget = tester.widget<Text>(find.byType(Text));
    return widget.data ?? '';
  }

  testWidgets('Bug #16: > 1 часа → «Xч Yм» (например 11ч 28м)',
      (tester) async {
    // expires через 11h 28m 33s от now → ожидаем «11ч 28м».
    final exp = DateTime.now().add(
      const Duration(hours: 11, minutes: 28, seconds: 33),
    );
    final label = await renderLabel(tester, exp.toUtc().toIso8601String());
    expect(
      RegExp(r'^11ч 2[78]м$').hasMatch(label),
      isTrue,
      reason: 'got "$label"',
    );
  });

  testWidgets('Bug #16: 1ч ровно → «1ч 0м» (не «60м»)', (tester) async {
    final exp = DateTime.now().add(
      const Duration(hours: 1, seconds: 5),
    );
    final label = await renderLabel(tester, exp.toUtc().toIso8601String());
    expect(label, anyOf('1ч 0м', '0ч 59м'));
  });

  testWidgets('Bug #16: 5 минут → «5м» / «4м» (округление вниз)',
      (tester) async {
    final exp = DateTime.now().add(
      const Duration(minutes: 5, seconds: 5),
    );
    final label = await renderLabel(tester, exp.toUtc().toIso8601String());
    expect(RegExp(r'^[45]м$').hasMatch(label), isTrue, reason: 'got "$label"');
  });

  testWidgets('Bug #16: < 1 минуты → fallback mm:ss', (tester) async {
    final exp = DateTime.now().add(const Duration(seconds: 42));
    final label = await renderLabel(tester, exp.toUtc().toIso8601String());
    // 0:42 ± 1 секунда (между парсингом и рендером).
    expect(
      RegExp(r'^0:[34][0-9]$').hasMatch(label),
      isTrue,
      reason: 'got "$label" (ожидалось формат 0:XX)',
    );
  });

  testWidgets('Bug #16: уже истёкло → «0м»', (tester) async {
    final exp = DateTime.now().subtract(const Duration(minutes: 5));
    final label = await renderLabel(tester, exp.toUtc().toIso8601String());
    expect(label, '0м');
  });

  testWidgets('Bug #16: невалидный ISO → «—»', (tester) async {
    final label = await renderLabel(tester, 'not-a-date');
    expect(label, '—');
  });
}
