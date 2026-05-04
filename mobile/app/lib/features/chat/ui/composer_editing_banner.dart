import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Полоса над композером в режиме правки текста (паритет веб `ChatMessageInput` + `editingMessage`).
class ComposerEditingBanner extends StatelessWidget {
  const ComposerEditingBanner({
    super.key,
    required this.previewPlain,
    required this.onCancel,
  });

  /// Уже plain-текст для превью (1–2 строки обрезает родитель при необходимости).
  final String previewPlain;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_rounded, size: 22, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.composer_editing_title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: scheme.primary,
                      ),
                    ),
                    if (previewPlain.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        previewPlain,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.composer_editing_cancel_tooltip,
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
