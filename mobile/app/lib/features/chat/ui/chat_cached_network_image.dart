import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: httpHeaders,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      progressIndicatorBuilder: progress,
      errorWidget: (context, failedUrl, err) {
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
      },
    );
  }
}
