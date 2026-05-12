import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

/// Подписка на собственную URL-схему `lighchat://` для desktop.
///
/// Поддерживаемые формы:
///   `lighchat://chat/{conversationId}`     → /chats/{conversationId}
///   `lighchat://meeting/{meetingId}`       → /meetings/{meetingId}
///   `lighchat://user/{uid}`                → /contacts/user/{uid}
///   `lighchat://admin/{section}`           → /admin/{section}
///   `lighchat://settings`                  → /settings
///
/// Регистрация:
///   - macOS: `Info.plist` → `CFBundleURLTypes` (см. macos/Runner/Info.plist).
///   - Windows: MSIX `protocol_activation: lighchat` (см. pubspec.yaml).
///   - Linux: `.desktop` файл с `MimeType=x-scheme-handler/lighchat;`
///     (см. .github/workflows/desktop.yml → AppImage packaging).
class DesktopDeepLinks {
  DesktopDeepLinks._();
  static final DesktopDeepLinks instance = DesktopDeepLinks._();

  StreamSubscription<Uri>? _sub;

  Future<void> attach(GoRouter router) async {
    final appLinks = AppLinks();

    // Cold start: приложение запущено по клику на lighchat:// URL.
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        final path = _toRoute(initial);
        if (path != null) router.go(path);
      }
    } catch (e, st) {
      appLogger.w('[deep-link] initial failed', error: e, stackTrace: st);
    }

    await _sub?.cancel();
    _sub = appLinks.uriLinkStream.listen(
      (uri) {
        final path = _toRoute(uri);
        if (path != null) router.go(path);
      },
      onError: (Object e, StackTrace st) {
        appLogger.w('[deep-link] stream error', error: e);
      },
    );
  }

  Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  String? _toRoute(Uri uri) {
    if (uri.scheme != 'lighchat') return null;
    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);
    final host = uri.host;
    final head = host.isNotEmpty ? host : (segments.isEmpty ? '' : segments[0]);
    final rest = host.isNotEmpty ? segments : segments.skip(1).toList();

    switch (head) {
      case 'chat':
      case 'chats':
        if (rest.isEmpty) return '/chats';
        return '/chats/${Uri.encodeComponent(rest.first)}';
      case 'meeting':
      case 'meetings':
        if (rest.isEmpty) return '/meetings';
        return '/meetings/${Uri.encodeComponent(rest.first)}';
      case 'user':
      case 'contact':
        if (rest.isEmpty) return '/contacts';
        return '/contacts/user/${Uri.encodeComponent(rest.first)}';
      case 'admin':
        if (rest.isEmpty) return '/admin';
        return '/admin/${Uri.encodeComponent(rest.first)}';
      case 'settings':
        return '/settings';
      case 'auth':
        return '/auth';
      default:
        appLogger.d('[deep-link] unsupported: $uri');
        return null;
    }
  }
}
