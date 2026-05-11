import 'dart:async';
import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../data/chat_image_cache_manager.dart';
import '../data/local_cache_entry_registry.dart';
import '../data/media_load_scheduler.dart';

/// Сетевые картинки чата: кэш на диске + в памяти ([CachedNetworkImage]),
/// чтобы при обратном скролле не было повторной загрузки с сети.
///
/// Когда `enableScheduler` включён, загрузка проходит через
/// [MediaLoadScheduler] — лимит параллельных скачиваний и приоритет
/// видимых тайлов (виден на экране → быстрее в очереди). Опт-ин, чтобы
/// мелкие миниатюры (список чатов, реплай-превью) не вставали в общую
/// очередь медиа-тайлов чата и грузились моментально.
class ChatCachedNetworkImage extends StatefulWidget {
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
    this.enableScheduler = false,
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

  /// Включить гейт через [MediaLoadScheduler]: загрузка не стартует до тех
  /// пор пока диспетчер не выдаст слот; видимость через [VisibilityDetector]
  /// поднимает приоритет в очереди. По умолчанию выключено — иначе мелкие
  /// аватары/превью в чат-листе тоже встают в общую очередь.
  final bool enableScheduler;

  @override
  State<ChatCachedNetworkImage> createState() => _ChatCachedNetworkImageState();
}

class _ChatCachedNetworkImageState extends State<ChatCachedNetworkImage> {
  // Сценарий с диспетчером: предзагружаем файл в кэш сами, чтобы держать слот
  // ровно на время реального скачивания. После — внутренний CachedNetworkImage
  // отдаёт картинку из кэша мгновенно.
  MediaLoadTicket? _ticket;
  bool _ready = false;
  bool _failed = false;
  double? _downloadProgress;
  MediaLoadPriority _priority = MediaLoadPriority.low;
  late final Key _visibilityKey;
  StreamSubscription<FileResponse>? _streamSub;

  bool get _needsScheduling {
    if (!widget.enableScheduler) return false;
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  @override
  void initState() {
    super.initState();
    _visibilityKey = Key('cni-${identityHashCode(this)}');
    if (_needsScheduling) {
      unawaited(_startScheduledLoad());
    } else {
      _ready = true;
    }
  }

  @override
  void didUpdateWidget(covariant ChatCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.enableScheduler != widget.enableScheduler) {
      _ticket?.cancel();
      _ticket = null;
      _streamSub?.cancel();
      _streamSub = null;
      _ready = !_needsScheduling;
      _failed = false;
      _downloadProgress = null;
      if (_needsScheduling) {
        unawaited(_startScheduledLoad());
      }
    }
  }

  @override
  void dispose() {
    _ticket?.cancel();
    _streamSub?.cancel();
    super.dispose();
  }

  CacheManager _cacheManager() {
    final cid = widget.conversationId?.trim();
    if (cid != null && cid.isNotEmpty) return ChatImageCacheManager();
    return DefaultCacheManager();
  }

  Future<void> _startScheduledLoad() async {
    final mgr = _cacheManager();
    try {
      final cached = await mgr.getFileFromCache(widget.url);
      if (!mounted) return;
      if (cached != null) {
        setState(() => _ready = true);
        return;
      }
    } catch (_) {}

    final t = MediaLoadScheduler.instance.enqueue(priority: _priority);
    _ticket = t;
    try {
      await t.granted;
    } on MediaLoadCancelled {
      return;
    }
    if (!mounted) {
      t.release();
      return;
    }

    final stream = mgr.getFileStream(
      widget.url,
      headers: widget.httpHeaders,
      withProgress: true,
    );
    _streamSub = stream.listen(
      (resp) {
        if (!mounted) return;
        if (resp is DownloadProgress) {
          setState(() => _downloadProgress = resp.progress);
        } else if (resp is FileInfo) {
          setState(() => _ready = true);
          t.release();
          _streamSub?.cancel();
          _streamSub = null;
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _failed = true);
        t.release();
      },
      cancelOnError: true,
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_needsScheduling) return;
    final visible = info.visibleFraction > 0.25;
    final next =
        visible ? MediaLoadPriority.high : MediaLoadPriority.low;
    if (_priority == next) return;
    _priority = next;
    _ticket?.bumpPriority(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uri = Uri.tryParse(widget.url);

    // E2EE media: пока chunked envelope качается и расшифровывается,
    // оркестратор подставляет плейсхолдер с URL-схемой `e2ee-pending://`.
    // Рисуем спиннер с иконкой нужного типа вместо ошибки «битая картинка».
    if (uri != null && uri.scheme == 'e2ee-pending') {
      return _e2eePendingPlaceholder(uri, scheme);
    }

    // Mixed-source support: E2EE media decrypt-path возвращает `file://...`.
    if (uri != null && uri.scheme == 'file') {
      try {
        return Image.file(
          File(uri.toFilePath()),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => _defaultErrorWidget(scheme),
        );
      } catch (_) {
        return _defaultErrorWidget(scheme);
      }
    }

    final cid = widget.conversationId?.trim();
    final useChatCache = cid != null && cid.isNotEmpty;
    if (useChatCache) {
      // Best-effort: register so storage settings can map the cached file
      // back to this conversation. Idempotent.
      LocalCacheEntryRegistry.registerImageContext(
        url: widget.url,
        conversationId: cid,
        messageId: widget.messageId,
        attachmentName: widget.attachmentName,
      );
    }

    Widget inner;
    if (_needsScheduling && !_ready && !_failed) {
      inner = _progressPlaceholder(
        scheme,
        determinateProgress: _downloadProgress,
      );
    } else if (_failed) {
      inner = _defaultErrorWidget(scheme);
    } else {
      inner = CachedNetworkImage(
        imageUrl: widget.url,
        httpHeaders: widget.httpHeaders,
        cacheManager: useChatCache ? ChatImageCacheManager() : null,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        progressIndicatorBuilder: (ctx, _, progress) {
          return _progressPlaceholder(
            scheme,
            determinateProgress: progress.progress,
          );
        },
        errorWidget: (context, failedUrl, err) =>
            _defaultErrorWidget(scheme),
      );
    }

    if (!_needsScheduling) return inner;
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: inner,
    );
  }

  Widget _e2eePendingPlaceholder(Uri uri, ColorScheme scheme) {
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
            size: widget.compact ? 22 : 36,
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

  Widget _progressPlaceholder(
    ColorScheme scheme, {
    double? determinateProgress,
  }) {
    if (widget.compact || !widget.showProgressIndicator) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: widget.compact ? 0.45 : 0.22,
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
            value: determinateProgress,
          ),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget(ColorScheme scheme) {
    if (widget.errorOverride != null) return widget.errorOverride!;
    if (widget.compact) {
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
}
