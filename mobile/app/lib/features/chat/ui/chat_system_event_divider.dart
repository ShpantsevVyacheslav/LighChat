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
import '../../../l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// WhatsApp-style bubble для call-событий в timeline чата.
/// Выравнивается вправо/влево в зависимости от того, кто звонил.
class ChatCallBubble extends StatelessWidget {
  const ChatCallBubble({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.createdAt,
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  final ChatSystemEvent event;
  final String currentUserId;
  final DateTime createdAt;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final callerId = event.data?['callerId'] as String?;
    final isMine = callerId == currentUserId;
    final isVideo = event.data?['isVideo'] == true;
    final isMissed = event.type == ChatSystemEventType.callMissed;

    final label = isMissed
        ? l10n.system_event_call_missed
        : l10n.system_event_call_cancelled;

    final bubbleColor = isMine
        ? (outgoingBubbleColor ?? theme.colorScheme.primaryContainer)
        : (theme.colorScheme.surfaceContainerHighest);

    final onBubble = isMine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    final iconColor = isMissed
        ? Colors.red.shade400
        : onBubble.withValues(alpha: 0.55);

    final local = createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideo ? Icons.videocam_outlined : Icons.phone_outlined,
                size: 24,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: onBubble),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onBubble.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    final icon = _pickIcon(event.type);
    final label = _renderText(l10n, event, actorName);

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
      case ChatSystemEventType.gameLobbyCreated:
        return Icons.style_rounded;
      case ChatSystemEventType.gameStarted:
        return Icons.sports_esports_rounded;
      case ChatSystemEventType.callMissed:
        return Icons.call_missed_outlined;
      case ChatSystemEventType.callCancelled:
        return Icons.call_end_outlined;
    }
  }

  static String _renderText(AppLocalizations l10n, ChatSystemEvent event, String? actorNameOverride) {
    final data = event.data ?? const {};
    final actor =
        actorNameOverride ??
        (data['actorName'] is String ? data['actorName'] as String : null) ??
        l10n.system_event_default_actor;
    final deviceLabel = data['deviceLabel'] is String
        ? data['deviceLabel'] as String
        : l10n.system_event_default_device;
    switch (event.type) {
      case ChatSystemEventType.e2eeV2Enabled:
        return l10n.system_event_e2ee_enabled(0);
      case ChatSystemEventType.e2eeV2Disabled:
        return l10n.system_event_e2ee_disabled;
      case ChatSystemEventType.e2eeV2EpochRotated:
        return l10n.system_event_e2ee_epoch_rotated;
      case ChatSystemEventType.e2eeV2DeviceAdded:
        return l10n.system_event_e2ee_device_added(actor, deviceLabel);
      case ChatSystemEventType.e2eeV2DeviceRevoked:
        return l10n.system_event_e2ee_device_revoked(actor, deviceLabel);
      case ChatSystemEventType.e2eeV2FingerprintChanged:
        return l10n.system_event_e2ee_fingerprint_changed(actor);
      case ChatSystemEventType.gameLobbyCreated:
        return l10n.system_event_game_lobby_created;
      case ChatSystemEventType.gameStarted:
        return l10n.system_event_game_started;
      case ChatSystemEventType.callMissed:
        return l10n.system_event_call_missed;
      case ChatSystemEventType.callCancelled:
        return l10n.system_event_call_cancelled;
    }
  }
}
