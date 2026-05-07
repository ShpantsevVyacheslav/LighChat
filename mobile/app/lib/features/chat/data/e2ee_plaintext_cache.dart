/// E2EE v2 — persistent-кэш расшифрованного текста и файлов.
///
/// Зачем:
///  - без кэша каждый повторный вход в чат (открыть-закрыть, переключение
///    между чатами, рестарт приложения) приводит к полному повтору
///    decrypt-пасса. Для истории из сотен сообщений это заметная задержка
///    и постоянная трата CPU на симметричную AES-GCM расшифровку.
///  - текст занимает мало, но decrypt требует участия keystore → дороже
///    чем чтение файла;
///  - для media мы и так пишем расшифрованные байты на диск, но в `temp/`,
///    который iOS/Android могут чистить в любой момент — поэтому переносим
///    в `applicationSupport/e2ee_media_cache/`.
///
/// Также храним `preview` — последний расшифрованный текст для каждого
/// диалога (один файл `preview.json` на всё приложение). Нужен потому, что
/// `conversations.lastMessageText` для E2EE-сообщений содержит плейсхолдер
/// «Зашифрованное сообщение» (серверу plaintext не доверяем). Без этого
/// кэша список чатов всегда показывал бы плейсхолдер. См. также веб-аналог
/// `src/lib/e2ee/plaintext-cache.ts`.
///
/// Потокобезопасность: конкурентные `put` для одного ключа завершатся
/// «последним писателем выиграл», для текста это безопасно (plaintext
/// детерминирован от ciphertext).
///
/// Безопасность: кэш plaintext на диске — компромисс скорости vs утечки
/// при компрометации устройства. Расшифровка «на лету» уже доступна
/// любому с доступом к root-ФС (приложение хранит device-key в secure
/// storage, но процесс может расшифровать). Поэтому хранение plaintext
/// не снижает модель угроз в нашем профиле.
///
/// Очистка: `clearConversation` — при удалении чата / logout.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Запись в preview-кэше для одного чата.
///
/// `ts` копирует `conversation.lastMessageTimestamp` сообщения, чей текст
/// в `text`. Если значения расходятся — значит поверх пришло более новое
/// сообщение, ещё не успевшее декодироваться, и кеш надо игнорировать
/// (показываем плейсхолдер вместо stale-текста).
@immutable
class E2eeConversationPreview {
  const E2eeConversationPreview({
    required this.text,
    required this.ts,
    required this.messageId,
  });

  final String text;
  final String ts;
  final String messageId;

  Map<String, Object?> toJson() => <String, Object?>{
        'text': text,
        'ts': ts,
        'messageId': messageId,
      };

  static E2eeConversationPreview? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final t = raw['text'];
    final ts = raw['ts'];
    final mid = raw['messageId'];
    if (t is! String || ts is! String || mid is! String) return null;
    return E2eeConversationPreview(text: t, ts: ts, messageId: mid);
  }
}

class E2eePlaintextCache {
  E2eePlaintextCache._();

  static final E2eePlaintextCache instance = E2eePlaintextCache._();

  Directory? _rootDir;
  Future<Directory>? _rootFuture;

  final Map<String, Map<String, String>> _textMemCache =
      <String, Map<String, String>>{};
  final Map<String, Future<void>> _textLoads = <String, Future<void>>{};

  final Map<String, E2eeConversationPreview> _previewMemCache =
      <String, E2eeConversationPreview>{};
  Future<void>? _previewLoadFuture;
  bool _previewLoaded = false;

  /// Тикает на каждое изменение preview-кэша. Подписчики (например,
  /// `chat_list_screen.dart`) делают `addListener(setState)`. Хранится
  /// в одном `ValueNotifier<int>` потому, что список чатов и так
  /// перерендеривается целиком, и нам важна только информация «что-то
  /// поменялось» — гранулярность по conversationId не требуется.
  ValueListenable<int> get previewRevision => _previewRevision;
  final ValueNotifier<int> _previewRevision = ValueNotifier<int>(0);

