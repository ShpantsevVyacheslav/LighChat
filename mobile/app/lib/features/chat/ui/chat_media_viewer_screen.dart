import 'dart:async';
import 'dart:io' show Directory, File, FileSystemException, HttpException;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/app_logger.dart';
import '../data/chat_image_cache_manager.dart';
import '../data/chat_media_gallery.dart';
import '../data/local_cache_entry_registry.dart';
import 'chat_gallery_video_local_cache.dart';
import 'chat_media_viewer_photo_page.dart';
import 'chat_vlc_network_media.dart';
import '../data/live_text.dart';
import '../data/subject_lift.dart';
import '../../../l10n/app_localizations.dart';

String formatChatMediaViewerDate(BuildContext context, DateTime utcOrLocal) {
  final d = utcOrLocal.toLocal();
  final l10n = AppLocalizations.of(context)!;
  final localeName = l10n.localeName;
  // Example: "27 April 2026, 16:23" / "27 апреля 2026, 16:23"
  final f = intl.DateFormat('d MMMM yyyy, HH:mm', localeName);
  return f.format(d);
}

/// Маршрут без [MaterialPageRoute.fullscreenDialog]: при закрытии экран уезжает
/// в направлении жеста закрытия (свайп вниз — вниз, свайп вверх — вверх, иначе
/// вверх по умолчанию, как было).
Route<T> chatMediaViewerPageRoute<T extends Object?>(Widget page) {
  // `-1` = вверх (по умолчанию, сохраняет старое поведение для закрытий
  // не через жест — например, кнопка назад, программный `pop()`).
  // `+1` = вниз (выставляется при свайп-вниз в `_ChatMediaViewerScreenState`).
  final dir = ValueNotifier<double>(-1);
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: Colors.transparent,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ChatMediaViewerCloseDirectionScope(notifier: dir, child: page);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _ChatMediaViewerSlideTransition(
        animation: animation,
        closeDirection: dir,
        child: child,
      );
    },
  );
}

/// InheritedWidget, отдающий экрану-владельцу доступ к ValueNotifier направления
/// закрытия, которое читает `_ChatMediaViewerSlideTransition` на reverse.
class _ChatMediaViewerCloseDirectionScope extends InheritedWidget {
  const _ChatMediaViewerCloseDirectionScope({
    required this.notifier,
    required super.child,
  });

  final ValueNotifier<double> notifier;

  static ValueNotifier<double>? maybeOf(BuildContext context) {
    final w = context
        .getInheritedWidgetOfExactType<_ChatMediaViewerCloseDirectionScope>();
    return w?.notifier;
  }

  @override
  bool updateShouldNotify(_ChatMediaViewerCloseDirectionScope old) =>
      old.notifier != notifier;
}

class _ChatMediaViewerSlideTransition extends StatelessWidget {
  const _ChatMediaViewerSlideTransition({
    required this.animation,
    required this.closeDirection,
    required this.child,
  });

  final Animation<double> animation;
  final ValueNotifier<double> closeDirection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[animation, closeDirection]),
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        // Для forward (открытие) — всегда появляемся снизу вверх (как было).
        // Для reverse (закрытие) — направление зависит от жеста закрытия:
        // `-1` вверх (дефолт), `+1` вниз (после свайп-вниз).
        final double dy;
        if (animation.status == AnimationStatus.reverse) {
          final sign = closeDirection.value >= 0 ? 1.0 : -1.0;
          dy = sign * h * (1.0 - t);
        } else {
          dy = h * (1.0 - t);
        }
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

/// Полноэкранный просмотр изображений и видео из чата (паритет веба `media-viewer.tsx`).
class ChatMediaViewerScreen extends StatefulWidget {
  const ChatMediaViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    this.conversationId,
    required this.currentUserId,
    required this.senderLabel,
    this.onReply,
    required this.onForward,
    required this.onDeleteItem,
    this.onShowInChat,
    this.onAttachToComposer,
    this.allowForward = true,
    this.allowSave = true,
    this.allowExternalShare = true,
  });

  final List<ChatMediaGalleryItem> items;
  final int initialIndex;
  final String? conversationId;
  final String currentUserId;
  final String Function(String senderId) senderLabel;

  /// Если `null`, кнопки «Ответить» скрыты (например, экран ветки без превью ответа).
  final void Function(ChatMessage message)? onReply;

  /// Пересылка текущего вложения (один файл, не весь альбом).
  final void Function(ChatMediaGalleryItem item) onForward;

  /// `true` после успешного удаления файла или сообщения (диалог — у родителя).
  final Future<bool> Function(ChatMediaGalleryItem item) onDeleteItem;

  /// Переход к сообщению во внутреннем чате (из fullscreen-viewer).
  final void Function(ChatMediaGalleryItem item)? onShowInChat;

  /// Опционально: callback для прикрепления локального файла как нового
  /// attachment в текущем чате. Используется Subject Lift action sheet —
  /// «Отправить в этот чат» вставляет извлечённый PNG в composer.
  /// Если `null` — пункт отключён.
  final void Function(String filePath)? onAttachToComposer;

  final bool allowForward;
  final bool allowSave;
  final bool allowExternalShare;

  @override
  State<ChatMediaViewerScreen> createState() => _ChatMediaViewerScreenState();
}

class _ChatMediaViewerScreenState extends State<ChatMediaViewerScreen> {
  static const double _kTopChromeFallbackHeight = 68;

  late List<ChatMediaGalleryItem> _items;
  late PageController _pageController;
  late int _index;
  final Map<int, TransformationController> _imageTransforms = {};
  final Map<int, TransformationController> _videoTransforms = {};
  final GlobalKey _topChromeKey = GlobalKey();
  double _topChromeMeasuredHeight = 0;
  bool _zoomed = false;
  double _dismissDragY = 0;

  /// Одиночный тап по фото скрывает/показывает верхний и нижний chrome.
  bool _chromeHidden = false;

  /// Скрывает нижние FAB (ответить / переслать / …), пока активная страница — видео и оно играет.
  bool _galleryVideoPlaying = false;

  /// Состояние видимости контролов текущей video-страницы.
  /// Держим в родителе, чтобы можно было расширять логику chrome без
  /// подписки на контроллер плеера в этом виджете.
  bool _galleryVideoControlsVisible = true;

