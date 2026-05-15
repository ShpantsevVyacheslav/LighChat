import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Системный поиск iOS — CoreSpotlight.
///
/// Индексируем чаты и pinned-сообщения как `CSSearchableItem` чтобы
/// пользователь мог найти их через свайп вниз → Spotlight. На Android
/// аналог (App Search API) пока не реализован — `isAvailable()` вернёт
/// `false`, методы — no-op.
class SpotlightIndexer {
  SpotlightIndexer._();
  static final SpotlightIndexer instance = SpotlightIndexer._();

  static const _channel = MethodChannel('lighchat/spotlight');
  static const _stream = EventChannel('lighchat/spotlight_events');

  bool? _availableCache;
  Stream<SpotlightActivation>? _liveStream;

  /// Доступна ли индексация на этом устройстве. Кешируется на время сессии.
  Future<bool> isAvailable() async {
    final cached = _availableCache;
    if (cached != null) return cached;
    if (kIsWeb || !Platform.isIOS) {
      _availableCache = false;
      return false;
    }
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      _availableCache = v == true;
    } catch (_) {
      _availableCache = false;
    }
    return _availableCache!;
  }

  /// Добавить/обновить список items в индексе. Идемпотентно по [SpotlightItem.uid].
  Future<void> index(List<SpotlightItem> items) async {
    if (items.isEmpty) return;
    if (!await isAvailable()) return;
    try {
      await _channel.invokeMethod<void>('index', <String, Object?>{
        'items': items.map((i) => i.toMap()).toList(),
      });
    } catch (_) {/* silent */}
  }

  /// Удалить items из индекса.
  Future<void> remove(List<String> uids) async {
    if (uids.isEmpty) return;
    if (!await isAvailable()) return;
    try {
      await _channel.invokeMethod<void>('remove', <String, Object?>{
        'ids': uids,
      });
    } catch (_) {}
  }

  /// Полностью очистить наш индекс — вызывать при logout/смене аккаунта,
  /// иначе чужие чаты будут видны в Spotlight нового пользователя.
  Future<void> removeAll() async {
    if (!await isAvailable()) return;
    try {
      await _channel.invokeMethod<void>('removeAll');
    } catch (_) {}
  }

  /// Cold-start: если приложение открыли тапом по Spotlight-результату,
  /// возвращаем payload. Иначе — null.
  Future<SpotlightActivation?> consumeLaunchActivity() async {
    if (!await isAvailable()) return null;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'consumeLaunchActivity',
      );
      if (raw == null) return null;
      return SpotlightActivation.fromMap(raw);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: построить SpotlightItem из списка conversations + их
  /// pinned messages и проиндексировать одним пакетом. Сами вырезаем
  /// сервисные/пустые чаты, остальное — index.
  Future<void> indexConversations({
    required List<ConversationWithId> conversations,
    required String currentUserId,
  }) async {
    if (!await isAvailable()) return;
    final items = <SpotlightItem>[];
    for (final c in conversations) {
      final title = _conversationTitle(c, currentUserId);
      if (title.isEmpty) continue;
      final preview = (c.data.lastMessageText ?? '').trim();
      // Keywords — имена всех участников (помогает найти чат по имени).
      final keywords = <String>{};
      final info = c.data.participantInfo;
      if (info != null) {
        for (final p in info.values) {
          final n = p.name.trim();
          if (n.isNotEmpty) keywords.add(n);
        }
      }
      items.add(SpotlightItem(
        uid: 'chat:${c.id}',
        title: title,
        subtitle: preview.isEmpty ? null : preview,
        keywords: keywords.toList(growable: false),
      ));

      // Pinned messages: каждое pinned-сообщение → отдельный
      // SpotlightItem с uid `pin:<convId>:<msgId>`. При тапе в Spotlight
      // юзер попадает в чат с якорем на это сообщение (см. main.dart).
      final pins = c.data.pinnedMessages;
      if (pins != null) {
        for (final p in pins) {
          final pinText = p.text.trim();
          if (pinText.isEmpty) continue;
          items.add(SpotlightItem(
            uid: 'pin:${c.id}:${p.messageId}',
            // В title — текст пина (обрезанный), это то по чему юзер ищет.
            title: pinText.length > 80
                ? '${pinText.substring(0, 77)}…'
                : pinText,
            // В subtitle — контекст: «📌 в чате с <X>» / «📌 <автор> в <группа>»
            subtitle: '📌 ${p.senderName.trim()} · $title',
            keywords: [
              ...keywords,
              if (p.senderName.trim().isNotEmpty) p.senderName.trim(),
            ],
          ));
        }
      }
    }
    await index(items);
  }

  static String _conversationTitle(
    ConversationWithId c,
    String currentUserId,
  ) {
    if (c.data.isGroup) {
      return (c.data.name ?? '').trim();
    }
    // DM: имя «другого» участника из participantInfo.
    final info = c.data.participantInfo;
    if (info != null) {
      for (final entry in info.entries) {
        if (entry.key != currentUserId) {
          return entry.value.name.trim();
        }
      }
    }
    return '';
  }

  /// Live-стрим активаций пока приложение запущено (handoff в foreground).
  Stream<SpotlightActivation> get activations {
    return _liveStream ??= _stream
        .receiveBroadcastStream()
        .map<SpotlightActivation>((raw) =>
            SpotlightActivation.fromMap(raw as Map<dynamic, dynamic>))
        .asBroadcastStream();
  }
}

/// Один индексируемый элемент: чат или закреп-сообщение.
class SpotlightItem {
  const SpotlightItem({
    required this.uid,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.keywords = const <String>[],
  });

  /// Формат:
  ///  - `chat:<conversationId>` — для чата
  ///  - `pin:<conversationId>:<messageId>` — для pinned-сообщения
  final String uid;
  final String title;
  final String? subtitle;

  /// Абсолютный путь к локальному файлу-аватарке (или `null`).
  final String? imagePath;

  /// Доп. ключевые слова — помогают Spotlight ранжировать.
  final List<String> keywords;

  Map<String, Object?> toMap() => <String, Object?>{
        'uid': uid,
        'title': title,
        if (subtitle != null && subtitle!.trim().isNotEmpty) 'subtitle': subtitle,
        if (imagePath != null && imagePath!.isNotEmpty) 'imagePath': imagePath,
        if (keywords.isNotEmpty) 'keywords': keywords,
      };
}

/// Активация = пользователь тапнул на нашем результате в Spotlight.
class SpotlightActivation {
  const SpotlightActivation({
    required this.uid,
    required this.kind,
    this.conversationId,
    this.messageId,
  });

  /// Исходный uid (как был indexed).
  final String uid;

  /// `chat` | `pin` | прочее.
  final String kind;
  final String? conversationId;
  final String? messageId;

  static SpotlightActivation fromMap(Map<dynamic, dynamic> raw) {
    return SpotlightActivation(
      uid: (raw['uid'] as String?) ?? '',
      kind: (raw['kind'] as String?) ?? 'unknown',
      conversationId: raw['conversationId'] as String?,
      messageId: raw['messageId'] as String?,
    );
  }
}
