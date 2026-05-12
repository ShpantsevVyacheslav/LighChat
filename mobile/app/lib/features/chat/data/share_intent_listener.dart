import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'share_intent_payload.dart';
import 'package:lighchat_mobile/core/app_logger.dart';

/// Подписка на системный «Поделиться» (iOS Share Extension / Android
/// `ACTION_SEND(_MULTIPLE)`). При получении payload навигирует на
/// `/share` с уже распакованным [ShareIntentPayload] в `extra`.
///
/// Вызывается из `MyApp.initState` после `attachAppGoRouter` — поток ведёт
/// себя одинаково и при cold-start (через `getInitialMedia`), и пока
/// приложение в background/foreground (через `getMediaStream`).
class ShareIntentListener {
  ShareIntentListener._({required this.router});

  final GoRouter router;
  StreamSubscription<List<SharedMediaFile>>? _streamSub;

  /// Создать и подписаться. Возвращает экземпляр для последующего [dispose]
  /// в `MyApp.dispose`. Web/desktop платформы — no‑op.
  static Future<ShareIntentListener?> attach({required GoRouter router}) async {
    if (kIsWeb) return null;
    final l = ShareIntentListener._(router: router);
    await l._handleInitial();
    l._listenStream();
    return l;
  }

  Future<void> _handleInitial() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      _dispatch(initial);
      // Сбрасываем initial‑буфер, иначе при следующем cold‑start payload
      // вернётся повторно (контракт receive_sharing_intent).
      ReceiveSharingIntent.instance.reset();
    } catch (e, st) {
      appLogger.w('ShareIntentListener.initial failed', error: e, stackTrace: st);
    }
  }

  void _listenStream() {
    try {
      _streamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _dispatch,
        onError: (Object e, StackTrace st) {
          appLogger.w('ShareIntentListener.stream error', error: e, stackTrace: st);
        },
      );
    } catch (e, st) {
      appLogger.w('ShareIntentListener.stream attach failed', error: e, stackTrace: st);
    }
  }

  void _dispatch(List<SharedMediaFile> raw) {
    final payload = _normalize(raw);
    if (payload.isEmpty) return;
    // go() — replace, чтобы /share не накапливался в стеке при многократных
    // шерингах подряд. Если пользователь уже находится в каком‑то чате,
    // /share открывается поверх и после выбора цели возвращает в нужный
    // чат (тот же стек).
    router.go('/share', extra: payload);
  }

  ShareIntentPayload _normalize(List<SharedMediaFile> raw) {
    if (raw.isEmpty) return const ShareIntentPayload();
    final files = <XFile>[];
    String? sharedText;
    for (final m in raw) {
      switch (m.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          // text идёт в `path` (не file path). Не превращаем в файл.
          final t = m.path.trim();
          if (t.isNotEmpty) {
            sharedText = sharedText == null || sharedText.isEmpty
                ? t
                : '$sharedText\n$t';
          }
          break;
        case SharedMediaType.image:
        case SharedMediaType.video:
        case SharedMediaType.file:
          final p = m.path.trim();
          if (p.isEmpty) continue;
          // Имя выводим из последнего сегмента пути (iOS Share Extension
          // обычно сохраняет файлы с человекочитаемыми именами в App Group
          // shared container; Android даёт content:// path после копии в
          // cacheDir самим receive_sharing_intent).
          final name = p.contains('/') ? p.substring(p.lastIndexOf('/') + 1) : p;
          files.add(XFile(p, name: name, mimeType: m.mimeType));
          break;
      }
    }
    return ShareIntentPayload(files: files, text: sharedText);
  }

  Future<void> dispose() async {
    await _streamSub?.cancel();
    _streamSub = null;
  }
}