  /// Поддерживает ли устройство Live Text (iOS 16+ VisionKit). Проверяем
  /// один раз при инициализации — состояние стабильно за время жизни вью.
  bool _liveTextAvailable = false;

  /// Subject Lift (iOS 17+ VisionKit) — вырезание объекта с фона.
  bool _subjectLiftAvailable = false;

  @override
  void initState() {
    super.initState();
    _items = List<ChatMediaGalleryItem>.from(widget.items);
    final n = _items.length;
    final start = n == 0 ? 0 : widget.initialIndex.clamp(0, n - 1);
    _index = start;
    _pageController = PageController(initialPage: start);
    unawaited(LiveTextViewer.instance.isAvailable().then((v) {
      if (mounted) setState(() => _liveTextAvailable = v);
    }));
    unawaited(SubjectLift.instance.isAvailable().then((v) {
      if (mounted) setState(() => _subjectLiftAvailable = v);
    }));
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _imageTransforms.values) {
      c.dispose();
    }
    for (final c in _videoTransforms.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _transformFor(int pageIndex) {
    return _imageTransforms.putIfAbsent(pageIndex, () {
      final c = TransformationController();
      c.addListener(() {
        if (!mounted || _index != pageIndex) return;
        final s = c.value.getMaxScaleOnAxis();
        final z = s > 1.05;
        if (z != _zoomed) {
          setState(() => _zoomed = z);
        }
      });
      return c;
    });
  }

  TransformationController _videoTransformFor(int pageIndex) {
    return _videoTransforms.putIfAbsent(pageIndex, () {
      final c = TransformationController();
      c.addListener(() {
        if (!mounted || _index != pageIndex) return;
        final s = c.value.getMaxScaleOnAxis();
        final z = s > 1.05;
        if (z != _zoomed) {
          setState(() => _zoomed = z);
        }
      });
      return c;
    });
  }

  ChatMediaGalleryItem? get _current =>
      _items.isEmpty ? null : _items[_index.clamp(0, _items.length - 1)];

  void _scheduleTopChromeMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _topChromeKey.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) return;
      final measured = ro.size.height;
      if ((measured - _topChromeMeasuredHeight).abs() < 0.5) return;
      setState(() => _topChromeMeasuredHeight = measured);
    });
  }

  /// Открыть нативный Live Text viewer для текущей картинки (iOS 16+).
  Future<void> _openLiveText() async {
    final cur = _current;
    if (cur == null) return;
    final url = cur.attachment.url.trim();
    if (url.isEmpty) return;
    await LiveTextViewer.instance.present(imageUrl: url);
  }

  /// Открыть Subject Lift фуллскрин (iOS 17+). После выбора объекта
  /// показываем action-sheet: «Отправить в этот чат / Сохранить в галерею
  /// / Поделиться». Файл — PNG с прозрачным альфа-каналом.
  Future<void> _openSubjectLift() async {
    final cur = _current;
    if (cur == null) return;
    final url = cur.attachment.url.trim();
    if (url.isEmpty) return;
    final pngPath = await SubjectLift.instance.lift(imageUrl: url);
    if (!mounted || pngPath == null || pngPath.isEmpty) return;
    await _showSubjectLiftSheet(pngPath);
  }

  Future<void> _showSubjectLiftSheet(String pngPath) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: isDark
                ? const Color(0xFF15171C)
                : const Color(0xFFF5F6F8),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 180,
                          maxWidth: 220,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.file(File(pngPath), fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SubjectLiftActionTile(
                      icon: Icons.send_rounded,
                      label: l10n.media_viewer_action_subject_send,
                      isDark: isDark,
                      onTap: () async {
                        Navigator.of(ctx).maybePop();
                        widget.onAttachToComposer?.call(pngPath);
                      },
                      enabled: widget.onAttachToComposer != null,
                    ),
                    const SizedBox(height: 8),
                    _SubjectLiftActionTile(
                      icon: Icons.download_rounded,
                      label: l10n.media_viewer_action_subject_save,
                      isDark: isDark,
                      onTap: () async {
                        Navigator.of(ctx).maybePop();
                        try {
                          await Gal.putImage(pngPath);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(milliseconds: 1500),
                              content: Text(l10n.media_viewer_subject_saved),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.media_viewer_error_save_failed(e),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _SubjectLiftActionTile(
                      icon: Icons.ios_share_rounded,
                      label: l10n.media_viewer_action_subject_share,
                      isDark: isDark,
                      onTap: () async {
                        Navigator.of(ctx).maybePop();
                        await SharePlus.instance.share(
                          ShareParams(files: [XFile(pngPath)]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCurrent() async {
    final l10n = AppLocalizations.of(context)!;
    final item = _current;
    if (item == null) return;
    final url = item.attachment.url;
    final uri = Uri.tryParse(url);
    final rawName = item.attachment.name.trim();
    final name = rawName.isNotEmpty
        ? rawName.replaceAll(RegExp(r'[/\\]'), '_')
        : 'media';
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.media_viewer_error_no_gallery_access),
              ),
            );
          }
          return;
        }
      }
      final f = File(
        '${Directory.systemTemp.path}/lighchat_${DateTime.now().millisecondsSinceEpoch}_$name',
      );
      if (uri == null || uri.scheme.isEmpty) {
        throw FormatException(l10n.media_viewer_error_bad_media_url);
      }
      if (uri.scheme == 'file') {
        final src = File(uri.toFilePath());
        if (!await src.exists()) {
          throw FileSystemException(l10n.media_viewer_error_file_not_found);
        }
        await src.copy(f.path);
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final res = await http.get(uri);
        if (res.statusCode != 200) {
          throw HttpException(
            l10n.media_viewer_error_http_status(res.statusCode),
          );
        }
        await f.writeAsBytes(res.bodyBytes);
      } else {
        throw FormatException(l10n.media_viewer_error_unsupported_media_scheme);
      }
      final video = isChatGridGalleryVideo(item.attachment);
      if (video) {
        await Gal.putVideo(f.path);
      } else {
        await Gal.putImage(f.path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.media_viewer_error_save_failed(e))),
        );
      }
    }
  }

  String _shareExtFromAttachment(ChatAttachment att) {
    final mime = (att.type ?? '').toLowerCase();
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('gif')) return 'gif';
    if (mime.contains('heic')) return 'heic';
    if (mime.contains('heif')) return 'heif';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('mp4')) return 'mp4';
    if (mime.contains('quicktime') || mime.contains('mov')) return 'mov';
    if (mime.contains('mpeg')) return 'mpeg';

    final uri = Uri.tryParse(att.url);
    final path = (uri?.path ?? att.url).toLowerCase();
    final m = RegExp(r'\.([a-z0-9]{2,5})$').firstMatch(path);
    final ext = m?.group(1);
    if (ext != null && ext.isNotEmpty) return ext;
    return isChatGridGalleryVideo(att) ? 'mp4' : 'jpg';
  }

  Future<void> _shareCurrentExternal() async {
    final l10n = AppLocalizations.of(context)!;
    final item = _current;
    if (item == null) return;
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.media_viewer_error_share_unavailable_web),
          ),
        );
      }
      return;
    }

    Rect? shareRect;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      final origin = ro.localToGlobal(Offset.zero);
      shareRect = origin & ro.size;
    }

    final url = item.attachment.url;
    final uri = Uri.tryParse(url);
    final rawName = item.attachment.name.trim();
    final safeBaseName = rawName.isNotEmpty
        ? rawName.replaceAll(RegExp(r'[/\\]'), '_')
        : 'media';
    final ext = _shareExtFromAttachment(item.attachment);
    final video = isChatGridGalleryVideo(item.attachment);
    final fallbackName = video ? '$safeBaseName.$ext' : '$safeBaseName.$ext';
    final mimeType = (item.attachment.type ?? '').trim().isEmpty
        ? null
        : item.attachment.type;

    File? f;
    try {
      if (uri == null || uri.scheme.isEmpty) {
        throw FormatException(l10n.media_viewer_error_bad_media_url);
      }
      f = File(
        '${Directory.systemTemp.path}/lighchat_share_${DateTime.now().millisecondsSinceEpoch}_$fallbackName',
      );
      if (uri.scheme == 'file') {
        final src = File(uri.toFilePath());
        if (!await src.exists()) {
          throw FileSystemException(l10n.media_viewer_error_file_not_found);
        }
        await src.copy(f.path);
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final res = await http.get(uri);
        if (res.statusCode != 200) {
          throw HttpException(
            l10n.media_viewer_error_http_status(res.statusCode),
          );
        }
        await f.writeAsBytes(res.bodyBytes, flush: true);
      } else {
        throw FormatException(l10n.media_viewer_error_unsupported_media_scheme);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(f.path, name: fallbackName, mimeType: mimeType)],
          subject: 'LighChat',
          sharePositionOrigin: shareRect,
        ),
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.media_viewer_error_send_failed(e))),
        );
      }
    }
  }

  void _reply() {
    final m = _current?.message;
    final cb = widget.onReply;
    if (m == null || cb == null) return;
    Navigator.of(context).pop();
    cb(m);
  }

  void _forward() {
    final item = _current;
    if (item == null) return;
    Navigator.of(context).pop();
    widget.onForward(item);
  }

  void _showInChat() {
    final item = _current;
    final cb = widget.onShowInChat;
    if (item == null || cb == null) return;
    Navigator.of(context).pop();
    cb(item);
  }

  Future<void> _delete() async {
    final item = _current;
    if (item == null) return;
    final url = item.attachment.url;
    final ok = await widget.onDeleteItem(item);
    if (!ok || !mounted) return;
    setState(() {
      _items.removeWhere((e) => e.attachment.url == url);
    });
    if (_items.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (_index >= _items.length) {
      _index = _items.length - 1;
    }
    await _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final cur = _current;
    final currentIsVideo =
        cur != null && isChatGridGalleryVideo(cur.attachment);
    final showTopChrome = !_zoomed &&
        !(currentIsVideo && _galleryVideoPlaying) &&
        !_chromeHidden;
    if (showTopChrome) {
      _scheduleTopChromeMeasure();
    }
    final topBarControlsInset = (showTopChrome && currentIsVideo)
        ? (_topChromeMeasuredHeight > 0
              ? _topChromeMeasuredHeight
              : top + _kTopChromeFallbackHeight)
        : 0.0;
    final canDelete =
        cur != null && cur.message.senderId == widget.currentUserId;
    final showReply = widget.onReply != null;
    final showInChat = widget.onShowInChat != null;

    void goPrev() {
      if (_index <= 0) return;
      unawaited(
        _pageController.previousPage(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    }

    void goNext() {
      if (_index >= _items.length - 1) return;
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    }

    final multi = _items.length > 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onVerticalDragUpdate: !_zoomed
              ? (d) => setState(() => _dismissDragY += d.delta.dy)
              : null,
          onVerticalDragEnd: !_zoomed
              ? (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (_dismissDragY.abs() > 120 || v.abs() > 600) {
                    // Задать направление закрытия под жест пользователя,
                    // чтобы reverse-анимация продолжилась в ту же сторону,
                    // а не «отпрыгивала» вверх при свайпе вниз.
                    final downward = _dismissDragY > 0 || v > 0;
                    final dir = _ChatMediaViewerCloseDirectionScope.maybeOf(
                      context,
                    );
                    if (dir != null) {
                      dir.value = downward ? 1.0 : -1.0;
                    }
                    Navigator.of(context).pop();
                    // Don't reset `_dismissDragY` here — it causes a visible
                    // "snap back" right before the route dismisses.
                    return;
                  }
                  setState(() => _dismissDragY = 0);
                }
              : null,
          child: Transform.translate(
            offset: Offset(0, _dismissDragY),
            child: Opacity(
              opacity: (1.0 - _dismissDragY.abs() / 480).clamp(0.4, 1.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BackdropLayer(
                    item: cur?.attachment,
                    conversationId: widget.conversationId,
                    messageId: cur?.message.id,
                  ),
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _zoomed
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() {
                          _index = i;
                          _zoomed = false;
                          _galleryVideoPlaying = false;
                          _galleryVideoControlsVisible = true;
                          _chromeHidden = false;
                        });
                        for (final e in _imageTransforms.entries) {
                          if (e.key != i) {
                            e.value.value = Matrix4.identity();
                          }
                        }
                        for (final e in _videoTransforms.entries) {
                          if (e.key != i) {
                            e.value.value = Matrix4.identity();
                          }
                        }
                      },
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final it = _items[i];
                        final att = it.attachment;
                        if (isChatGridGalleryVideo(att)) {
                          return _GalleryVideoPage(
                            key: ValueKey<String>('v-${att.url}'),
                            pageIndex: i,
                            url: att.url,
                            transformationController: _videoTransformFor(i),
                            conversationId: widget.conversationId,
                            messageId: it.message.id,
                            attachmentName: att.name,
                            mimeType: att.type,
                            topOverlayInset: i == _index
                                ? topBarControlsInset
                                : 0,
                            showEdgeNavigation: multi && !_zoomed,
                            onTapPrev: i > 0 ? goPrev : null,
                            onTapNext: i < _items.length - 1 ? goNext : null,
                            onPlaybackStateChanged: (pageIdx, playing) {
                              if (!mounted || pageIdx != _index) return;
                              if (_galleryVideoPlaying != playing) {
                                setState(() => _galleryVideoPlaying = playing);
                              }
                            },
                            onControlsVisibleChanged: (pageIdx, visible) {
                              if (!mounted || pageIdx != _index) return;
                              if (_galleryVideoControlsVisible != visible) {
                                setState(
                                  () => _galleryVideoControlsVisible = visible,
                                );
                              }
                            },
                          );
                        }
                        final tc = _transformFor(i);
                        return ChatMediaViewerPhotoPage(
                          key: ValueKey<String>('p-${att.url}'),
                          url: att.url,
                          transformationController: tc,
                          showEdgeNavigation: !_zoomed,
                          canGoPrev: multi && i > 0,
                          canGoNext: multi && i < _items.length - 1,
                          onGoPrev: goPrev,
                          onGoNext: goNext,
                          onSingleTap: () {
                            if (!mounted) return;
                            setState(() => _chromeHidden = !_chromeHidden);
                          },
                        );
                      },
                    ),
                  ),
                  if (showTopChrome)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        key: _topChromeKey,
                        padding: EdgeInsets.fromLTRB(4, top + 4, 8, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0),
                            ],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: Colors.white,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: cur == null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                widget.senderLabel(
                                                  cur.message.senderId,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.22),
                                                ),
                                                color: Colors.white.withValues(
                                                  alpha: 0.10,
                                                ),
                                              ),
                                              child: Text(
                                                '${_index + 1} / ${_items.length}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.88),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatChatMediaViewerDate(
                                            context,
                                            cur.message.createdAt,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.52,
                                            ),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                              ),
                              color: const Color(0xEE1C1C1E),
                              onSelected: (v) {
                                switch (v) {
                                  case 'reply':
                                    _reply();
                                    return;
                                  case 'forward':
                                    if (widget.allowForward) _forward();
                                    return;
                                  case 'share_external':
                                    if (widget.allowExternalShare) {
                                      unawaited(_shareCurrentExternal());
                                    }
                                    return;
                                  case 'save':
                                    if (widget.allowSave) {
                                      unawaited(_saveCurrent());
                                    }
                                    return;
                                  case 'live_text':
                                    unawaited(_openLiveText());
                                  case 'subject_lift':
                                    unawaited(_openSubjectLift());
                                    return;
                                  case 'show_in_chat':
                                    _showInChat();
                                    return;
                                  case 'delete':
                                    unawaited(_delete());
                                    return;
                                  default:
                                    return;
                                }
                              },
                              itemBuilder: (ctx) {
                                final hi = Colors.white.withValues(alpha: 0.92);
                                final l10n = AppLocalizations.of(context)!;
                                return [
                                  if (showReply)
                                    PopupMenuItem(
                                      value: 'reply',
                                      child: Row(
                                        children: [
                                          Icon(Icons.reply_rounded, color: hi),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_reply,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.allowForward)
                                    PopupMenuItem(
                                      value: 'forward',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.forward_rounded,
                                            color: hi,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_forward,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.allowExternalShare)
                                    PopupMenuItem(
                                      value: 'share_external',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share_outlined, color: hi),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_send,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.allowSave)
                                    PopupMenuItem(
                                      value: 'save',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.download_rounded,
                                            color: hi,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_save,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_liveTextAvailable && !currentIsVideo)
                                    PopupMenuItem(
                                      value: 'live_text',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.text_format_rounded,
                                            color: hi,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_live_text,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_subjectLiftAvailable && !currentIsVideo)
                                    PopupMenuItem(
                                      value: 'subject_lift',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            color: hi,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_subject_lift,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (showInChat)
                                    PopupMenuItem(
                                      value: 'show_in_chat',
                                      child: Row(
                                        children: [
                                          Icon(Icons.chat_rounded, color: hi),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_show_in_chat,
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (canDelete)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.media_viewer_action_delete,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ];
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_zoomed && !_galleryVideoPlaying && !_chromeHidden)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: bottom + 16,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showReply) ...[
                              _FabGlass(
                                icon: Icons.reply_rounded,
                                onTap: _reply,
                              ),
                              const SizedBox(width: 12),
                            ],
                            _FabGlass(
                              icon: Icons.forward_rounded,
                              onTap: _forward,
                            ),
                            if (showInChat) ...[
                              const SizedBox(width: 12),
                              _FabGlass(
                                icon: Icons.chat_rounded,
                                onTap: _showInChat,
                              ),
                            ],
                            if (canDelete) ...[
                              const SizedBox(width: 12),
                              _FabGlass(
                                icon: Icons.delete_outline_rounded,
                                danger: true,
                                onTap: () => unawaited(_delete()),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropLayer extends StatelessWidget {
  const _BackdropLayer({this.item, this.conversationId, this.messageId});

  final ChatAttachment? item;
  final String? conversationId;
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final att = item;
    if (att == null) {
      return const ColoredBox(color: Color(0xFF0A0A0B));
    }
    if (isChatGridGalleryVideo(att)) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF27272A), Color(0xFF09090B), Color(0xFF000000)],
          ),
        ),
      );
    }
    final url = att.url;
    final uri = Uri.tryParse(url);
    final cid = conversationId?.trim();
    final hasChatCtx = cid != null && cid.isNotEmpty;
    final ImageProvider<Object>? bgImage = (uri != null && uri.scheme == 'file')
        ? FileImage(File(uri.toFilePath()))
        : ((uri != null && uri.hasScheme)
              // Используем `ChatImageCacheManager` (с регистрацией в
              // [LocalCacheEntryRegistry]), чтобы blurred backdrop не оседал
              // в дефолтном `libCachedImageData/` orphan-кэше.
              ? (hasChatCtx
                    ? CachedNetworkImageProvider(
                        url,
                        cacheManager: ChatImageCacheManager(),
                      )
                    : CachedNetworkImageProvider(url))
              : null);
    if (hasChatCtx && uri != null && uri.hasScheme && uri.scheme != 'file') {
      LocalCacheEntryRegistry.registerImageContext(
        url: url,
        conversationId: cid,
        messageId: messageId,
        attachmentName: att.name,
      );
    }
    if (bgImage == null) {
      return const ColoredBox(color: Color(0xFF18181B));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Transform.scale(
            scale: 1.18,
            child: Image(
              image: bgImage,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF18181B)),
            ),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.60)),
      ],
    );
  }
}

