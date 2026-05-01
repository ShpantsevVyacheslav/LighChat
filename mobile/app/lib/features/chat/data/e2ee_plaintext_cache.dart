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

import 'package:path_provider/path_provider.dart';

import 'local_storage_preferences.dart';

class E2eePlaintextCache {
  E2eePlaintextCache._();

  static final E2eePlaintextCache instance = E2eePlaintextCache._();

  Directory? _rootDir;
  Future<Directory>? _rootFuture;

  final Map<String, Map<String, String>> _textMemCache =
      <String, Map<String, String>>{};
  final Map<String, Future<void>> _textLoads = <String, Future<void>>{};

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
    final prefs = await LocalStoragePreferencesStore.load();
    if (!prefs.e2eeTextEnabled) return;
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
  }

  /// Очищает все E2EE кэши (используется при logout).
  Future<void> clearAll() async {
    _textMemCache.clear();
    try {
      final root = await _root();
      if (await root.exists()) {
        await root.delete(recursive: true);
        _rootDir = null;
        _rootFuture = null;
      }
    } catch (_) {}
  }
}