  Future<Directory> _root() async {
    if (_rootDir != null) return _rootDir!;
    _rootFuture ??= () async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/e2ee_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _rootDir = dir;
      return dir;
    }();
    return _rootFuture!;
  }

  Future<Directory> mediaDir(String conversationId) async {
    final root = await _root();
    final dir = Directory('${root.path}/media/$conversationId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _textFile(String conversationId) async {
    final root = await _root();
    final dir = Directory('${root.path}/text');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$conversationId.json');
  }

  /// Загружает (лениво, один раз на conversation) все расшифрованные тексты
  /// из файла в `_textMemCache`. Вызывается автоматически из [getText].
  Future<void> _ensureTextLoaded(String conversationId) async {
    if (_textMemCache.containsKey(conversationId)) return;
    final inFlight = _textLoads[conversationId];
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final fut = () async {
      try {
        final file = await _textFile(conversationId);
        if (!await file.exists()) {
          _textMemCache[conversationId] = <String, String>{};
          return;
        }
        final raw = await file.readAsString();
        if (raw.trim().isEmpty) {
          _textMemCache[conversationId] = <String, String>{};
          return;
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          _textMemCache[conversationId] = <String, String>{};
          return;
        }
        final out = <String, String>{};
        decoded.forEach((k, v) {
          if (k is String && v is String) out[k] = v;
        });
        _textMemCache[conversationId] = out;
      } catch (_) {
        _textMemCache[conversationId] = <String, String>{};
      } finally {
        _textLoads.remove(conversationId);
      }
    }();
    _textLoads[conversationId] = fut;
    await fut;
  }

  Future<String?> getText({
    required String conversationId,
    required String messageId,
  }) async {
    await _ensureTextLoaded(conversationId);
    return _textMemCache[conversationId]?[messageId];
  }

  /// Синхронный hit (без дисковой загрузки). Полезно для render path —
  /// если cache уже разогрет через `warmUp`, мы получаем мгновенный ответ.
  String? getTextSync({
    required String conversationId,
    required String messageId,
  }) {
    return _textMemCache[conversationId]?[messageId];
  }

  Future<void> warmUp(String conversationId) =>
      _ensureTextLoaded(conversationId);

  Future<void> putText({
    required String conversationId,
    required String messageId,
    required String plaintext,
  }) async {
    await _ensureTextLoaded(conversationId);
    final bucket = _textMemCache.putIfAbsent(
      conversationId,
      () => <String, String>{},
    );
    if (bucket[messageId] == plaintext) return; // no-op
    bucket[messageId] = plaintext;
    unawaited(_persistText(conversationId));
  }

  Future<void> _persistText(String conversationId) async {
    try {
      final bucket = _textMemCache[conversationId];
      if (bucket == null) return;
      final file = await _textFile(conversationId);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(bucket), flush: true);
      // Атомарная замена: на Android/iOS rename того же volume атомарно.
      await tmp.rename(file.path);
    } catch (_) {
      // best-effort persistence — silently ignore IO errors.
    }
  }

  Future<void> clearConversation(String conversationId) async {
    _textMemCache.remove(conversationId);
    try {
      final file = await _textFile(conversationId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    try {
      final dir = await mediaDir(conversationId);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    final hadPreview = _previewMemCache.remove(conversationId) != null;
    if (hadPreview) {
      unawaited(_persistPreviews());
      _bumpPreviewRevision();
    }
  }

  /// Очищает все E2EE кэши (используется при logout).
  Future<void> clearAll() async {
    _textMemCache.clear();
    final hadPreviews = _previewMemCache.isNotEmpty;
    _previewMemCache.clear();
    _previewLoaded = false;
    _previewLoadFuture = null;
    try {
      final root = await _root();
      if (await root.exists()) {
        await root.delete(recursive: true);
        _rootDir = null;
        _rootFuture = null;
      }
    } catch (_) {}
    if (hadPreviews) _bumpPreviewRevision();
  }

  // -------------------------------------------------------------------------
  // Preview cache (lastMessageText fallback для списка чатов)
  // -------------------------------------------------------------------------

  Future<File> _previewFile() async {
    final root = await _root();
    return File('${root.path}/preview.json');
  }

  Future<void> _ensurePreviewLoaded() async {
    if (_previewLoaded) return;
    final inFlight = _previewLoadFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final fut = () async {
      try {
        final file = await _previewFile();
        if (!await file.exists()) return;
        final raw = await file.readAsString();
        if (raw.trim().isEmpty) return;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return;
        decoded.forEach((k, v) {
          if (k is! String) return;
          final rec = E2eeConversationPreview.fromJson(v);
          if (rec != null) _previewMemCache[k] = rec;
        });
      } catch (_) {
        // best-effort
      } finally {
        _previewLoaded = true;
        _previewLoadFuture = null;
      }
    }();
    _previewLoadFuture = fut;
    await fut;
    _bumpPreviewRevision();
  }

  /// Прогревает preview-кэш с диска. Вызывается из `chat_list_screen.dart`
  /// при первом построении списка чатов.
  Future<void> warmUpPreviews() => _ensurePreviewLoaded();

  /// Синхронный hit (без дисковой загрузки). Безопасно вызывать в build():
  /// если кэш ещё не разогрет — вернёт null.
  E2eeConversationPreview? getPreviewSync(String conversationId) {
    if (!_previewLoaded) return null;
    return _previewMemCache[conversationId];
  }

  Future<void> putPreview({
    required String conversationId,
    required String text,
    required String ts,
    required String messageId,
  }) async {
    if (text.isEmpty) return;
    await _ensurePreviewLoaded();
    final existing = _previewMemCache[conversationId];
    final next = E2eeConversationPreview(
      text: text,
      ts: ts,
      messageId: messageId,
    );
    if (existing != null &&
        existing.text == next.text &&
        existing.ts == next.ts &&
        existing.messageId == next.messageId) {
      return;
    }
    _previewMemCache[conversationId] = next;
    _bumpPreviewRevision();
    unawaited(_persistPreviews());
  }

  Future<void> _persistPreviews() async {
    try {
      final file = await _previewFile();
      final tmp = File('${file.path}.tmp');
      final json = <String, Object?>{};
      _previewMemCache.forEach((k, v) {
        json[k] = v.toJson();
      });
      await tmp.writeAsString(jsonEncode(json), flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      // best-effort persistence — silently ignore IO errors.
    }
  }

  void _bumpPreviewRevision() {
    _previewRevision.value = _previewRevision.value + 1;
  }
}