class _FabGlass extends StatelessWidget {
  const _FabGlass({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: danger
                  ? const Color(0x99F87171)
                  : Colors.white.withValues(alpha: 0.28),
            ),
            color: danger
                ? const Color(0x662B0A0A)
                : Colors.black.withValues(alpha: 0.52),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: danger
                ? const Color(0xFFFECACA)
                : Colors.white.withValues(alpha: 0.94),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _GalleryVideoPage extends StatefulWidget {
  const _GalleryVideoPage({
    super.key,
    required this.pageIndex,
    required this.url,
    required this.transformationController,
    this.conversationId,
    this.messageId,
    this.attachmentName,
    this.mimeType,
    this.topOverlayInset = 0,
    this.showEdgeNavigation = true,
    this.onTapPrev,
    this.onTapNext,
    this.onPlaybackStateChanged,
    this.onControlsVisibleChanged,
  });

  final int pageIndex;
  final String url;
  final TransformationController transformationController;
  final String? conversationId;
  final String? messageId;
  final String? attachmentName;
  final String? mimeType;
  final double topOverlayInset;
  final bool showEdgeNavigation;
  final VoidCallback? onTapPrev;
  final VoidCallback? onTapNext;
  final void Function(int pageIndex, bool isPlaying)? onPlaybackStateChanged;
  final void Function(int pageIndex, bool visible)? onControlsVisibleChanged;

  @override
  State<_GalleryVideoPage> createState() => _GalleryVideoPageState();
}

class _GalleryVideoPageState extends State<_GalleryVideoPage>
    with SingleTickerProviderStateMixin {
  static const double _videoDoubleTapScale = 2.5;
  static const double _videoZoomedThreshold = 1.01;

  VideoPlayerController? _av;
  bool _failed = false;
  bool _controlsVisible = true;
  bool _muted = false;
  bool _switchingQuality = false;
  bool _scrubbing = false;
  Duration _scrubPosition = Duration.zero;
  double _playbackSpeed = 1.0;
  _ViewerVideoQuality _quality = _ViewerVideoQuality.auto;
  String _activeUrl = '';
  Timer? _hideControlsTimer;

  late final AnimationController _zoomAnim;
  VoidCallback? _zoomTickListener;

  bool _lastNotifiedPlaying = false;
  bool _lastNotifiedControlsVisible = true;

  /// Экземпляр, которому нативный PiP шлёт `pipFinished` (последний, открывший PiP).
  static _GalleryVideoPageState? _pipResumeTarget;

  @override
  void initState() {
    super.initState();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _activeUrl = _urlForQuality(_quality);
    _PictureInPictureBridge.ensureDartInboundForPipFinished();
    unawaited(_initAv(url: _activeUrl));
  }

  void _disposeZoomAnimListener() {
    final l = _zoomTickListener;
    if (l != null) {
      _zoomAnim.removeListener(l);
      _zoomTickListener = null;
    }
  }

  void _animateZoomTo(Matrix4 target) {
    _disposeZoomAnimListener();
    final c = widget.transformationController;
    final anim = Matrix4Tween(
      begin: c.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    void l() {
      c.value = anim.value;
    }

    _zoomTickListener = l;
    _zoomAnim
      ..removeStatusListener(_onZoomAnimStatus)
      ..addStatusListener(_onZoomAnimStatus);
    _zoomAnim.addListener(l);
    _zoomAnim
      ..value = 0
      ..forward();
  }

  void _onZoomAnimStatus(AnimationStatus status) {
    if (kDebugMode) {
      appLogger.d('[video-viewer] zoomAnim status=$status');
    }
    // ТОЛЬКО completed: dismissed срабатывает при forward(from: 0) →
    // value = 0 на втором вызове, и listener умирает до первого кадра.
    if (status == AnimationStatus.completed) {
      _disposeZoomAnimListener();
    }
  }

  void _handleVideoDoubleTap(TapDownDetails d) {
    final c = widget.transformationController;
    final scale = c.value.getMaxScaleOnAxis();
    if (kDebugMode) {
      appLogger.d(
        '[video-viewer] doubleTap scale=$scale focal=${d.localPosition}',
      );
    }
    if (scale > _videoZoomedThreshold) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    final focal = d.localPosition;
    final target = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(_videoDoubleTapScale, _videoDoubleTapScale, 1.0, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _animateZoomTo(target);
  }

  Future<void> _initAv({required String url}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      if (uri.scheme == 'file') {
        c = VideoPlayerController.file(
          File(uri.toFilePath()),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        final cached = await ChatGalleryVideoLocalCache.cachedFileIfExists(url);
        if (cached != null) {
          c = VideoPlayerController.file(
            cached,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          // НЕ запускаем параллельный downloadToCache: video_player сам
          // стримит сетевой URL, а второй HTTP-коннект только дробил бы
          // пропускную способность пополам и визуально создавал эффект
          // «видео не играет, пока полностью не загрузится». Кэш для
          // повторных открытий заполняется отложенно через warmUp() в
          // dispose() — там сеть уже свободна.
          c = VideoPlayerController.networkUrl(
            uri,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        }
      }
      await c.initialize();
      await c.setLooping(false);
      await c.setVolume(_muted ? 0 : 1);
      await c.setPlaybackSpeed(_playbackSpeed);
      if (!mounted) {
        await c.dispose();
        return;
      }
      if (c.value.hasError) {
        await c.dispose();
        setState(() => _failed = true);
        return;
      }
      setState(() {
        _av = c;
        _failed = false;
      });
      // Стартуем сразу после инициализации — видео дальше будет буферизоваться в фоне.
      unawaited(c.play());
      _showControlsTemporarily(force: true);
    } catch (_) {
      await c?.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    if (_lastNotifiedPlaying) {
      _lastNotifiedPlaying = false;
      widget.onPlaybackStateChanged?.call(widget.pageIndex, false);
    }
    if (_pipResumeTarget == this) {
      _pipResumeTarget = null;
    }
    _hideControlsTimer?.cancel();
    _av?.dispose();
    _disposeZoomAnimListener();
    _zoomAnim.dispose();
    // Подогрев кэша «после» — сеть уже свободна, в отличие от случая,
    // когда плеер активен и сам качает по тому же URL.
    final url = widget.url;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme.isNotEmpty && uri.scheme != 'file') {
      unawaited(
        ChatGalleryVideoLocalCache.warmUp(
          url,
          conversationId: widget.conversationId,
          messageId: widget.messageId,
          attachmentName: widget.attachmentName,
        ),
      );
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final sec = d.inSeconds.clamp(0, 99 * 3600);
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSpeed(double value) {
    if ((value - value.roundToDouble()).abs() < 0.001) {
      return value.toStringAsFixed(0);
    }
    final x10 = value * 10;
    if ((x10 - x10.roundToDouble()).abs() < 0.001) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  Duration _safeDuration(VideoPlayerValue value) {
    final d = value.duration;
    if (d <= Duration.zero) return const Duration(seconds: 1);
    return d;
  }

  void _showControlsTemporarily({bool force = false}) {
    if (force && mounted && !_controlsVisible) {
      setState(() => _controlsVisible = true);
    } else if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _hideControlsTimer?.cancel();
    final c = _av;
    if (c != null && c.value.isPlaying) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _controlsVisible = false);
      });
    }
  }

  void _hideControlsNow() {
    _hideControlsTimer?.cancel();
    if (!_controlsVisible || !mounted) return;
    setState(() => _controlsVisible = false);
  }

  Future<void> _togglePlayPause() async {
    final c = _av;
    if (c == null || !c.value.isInitialized || _switchingQuality) return;
    if (c.value.isPlaying) {
      await c.pause();
      _hideControlsTimer?.cancel();
      if (mounted) setState(() => _controlsVisible = true);
    } else {
      await c.play();
      _showControlsTemporarily(force: true);
    }
  }

  Future<void> _toggleMute() async {
    final c = _av;
    if (c == null || !c.value.isInitialized || _switchingQuality) return;
    final next = !_muted;
    await c.setVolume(next ? 0 : 1);
    if (!mounted) return;
    setState(() => _muted = next);
    _showControlsTemporarily(force: true);
  }

  Future<void> _seekBySeconds(int delta) async {
    final c = _av;
    if (c == null || !c.value.isInitialized || _switchingQuality) return;
    final d = _safeDuration(c.value);
    final target = c.value.position + Duration(seconds: delta);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, d.inMilliseconds),
    );
    await c.seekTo(clamped);
    _showControlsTemporarily(force: true);
  }

  Future<void> _setSpeed(double speed) async {
    final c = _av;
    if (c == null || !c.value.isInitialized || _switchingQuality) return;
    await c.setPlaybackSpeed(speed);
    if (!mounted) return;
    setState(() => _playbackSpeed = speed);
    _showControlsTemporarily(force: true);
  }

  Future<void> _pickSpeed() async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1C),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        const options = <double>[1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.media_viewer_video_playback_speed,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final speed in options)
                ListTile(
                  onTap: () => Navigator.of(context).pop(speed),
                  title: Text(
                    '${_formatSpeed(speed)}x',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: (speed - _playbackSpeed).abs() < 0.001
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    await _setSpeed(picked);
  }

  String _urlForQuality(_ViewerVideoQuality quality) {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme.isEmpty || uri.scheme == 'file') {
      return widget.url;
    }
    final q = Map<String, String>.from(uri.queryParameters);
    final target = quality.targetHeight;
    if (target == null) {
      q.remove('quality');
    } else {
      q['quality'] = '$target';
    }
    return uri.replace(queryParameters: q).toString();
  }

  Future<void> _pickQuality() async {
    final picked = await showModalBottomSheet<_ViewerVideoQuality>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1C),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        const options = <_ViewerVideoQuality>[
          _ViewerVideoQuality.auto,
          _ViewerVideoQuality.p1080,
          _ViewerVideoQuality.p720,
          _ViewerVideoQuality.p480,
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.media_viewer_video_quality,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final quality in options)
                ListTile(
                  onTap: () => Navigator.of(context).pop(quality),
                  title: Text(
                    _videoQualityLabel(l10n, quality),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: quality == _quality
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || picked == _quality) return;
    await _applyQuality(picked);
  }

  Future<void> _applyQuality(_ViewerVideoQuality next) async {
    final l10n = AppLocalizations.of(context)!;
    if (Uri.tryParse(widget.url)?.scheme == 'file') return;
    final old = _av;
    if (old == null || !old.value.isInitialized || _switchingQuality) return;
    final nextUrl = _urlForQuality(next);
    if (nextUrl == _activeUrl && next == _quality) return;

    final oldPos = old.value.position;
    final oldPlaying = old.value.isPlaying;
    setState(() => _switchingQuality = true);

    VideoPlayerController? replacement;
    try {
      final uri = Uri.tryParse(nextUrl);
      if (uri == null || uri.scheme.isEmpty) {
        throw FormatException(l10n.media_viewer_error_bad_url);
      }
      final cached = await ChatGalleryVideoLocalCache.cachedFileIfExists(
        nextUrl,
      );
      if (cached != null) {
        replacement = VideoPlayerController.file(
          cached,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        unawaited(
          ChatGalleryVideoLocalCache.downloadToCache(
            url: nextUrl,
            onProgress: (_) {},
            isCancelled: () => !mounted,
            conversationId: widget.conversationId,
            messageId: widget.messageId,
            attachmentName: widget.attachmentName,
          ),
        );
        replacement = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
      await replacement.initialize();
      if (replacement.value.hasError) {
        throw Exception(
          replacement.value.errorDescription ??
              l10n.media_viewer_video_playback_failed,
        );
      }
      await replacement.setLooping(false);
      await replacement.setPlaybackSpeed(_playbackSpeed);
      await replacement.setVolume(_muted ? 0 : 1);
      final maxMs = replacement.value.duration.inMilliseconds;
      final target = Duration(
        milliseconds: oldPos.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0),
      );
      await replacement.seekTo(target);
      if (oldPlaying) {
        await replacement.play();
      }
      if (!mounted) {
        await replacement.dispose();
        return;
      }
      setState(() {
        _av = replacement;
        _quality = next;
        _activeUrl = nextUrl;
        _failed = false;
      });
      await old.dispose();
      replacement = null;
      _showControlsTemporarily(force: true);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.media_viewer_error_quality_switch_failed)),
      );
    } finally {
      await replacement?.dispose();
      if (mounted) setState(() => _switchingQuality = false);
    }
  }

