import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import 'chat_cached_network_image.dart';
import 'message_html_text.dart';

/// Thin bar above the composer: shows who you reply to + preview; [onCancel] clears draft reply.
class ComposerReplyBanner extends StatelessWidget {
  const ComposerReplyBanner({
    super.key,
    required this.replyTo,
    required this.onCancel,
  });

  final ReplyContext replyTo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final raw = (replyTo.text ?? '').trim();
    final preview = raw.contains('<') ? messageHtmlToPlainText(raw) : raw;

    final thumb = _buildThumb(scheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.reply_rounded, size: 22, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyTo.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: scheme.primary),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                  ],
                ),
              ),
              if (thumb != null) ...[
                const SizedBox(width: 8),
                thumb,
              ],
              IconButton(
                tooltip: l10n.chat_reply_cancel_tooltip,
                onPressed: onCancel,
                icon: Icon(Icons.close_rounded, color: scheme.onSurface.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildThumb(ColorScheme scheme) {
    final url = (replyTo.mediaPreviewUrl ?? '').trim();
    final type = replyTo.mediaType;
    if (url.isEmpty && type == null) return null;

    Widget? content;
    if (type == 'audio') {
      content = _iconBox(scheme, Icons.mic_rounded);
    } else if (type == 'location') {
      content = _iconBox(scheme, Icons.place_rounded);
    } else if (type == 'poll') {
      content = _iconBox(scheme, Icons.poll_rounded);
    } else if (url.isNotEmpty) {
      content = ChatCachedNetworkImage(
        url: url,
        fit: BoxFit.cover,
        compact: true,
      );
    }
    if (content == null) return null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: 28, height: 28, child: content),
    );
  }

  Widget _iconBox(ColorScheme scheme, IconData icon) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      ),
      child: Icon(
        icon,
        size: 18,
        color: scheme.onSurface.withValues(alpha: 0.70),
      ),
    );
  }
}
