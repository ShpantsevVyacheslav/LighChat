import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_image_cache_manager.dart';
import '../data/local_cache_entry_registry.dart';

/// Сетевые картинки чата: кэш на диске + в памяти ([CachedNetworkImage]),
/// чтобы при обратном скролле не было повторной загрузки с сети.
class ChatCachedNetworkImage extends StatelessWidget {
  const ChatCachedNetworkImage({
    super.key,
    required this.url,
    required this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.compact = false,
    this.showProgressIndicator = true,
    this.errorOverride,
    this.httpHeaders,
    this.conversationId,
    this.messageId,
    this.attachmentName,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  /// Миниатюры (ответ, список чатов): без спиннера, плейсхолдер.
  final bool compact;

  /// `false` — только фон при загрузке (обои и т.п.).
  final bool showProgressIndicator;

  /// Свой виджет при ошибке вместо иконки «битое изображение».
  final Widget? errorOverride;

  /// Для тайлов/превью OSM и др. сервисов, требующих идентифицируемый User-Agent.
  final Map<String, String>? httpHeaders;

  /// Когда заданы — закэшированный файл регистрируется в [LocalCacheEntryRegistry],
  /// чтобы экран «Хранилище» мог сопоставить его с конкретным чатом.
  final String? conversationId;
  final String? messageId;
  final String? attachmentName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uri = Uri.tryParse(url);

    // E2EE media: пока chunked envelope качается и расшифровывается,
    // оркестратор подставляет плейсхолдер с URL-схемой `e2ee-pending://`.
    // Рисуем спиннер с иконкой нужного типа вместо ошибки «битая картинка».
    if (uri != null && uri.scheme == 'e2ee-pending') {
      final kind = (uri.queryParameters['kind'] ?? 'image').toLowerCase();
      final iconData = kind == 'video' || kind == 'videoCircle'
          ? Icons.play_circle_outline_rounded
          : kind == 'voice' || kind == 'audio'
              ? Icons.graphic_eq_rounded
              : kind == 'file'
                  ? Icons.insert_drive_file_outlined
                  : Icons.image_outlined;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              iconData,
              size: compact ? 22 : 36,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            const Positioned(
              right: 8,
              bottom: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    Widget progress(BuildContext context, String _, DownloadProgress progress) {
      if (compact || !showProgressIndicator) {
        return ColoredBox(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: compact ? 0.45 : 0.22,
          ),
        );
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.progress,
            ),
          ),
        ),
      );
    }

    Widget defaultErrorWidget() {
      if (errorOverride != null) return errorOverride!;
      if (compact) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          child: Center(
            child: Icon(
              Icons.image_not_supported_rounded,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        );
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55),
            size: 28,
          ),
        ),
      );
    }

    // Mixed-source support: E2EE media decrypt-path возвращает `file://...`.
    if (uri != null && uri.scheme == 'file') {
      try {
        return Image.file(
          File(uri.toFilePath()),
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => defaultErrorWidget(),
        );
      } catch (_) {
        return defaultErrorWidget();
      }
    }

    final cid = conversationId?.trim();
    final useChatCache = cid != null && cid.isNotEmpty;
    if (useChatCache) {
      // Best-effort: register so storage settings can map the cached file
      // back to this conversation. Idempotent.
      LocalCacheEntryRegistry.registerImageContext(
        url: url,
        conversationId: cid,
        messageId: messageId,
        attachmentName: attachmentName,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: httpHeaders,
      cacheManager: useChatCache ? ChatImageCacheManager() : null,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      progressIndicatorBuilder: progress,
      errorWidget: (context, failedUrl, err) => defaultErrorWidget(),
    );
  }
}