  Future<void> _openPictureInPicture() async {
    final c = _av;
    if (c == null || !c.value.isInitialized) return;
    final supported = await _PictureInPictureBridge.isSupported();
    if (!supported) {
      if (!mounted) return;
      final l10nPip = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nPip.media_viewer_pip_not_supported)),
      );
      return;
    }
    final aspect = c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    final h = 1000;
    final w = (aspect * h).round().clamp(240, 2400);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _pipResumeTarget = this;
      await c.pause();
      final posMs = c.value.position.inMilliseconds;
      String urlForPip = _activeUrl;
      final f = await ChatGalleryVideoLocalCache.cachedFileIfExists(_activeUrl);
      if (f != null) {
        urlForPip = f.uri.toString();
      }
      final ok = await _PictureInPictureBridge.enter(
        aspectW: w,
        aspectH: h,
        videoUrl: urlForPip,
        positionMs: posMs,
      );
      if (!ok) {
        if (_pipResumeTarget == this) {
          _pipResumeTarget = null;
        }
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.media_viewer_error_pip_open_failed)),
          );
        }
      }
      return;
    }
    if (!c.value.isPlaying) {
      await c.play();
    }
    final ok = await _PictureInPictureBridge.enter(aspectW: w, aspectH: h);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.media_viewer_error_pip_open_failed)),
      );
    }
  }

  Future<void> _resumePlaybackAfterNativePip(int positionMs) async {
    final c = _av;
    if (c == null || !c.value.isInitialized) return;
    await c.seekTo(Duration(milliseconds: positionMs));
    await c.play();
    if (_pipResumeTarget == this) {
      _pipResumeTarget = null;
    }
    if (mounted) setState(() {});
  }

  Widget _wrapWithEdgeNav(Widget child) {
    if (!widget.showEdgeNavigation) return child;
    // При показанных контролах приоритет за кнопками плеера, а не навигацией по краям.
    if (_controlsVisible) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stripe = constraints.maxWidth * 0.22;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (widget.onTapPrev != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTapPrev,
                ),
              ),
            if (widget.onTapNext != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: stripe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTapNext,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unsupported = chatMediaRequiresServerNormalizationOnIos(
      widget.url,
      mimeType: widget.mimeType,
    );
    if (unsupported) {
      return _wrapWithEdgeNav(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.media_viewer_video_processing,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      );
    }
    if (_failed) {
      return _wrapWithEdgeNav(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.media_viewer_video_playback_failed,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final c = _av;
    if (c == null || !c.value.isInitialized) {
      return _wrapWithEdgeNav(
        const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Внешний GestureDetector — НЕ внутри ValueListenableBuilder/AnimatedBuilder,
    // иначе DoubleTapGestureRecognizer теряет состояние между тапами при
    // ребилдах от обновлений видеоплеера/матрицы зума.
    return _wrapWithEdgeNav(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final av = _av;
          final playing = av?.value.isPlaying ?? false;
          if (_controlsVisible) {
            if (playing) {
              _hideControlsNow();
            } else {
              unawaited(_togglePlayPause());
            }
          } else {
            _showControlsTemporarily(force: true);
          }
        },
        onDoubleTapDown: _handleVideoDoubleTap,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio > 0
                  ? c.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // InteractiveViewer ВНЕ ValueListenableBuilder — иначе он
                  // ребилдится на каждое обновление позиции (~30 раз/сек) и
                  // ScaleGestureRecognizer не успевает собрать pinch.
                  InteractiveViewer(
                    clipBehavior: Clip.hardEdge,
                    transformationController: widget.transformationController,
                    minScale: 1,
                    maxScale: 4,
                    panEnabled: true,
                    scaleEnabled: true,
                    onInteractionStart: (d) {
                      if (kDebugMode) {
                        appLogger.d(
                          '[video-viewer] interactionStart pointers=${d.pointerCount}',
                        );
                      }
                    },
                    onInteractionEnd: (d) {
                      if (kDebugMode) {
                        final scale = widget.transformationController.value
                            .getMaxScaleOnAxis();
                        appLogger.d(
                          '[video-viewer] interactionEnd scale=$scale',
                        );
                      }
                    },
                    child: VideoPlayer(c),
                  ),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: c,
                    builder: (context, value, _) {
                      final playing = value.isPlaying;
                      if (playing != _lastNotifiedPlaying) {
                        _lastNotifiedPlaying = playing;
                        final cb = widget.onPlaybackStateChanged;
                        final idx = widget.pageIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          cb?.call(idx, playing);
                        });
                      }
                      if (_controlsVisible != _lastNotifiedControlsVisible) {
                        _lastNotifiedControlsVisible = _controlsVisible;
                        final cb = widget.onControlsVisibleChanged;
                        final idx = widget.pageIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          cb?.call(idx, _controlsVisible);
                        });
                      }
                      final duration = _safeDuration(value);
                      final basePos = _scrubbing
                          ? _scrubPosition
                          : value.position;
                      final position = Duration(
                        milliseconds: basePos.inMilliseconds.clamp(
                          0,
                          duration.inMilliseconds,
                        ),
                      );
                      final sliderMax = duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0;
                      final sliderValue = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, sliderMax);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                      if (_switchingQuality)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.54),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.68),
                                ],
                                stops: const [0, 0.4, 1],
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 8 + widget.topOverlayInset),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _VideoControlChip(
                                        icon: _muted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        onTap: _toggleMute,
                                        active: !_muted,
                                      ),
                                      const SizedBox(width: 8),
                                      _VideoControlChip(
                                        icon: Icons.speed_rounded,
                                        label:
                                            '${_formatSpeed(_playbackSpeed)}x',
                                        onTap: _pickSpeed,
                                      ),
                                      const SizedBox(width: 8),
                                      _VideoControlChip(
                                        icon: Icons.hd_rounded,
                                        label: _videoQualityLabel(
                                          AppLocalizations.of(context)!,
                                          _quality,
                                        ),
                                        onTap: _pickQuality,
                                      ),
                                      const SizedBox(width: 8),
                                      _VideoControlChip(
                                        icon: Icons
                                            .picture_in_picture_alt_rounded,
                                        onTap: _openPictureInPicture,
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _VideoTransportButton(
                                      icon: Icons.replay_10_rounded,
                                      onTap: () => _seekBySeconds(-10),
                                    ),
                                    const SizedBox(width: 10),
                                    _VideoTransportButton(
                                      icon: value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      onTap: _togglePlayPause,
                                      large: true,
                                    ),
                                    const SizedBox(width: 10),
                                    _VideoTransportButton(
                                      icon: Icons.forward_10_rounded,
                                      onTap: () => _seekBySeconds(10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3.2,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                    activeTrackColor: const Color(0xFF2F86FF),
                                    inactiveTrackColor: Colors.white.withValues(
                                      alpha: 0.24,
                                    ),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: sliderMax,
                                    value: sliderValue,
                                    onChangeStart: (v) {
                                      setState(() {
                                        _scrubbing = true;
                                        _scrubPosition = Duration(
                                          milliseconds: v.round(),
                                        );
                                      });
                                    },
                                    onChanged: (v) {
                                      setState(() {
                                        _scrubbing = true;
                                        _scrubPosition = Duration(
                                          milliseconds: v.round(),
                                        );
                                      });
                                    },
                                    onChangeEnd: (v) async {
                                      setState(() {
                                        _scrubbing = false;
                                        _scrubPosition = Duration(
                                          milliseconds: v.round(),
                                        );
                                      });
                                      await c.seekTo(
                                        Duration(milliseconds: v.round()),
                                      );
                                      _showControlsTemporarily(force: true);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ViewerVideoQuality {
  auto(targetHeight: null),
  p1080(targetHeight: 1080),
  p720(targetHeight: 720),
  p480(targetHeight: 480);

  const _ViewerVideoQuality({required this.targetHeight});

  final int? targetHeight;
}

String _videoQualityLabel(AppLocalizations l10n, _ViewerVideoQuality q) {
  if (q == _ViewerVideoQuality.auto) {
    return l10n.media_viewer_video_quality_auto;
  }
  final h = q.targetHeight;
  return h == null ? l10n.media_viewer_video_quality_auto : '${h}p';
}

class _VideoControlChip extends StatelessWidget {
  const _VideoControlChip({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active
                ? const Color(0xFF2F86FF).withValues(alpha: 0.82)
                : Colors.black.withValues(alpha: 0.48),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.96)),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoTransportButton extends StatelessWidget {
  const _VideoTransportButton({
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 52.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: large
                ? const Color(0xFF2F86FF).withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          ),
          child: Icon(
            icon,
            size: large ? 34 : 28,
            color: Colors.white.withValues(alpha: 0.97),
          ),
        ),
      ),
    );
  }
}

class _PictureInPictureBridge {
  static const MethodChannel _channel = MethodChannel('lighchat/pip');
  static bool _dartInboundInstalled = false;

  /// Обработка `pipFinished` с iOS (нативный AVPlayer закрылся — продолжаем во Flutter).
  static void ensureDartInboundForPipFinished() {
    if (_dartInboundInstalled) return;
    _dartInboundInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'pipFinished') return;
      final args = call.arguments;
      var ms = 0;
      if (args is Map && args['positionMs'] is int) {
        ms = args['positionMs'] as int;
      }
      final t = _GalleryVideoPageState._pipResumeTarget;
      if (t != null && t.mounted) {
        await t._resumePlaybackAfterNativePip(ms);
      } else {
        _GalleryVideoPageState._pipResumeTarget = null;
      }
    });
  }

  static Future<bool> isSupported() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('isSupported');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enter({
    required int aspectW,
    required int aspectH,
    String? videoUrl,
    int positionMs = 0,
  }) async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final ok = await _channel.invokeMethod<bool>('enter', <String, int>{
          'aspectW': aspectW,
          'aspectH': aspectH,
        });
        return ok == true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (videoUrl == null || videoUrl.isEmpty) return false;
        final ok = await _channel.invokeMethod<bool>('enter', <String, Object?>{
          'aspectW': aspectW,
          'aspectH': aspectH,
          'videoUrl': videoUrl,
          'positionMs': positionMs,
        });
        return ok == true;
      }
    } catch (_) {}
    return false;
  }
}

/// Tile в Subject-Lift action sheet: 56pt высота, icon + label, premium-look.
class _SubjectLiftActionTile extends StatelessWidget {
  const _SubjectLiftActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Future<void> Function() onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final fg = enabled
        ? (isDark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22))
        : (isDark
              ? const Color(0xFFA0A4AD)
              : const Color(0xFF5C6470).withValues(alpha: 0.5));
    final border = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onTap() : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: fg.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
