import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'meeting_invite_link.dart';

/// Подписка на открытие `https://…/meetings/…` из браузера / «Открыть в приложении».
///
/// **iOS:** полноценные Universal Links требуют платную подписку **Apple Developer Program**
/// (не Personal Team): в Xcode → Signing & Capabilities → Associated Domains, плюс
/// `applinks:lighchat.online` в `Runner*.entitlements`. Без этого ссылка открывается в Safari.
///
/// **Android:** при верифицированном `assetlinks.json` и подписи приложения ссылки ведут в приложение.
///
/// Вызывать один раз при старте (см. [main.dart]): cold start — [AppLinks.getInitialLink],
/// warm — [AppLinks.uriLinkStream].
Future<StreamSubscription<Uri>> attachMeetingWebDeepLinks(GoRouter router) async {
  final appLinks = AppLinks();
  try {
    final initial = await appLinks.getInitialLink();
    if (initial != null) {
      final path = goRouterPathFromMeetingWebUri(initial);
      if (path != null) router.go(path);
    }
  } catch (e, st) {
    debugPrint('attachMeetingWebDeepLinks initial: $e\n$st');
  }

  return appLinks.uriLinkStream.listen((uri) {
    final path = goRouterPathFromMeetingWebUri(uri);
    if (path != null) router.go(path);
  });
}
