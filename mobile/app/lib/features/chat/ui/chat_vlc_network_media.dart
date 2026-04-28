import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
/// Legacy filename kept intentionally to avoid broad import churn.
/// VLC dependency is removed; helpers now describe unsupported media and
/// server-side normalization state.

bool chatMediaRequiresServerNormalizationOnIos(String url, {String? mimeType}) {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.iOS) return false;
  // E2EE v2: расшифрованные локальные файлы (file:///...) не проходят через
  // серверный транскодинг — сервер не видит plaintext-байты. Поэтому любое
  // "ожидание нормализации" для них бесполезно и блокирует UI. Возвращаем
  // false, чтобы media-проигрыватели сразу пытались открыть локальный файл
  // (webm/ogg-форматы, если попадутся, — задача UI-плеера, а не placeholder).
  if (url.startsWith('file:')) return false;
  final path = url.split('?').first.toLowerCase();
  if (path.endsWith('.webm')) return true;
  final t = (mimeType ?? '').toLowerCase();
  return t.contains('webm');
}

enum ChatMediaNormUiState { none, pending, failed }

ChatMediaNormUiState chatMediaNormUiStateForAttachment({
  required ChatAttachment attachment,
  required int attachmentIndex,
  required ChatMediaNorm? mediaNorm,
}) {
  if (!chatMediaRequiresServerNormalizationOnIos(
    attachment.url,
    mimeType: attachment.type,
  )) {
    return ChatMediaNormUiState.none;
  }
  if (mediaNorm == null) {
    return ChatMediaNormUiState.pending;
  }
  if (mediaNorm.isFailed &&
      (mediaNorm.failedIndexes.isEmpty ||
          mediaNorm.isFailedIndex(attachmentIndex))) {
    return ChatMediaNormUiState.failed;
  }
  if (mediaNorm.isPending) {
    return ChatMediaNormUiState.pending;
  }
  return ChatMediaNormUiState.none;
}

class ChatMediaNormStatusWidget extends StatelessWidget {
  const ChatMediaNormStatusWidget({
    super.key,
    required this.state,
    required this.mediaKindLabel,
    this.onRetry,
    this.compact = false,
  });

  final ChatMediaNormUiState state;
  final String mediaKindLabel;
  final Future<void> Function()? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (state == ChatMediaNormUiState.none) return const SizedBox.shrink();
    final isPending = state == ChatMediaNormUiState.pending;
    final icon = isPending
        ? Icons.hourglass_top_rounded
        : Icons.error_outline_rounded;
    final title = isPending
        ? l10n.chat_media_norm_pending_title(mediaKindLabel)
        : l10n.chat_media_norm_failed_title(mediaKindLabel);
    final subtitle = isPending
        ? l10n.chat_media_norm_pending_subtitle
        : l10n.chat_media_norm_failed_subtitle;
    final padV = compact ? 8.0 : 12.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isPending ? scheme.primary : scheme.error).withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, padV, 12, padV),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPending ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (!isPending && onRetry != null)
              TextButton(
                onPressed: () async {
                  await onRetry!.call();
                },
                child: Text(l10n.common_retry),
              ),
          ],
        ),
      ),
    );
  }
}
