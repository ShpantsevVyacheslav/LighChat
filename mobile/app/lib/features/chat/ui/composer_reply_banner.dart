import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
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
}
