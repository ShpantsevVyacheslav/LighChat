import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/user_profile.dart';
import 'message_html_text.dart';

/// Карточка предпросмотра пересылаемых сообщений (аналог web `ForwardingMessagePreview`).
class ForwardMessagePreview extends StatelessWidget {
  const ForwardMessagePreview({
    super.key,
    required this.messages,
    required this.profilesById,
  });

  final List<ChatMessage> messages;
  final Map<String, UserProfile> profilesById;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < messages.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: scheme.primary.withValues(alpha: 0.12)),
                ),
              _ForwardPreviewEntry(message: messages[i], profilesById: profilesById),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForwardPreviewEntry extends StatelessWidget {
  const _ForwardPreviewEntry({
    required this.message,
    required this.profilesById,
  });

  final ChatMessage message;
  final Map<String, UserProfile> profilesById;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final senderName = profilesById[message.senderId]?.name ?? 'Неизвестный';
    final raw = message.text ?? '';
    final previewText = raw.trim().isEmpty
        ? (message.attachments.isNotEmpty ? 'Вложение' : 'Сообщение')
        : (raw.contains('<') ? messageHtmlToPlainText(raw) : raw.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_quote_rounded, size: 14, color: scheme.primary.withValues(alpha: 0.45)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 4),
          child: Text(
            previewText,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.25,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
