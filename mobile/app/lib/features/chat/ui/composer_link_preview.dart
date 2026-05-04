import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/link_preview_metadata.dart';

final LinkPreviewMetadataCache _composerLinkPreviewCache =
    LinkPreviewMetadataCache();

/// Карточка превью ссылки над полем ввода (как в Telegram/WhatsApp).
///
/// Показывается когда пользователь набрал http(s)-ссылку, но ещё не отправил
/// сообщение. Можно скрыть крестиком — после этого превью для этой ссылки
/// больше не показывается до нового URL.
class ComposerLinkPreview extends StatelessWidget {
  const ComposerLinkPreview({
    super.key,
    required this.url,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final border = scheme.onSurface.withValues(alpha: dark ? 0.18 : 0.12);
    final bg = (dark ? Colors.white : scheme.surfaceContainerHigh)
        .withValues(alpha: dark ? 0.08 : 0.92);
    final accent = scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<LinkPreviewMetadata?>(
        future: _composerLinkPreviewCache.get(url),
        builder: (context, snap) {
          final data = snap.data;
          final isLoading = snap.connectionState != ConnectionState.done;
          if (!isLoading && data == null) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                if (data?.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      data!.imageUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLoading
                            ? AppLocalizations.of(context)!.composer_link_preview_loading
                            : (data?.title ?? url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoading
                            ? url
                            : (data?.description ??
                                  data?.siteName ??
                                  url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.composer_link_preview_hide_tooltip,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: onDismiss,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
