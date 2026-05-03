import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_media_layout_tokens.dart';
import 'chat_cached_network_image.dart';
import 'message_html_text.dart';

class MessageReplyPreview extends StatelessWidget {
  const MessageReplyPreview({
    super.key,
    required this.replyTo,
    required this.isMine,
    this.onOpenOriginal,
  });

  final ReplyContext replyTo;
  final bool isMine;
  /// Переход к исходному сообщению в истории (если задан).
  final VoidCallback? onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06);
    final border = isMine ? Colors.white.withValues(alpha: 0.35) : scheme.primary.withValues(alpha: 0.35);

    final rawText = (replyTo.text ?? '').trim();
    final preview = rawText.isEmpty ? AppLocalizations.of(context)!.reply_preview_message_fallback : (rawText.contains('<') ? messageHtmlToPlainText(rawText) : rawText);

    final hasThumb = (replyTo.mediaPreviewUrl ?? '').isNotEmpty;
    final textMax = ChatMediaLayoutTokens.messageBubbleMaxWidth -
        (hasThumb ? 44 : 16);

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: border, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: textMax.toDouble()),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyTo.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isMine ? Colors.white.withValues(alpha: 0.92) : scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMine ? Colors.white.withValues(alpha: 0.75) : scheme.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          if (hasThumb) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 20,
                height: 20,
                child: replyTo.mediaType == 'audio'
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 14,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      )
                    : ChatCachedNetworkImage(
                        url: replyTo.mediaPreviewUrl!,
                        fit: BoxFit.cover,
                        compact: true,
                      ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onOpenOriginal == null) {
      return inner;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenOriginal,
        borderRadius: BorderRadius.circular(14),
        child: inner,
      ),
    );
  }
}

