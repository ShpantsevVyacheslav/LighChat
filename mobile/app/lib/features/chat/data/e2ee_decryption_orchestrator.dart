/// Orchestrator-виджет для Phase 4 E2EE read-path.
///
/// Зачем отдельный файл:
///  - изоляция E2EE-логики (user-rule #1): `ChatMessageList` остаётся чистым,
///    этот файл знает про `MobileE2eeRuntime`, Riverpod и Firebase;
///  - одна реализация переиспользуется в `chat_screen.dart` и `thread_screen.dart`;
///  - state (`decryptedById`, `failedIds`) локализован в `State`, не переживает
///    logout и не течёт между чатами.
///
/// Public API: [E2eeMessagesResolver] — билдер, который принимает список
/// сообщений и отдаёт дочернему виджету готовые `decryptedTextByMessageId`
/// и `failedMessageIds`. Дочерний виджет (обычно `ChatMessageList`) не знает
/// о крипто — он просто получает готовые данные.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'e2ee_runtime.dart';

typedef E2eeMessagesBuilder = Widget Function(
  BuildContext context,
  Map<String, String> decryptedTextByMessageId,
  Set<String> failedMessageIds,
);

class E2eeMessagesResolver extends ConsumerStatefulWidget {
  const E2eeMessagesResolver({
    super.key,
    required this.conversationId,
    required this.messages,
    required this.builder,
  });

  final String conversationId;

  /// Полный список сообщений в чате. Дешифрует только те, у которых есть
  /// `e2eePayload`. При изменении списка новые E2EE-сообщения автоматически
  /// ставятся в очередь.
  final List<ChatMessage> messages;

  final E2eeMessagesBuilder builder;

  @override
  ConsumerState<E2eeMessagesResolver> createState() =>
      _E2eeMessagesResolverState();
}

class _E2eeMessagesResolverState extends ConsumerState<E2eeMessagesResolver> {
  final Map<String, String> _decrypted = <String, String>{};
  final Set<String> _failed = <String>{};
  final Set<String> _inFlight = <String>{};
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _scheduleDecryptionPass();
  }

  @override
  void didUpdateWidget(covariant E2eeMessagesResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // При переходе между чатами state обнуляем, чтобы не смешать ключи.
      _decrypted.clear();
      _failed.clear();
      _inFlight.clear();
    }
    _scheduleDecryptionPass();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _scheduleDecryptionPass() {
    final runtime = ref.read(mobileE2eeRuntimeProvider);
    if (runtime == null) return;
    for (final m in widget.messages) {
      final payload = m.e2eePayload;
      if (payload == null) continue;
      if (_decrypted.containsKey(m.id)) continue;
      if (_failed.contains(m.id)) continue;
      if (_inFlight.contains(m.id)) continue;
      _inFlight.add(m.id);
      unawaited(_decryptOne(runtime, m.id, payload));
    }
  }

  Future<void> _decryptOne(
    MobileE2eeRuntime runtime,
    String messageId,
    ChatMessageE2eePayload payload,
  ) async {
    try {
      final res = await runtime.decryptMessage(
        conversationId: widget.conversationId,
        messageId: messageId,
        payload: payload,
      );
      if (_disposed) return;
      setState(() {
        _inFlight.remove(messageId);
        if (res.ok) {
          _decrypted[messageId] = res.plaintext!;
        } else {
          _failed.add(messageId);
        }
      });
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _inFlight.remove(messageId);
        _failed.add(messageId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _decrypted, _failed);
  }
}
