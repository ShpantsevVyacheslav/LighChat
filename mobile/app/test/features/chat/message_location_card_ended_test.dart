import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/features/chat/ui/message_location_card.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Regression tests для Bug #18 — scroll-jitter в серии «end of share».
/// Когда live-session УЖЕ закончилась, MessageLocationCard должна
/// мгновенно вернуть `_endedBubble` без `StreamBuilder` Firestore-snapshot'а.
/// Firebase в тестовом окружении не инициализирован — если код пойдёт
/// в StreamBuilder, упадёт `[core/no-app] No Firebase App '[DEFAULT]'`.
/// Этот тест ловит регресс ровно таким образом: «build не должен бросать».
void main() {
  ChatLocationShare expiredShare() {
    final past = DateTime.now().subtract(const Duration(hours: 1));
    return ChatLocationShare(
      lat: 55.75,
      lng: 37.61,
      mapsUrl: 'https://maps.example/?q=55.75,37.61',
      capturedAt: '2026-05-16T00:00:00Z',
      liveSession:
          ChatLocationLiveSession(expiresAt: past.toUtc().toIso8601String()),
    );
  }

  Future<void> mount(WidgetTester tester, ChatLocationShare share) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: MessageLocationCard(
            share: share,
            senderId: 'u_other',
            isMine: false,
            createdAt: DateTime.utc(2026, 5, 16, 0),
            showTimestamps: false,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'Bug #18: истёкшая liveSession → _endedBubble мгновенно, без Firebase',
      (tester) async {
    await mount(tester, expiredShare());
    // Если бы код полез в Firestore — тест свалился бы с no-app error.
    // Bug G: вместо ChatGlassPanel теперь простой DecoratedBox —
    // ищем по тексту «трансляц» (общий префикс для ru/en через
    // locale-aware AppLocalizations: в ru — «Трансляция», в en —
    // «broadcast»). Тест-render использует locale=ru.
    final ruText = find.textContaining('рансляц');
    final found = ruText.evaluate().isNotEmpty;
    expect(found, isTrue, reason: 'ended-bubble text not rendered');
  });

  testWidgets('Bug #18: рендер дешёвый — нет тяжёлых дочерних виджетов',
      (tester) async {
    await mount(tester, expiredShare());
    // AspectRatio, StreamBuilder и сетевая картинка не должны
    // создаваться для ended-bubble — иначе скролл серии «end of share»
    // будет дёргаться.
    expect(find.byType(StreamBuilder<Object?>), findsNothing);
    expect(find.byType(AspectRatio), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
      'isMine → текст «вашей трансляции» / !isMine → «контакта» (en fallback)',
      (tester) async {
    final share = expiredShare();
    // Тестируем оба isMine отдельно.
    for (final mine in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: MessageLocationCard(
              share: share,
              senderId: 'u',
              isMine: mine,
              createdAt: DateTime.utc(2026, 5, 16, 0),
              showTimestamps: false,
            ),
          ),
        ),
      );
      // Один из двух текстов должен совпасть с известными ключами.
      final mineText =
          find.textContaining('Location broadcast ended');
      final otherText = find.textContaining(
          "This contact's location broadcast has ended");
      expect(
        mine ? mineText.evaluate().isNotEmpty : otherText.evaluate().isNotEmpty,
        isTrue,
        reason: 'isMine=$mine',
      );
    }
  });
}
