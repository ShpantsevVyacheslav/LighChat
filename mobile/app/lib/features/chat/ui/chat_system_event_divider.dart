/// Phase 8 — mobile-рендер system-маркера E2EE v2 в timeline чата.
///
/// Зеркало web-компонента `src/components/chat/ChatSystemEventDivider.tsx`:
/// рендерит компактный центр-выровненный «pill» вместо bubble, когда
/// у сообщения проставлен [ChatSystemEvent].
///
/// Что делает: читает тип события, подбирает иконку и локализованную подпись,
/// оборачивает в капсулу `muted/50` цветового скейла темы.
/// Где используется: вызывается из builder'а `ChatMessageList`, если
/// `message.systemEvent != null` и `message.senderId == '__system__'`.
/// Почему безопасно: чистый presentational widget, не меняет контрактов и
/// не затрагивает остальной рендер bubble'ов.

library;

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

class ChatSystemEventDivider extends StatelessWidget {
  const ChatSystemEventDivider({
    super.key,
    required this.event,
    this.actorName,
  });

  final ChatSystemEvent event;

  /// Имя актора, если доступно в профилях (fallback — из `event.data`).
  final String? actorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _pickIcon(event.type);
    final label = _renderText(event, actorName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _pickIcon(ChatSystemEventType type) {
    switch (type) {
      case ChatSystemEventType.e2eeV2Enabled:
        return Icons.lock_outline;
      case ChatSystemEventType.e2eeV2Disabled:
        return Icons.lock_open_outlined;
      case ChatSystemEventType.e2eeV2EpochRotated:
        return Icons.refresh;
      case ChatSystemEventType.e2eeV2DeviceAdded:
        return Icons.smartphone_outlined;
      case ChatSystemEventType.e2eeV2DeviceRevoked:
        return Icons.shield_outlined;
      case ChatSystemEventType.e2eeV2FingerprintChanged:
        return Icons.fingerprint;
    }
  }

  static String _renderText(ChatSystemEvent event, String? actorNameOverride) {
    final data = event.data ?? const {};
    final actor =
        actorNameOverride ??
        (data['actorName'] is String ? data['actorName'] as String : null) ??
        'Пользователь';
    final deviceLabel =
        data['deviceLabel'] is String
            ? data['deviceLabel'] as String
            : 'устройство';
    switch (event.type) {
      case ChatSystemEventType.e2eeV2Enabled:
        return 'Сквозное шифрование включено';
      case ChatSystemEventType.e2eeV2Disabled:
        return 'Сквозное шифрование отключено';
      case ChatSystemEventType.e2eeV2EpochRotated:
        return 'Ключ шифрования обновлён';
      case ChatSystemEventType.e2eeV2DeviceAdded:
        return '$actor добавил устройство «$deviceLabel»';
      case ChatSystemEventType.e2eeV2DeviceRevoked:
        return '$actor отозвал устройство «$deviceLabel»';
      case ChatSystemEventType.e2eeV2FingerprintChanged:
        return 'Отпечаток безопасности у $actor изменился';
    }
  }
}
