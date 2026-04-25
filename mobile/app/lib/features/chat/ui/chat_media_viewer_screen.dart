import 'dart:async';
import 'dart:io' show Directory, File, FileSystemException, HttpException;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:video_player/video_player.dart';

import '../data/chat_media_gallery.dart';
import 'chat_gallery_video_local_cache.dart';
import 'chat_media_viewer_photo_page.dart';
import 'chat_vlc_network_media.dart';

const _ruMonthsGenitive = <String>[
  '',
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String formatChatMediaViewerDateRu(DateTime utcOrLocal) {
  final d = utcOrLocal.toLocal();
  final m = _ruMonthsGenitive[d.month.clamp(1, 12)];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${m.toUpperCase()} ${d.year}, $hh:$mm';
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
    required this.currentUserId,
    required this.senderLabel,
    this.onReply,
    required this.onForward,
    required this.onDeleteItem,
    this.onShowInChat,
  });

  final List<ChatMediaGalleryItem> items;
  final int initialIndex;
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

  @override
  State<ChatMediaViewerScreen> createState() => _ChatMediaViewerScreenState();
}

class _ChatMediaViewerScreenState extends State<ChatMediaViewerScreen> {
  static const double _kTopChromeFallbackHeight = 68;

  late List<ChatMediaGalleryItem> _items;
  late PageController _pageController;
  late int _index;
  final Map<int, TransformationController> _imageTransforms = {};
  final GlobalKey _topChromeKey = GlobalKey();
  double _topChromeMeasuredHeight = 0;
  bool _zoomed = false;
  double _dismissDragY = 0;

  /// Скрывает нижние FAB (ответить / переслать / …), пока активная страница — видео и оно играет.
  bool _galleryVideoPlaying = false;

  /// Состояние видимости контролов текущей video-страницы.
  /// Держим в родителе, чтобы можно было расширять логику chrome без
  /// подписки на контроллер плеера в этом виджете.
  bool _galleryVideoControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _items = List<ChatMediaGalleryItem>.from(widget.items);
    final n = _items.length;
    final start = n == 0 ? 0 : widget.initialIndex.clamp(0, n - 1);
    _index = start;
    _pageController = PageController(initialPage: start);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _imageTransforms.values) {
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

  Future<void> _saveCurrent() async {
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
              const SnackBar(
                content: Text('Нет доступа к сохранению в галерею'),
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
        throw const FormatException('Bad media URL');
      }
      if (uri.scheme == 'file') {
        final src = File(uri.toFilePath());
        if (!await src.exists()) {
          throw const FileSystemException('Файл не найден');
        }
        await src.copy(f.path);
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final res = await http.get(uri);
        if (res.statusCode != 200) {
          throw HttpException('HTTP ${res.statusCode}');
        }
        await f.writeAsBytes(res.bodyBytes);
      } else {
        throw FormatException('Unsupported media scheme: ${uri.scheme}');
      }
      final video = isChatGridGalleryVideo(item.attachment);
      if (video) {
        await Gal.putVideo(f.path);
      } else {
        await Gal.putImage(f.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Сохранено в галерею')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
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
    final showTopChrome = !_zoomed && !(currentIsVideo && _galleryVideoPlaying);
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
                  _BackdropLayer(item: cur?.attachment),
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
                        });
                        for (final e in _imageTransforms.entries) {
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
                                          formatChatMediaViewerDateRu(
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
                                    _forward();
                                    return;
                                  case 'save':
                                    unawaited(_saveCurrent());
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
                                return [
                                  if (showReply)
                                    PopupMenuItem(
                                      value: 'reply',
                                      child: Row(
                                        children: [
                                          Icon(Icons.reply_rounded, color: hi),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Ответить',
                                            style: TextStyle(
                                              color: hi,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'forward',
                                    child: Row(
                                      children: [
                                        Icon(Icons.forward_rounded, color: hi),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Переслать',
                                          style: TextStyle(
                                            color: hi,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'save',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download_rounded, color: hi),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Сохранить',
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
                                            'Показать в чате',
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
                                          const Text(
                                            'Удалить',
                                            style: TextStyle(
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
                  if (!_zoomed && !_galleryVideoPlaying)
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
  const _BackdropLayer({this.item});

  final ChatAttachment? item;

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
    final ImageProvider<Object>? bgImage = (uri != null && uri.scheme == 'file')
        ? FileImage(File(uri.toFilePath()))
        : ((uri != null && uri.hasScheme)
              ? CachedNetworkImageProvider(url)
              : null);
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

class _GalleryVideoPageState extends State<_GalleryVideoPage> {
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
  final TransformationController _videoZoom = TransformationController();

  /// Прогресс сохранения в локальный кэш (0..1) или `null`, если полоска не нужна.
  double? _cacheProgress;
  bool _downloadCancelled = false;
  bool _lastNotifiedPlaying = false;
  bool _lastNotifiedControlsVisible = true;

  /// Экземпляр, которому нативный PiP шлёт `pipFinished` (последний, открывший PiP).
  static _GalleryVideoPageState? _pipResumeTarget;

  @override
  void initState() {
    super.initState();
    _activeUrl = _urlForQuality(_quality);
    _PictureInPictureBridge.ensureDartInboundForPipFinished();
    unawaited(_initAv(url: _activeUrl));
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
          // Важно: не блокировать воспроизведение полной скачкой в кэш.
          // Играем сразу по сети, а кэширование (если нужно) идёт параллельно.
          if (mounted) setState(() => _cacheProgress = 0);
          unawaited(
            ChatGalleryVideoLocalCache.downloadToCache(
              url: url,
              onProgress: (p) {
                if (!mounted || _downloadCancelled) return;
                setState(() => _cacheProgress = p ?? _cacheProgress);
              },
              isCancelled: () => _downloadCancelled || !mounted,
            ).whenComplete(() {
              if (!mounted || _downloadCancelled) return;
              setState(() => _cacheProgress = null);
            }),
          );
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
        setState(() {
          _failed = true;
          _cacheProgress = null;
        });
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
    _downloadCancelled = true;
    _hideControlsTimer?.cancel();
    _av?.dispose();
    _videoZoom.dispose();
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
        const options = <double>[1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Скорость воспроизведения',
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
                'Качество',
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
                    quality.label,
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
        throw const FormatException('Bad URL');
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
          ),
        );
        replacement = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
      await replacement.initialize();
      if (replacement.value.hasError) {
        throw Exception(replacement.value.errorDescription ?? 'Playback error');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось переключить качество')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PiP не поддерживается на этом устройстве'),
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть PiP')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось открыть PiP')));
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
    final unsupported = chatMediaRequiresServerNormalizationOnIos(
      widget.url,
      mimeType: widget.mimeType,
    );
    if (unsupported) {
      return _wrapWithEdgeNav(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Видео обрабатывается на сервере и скоро станет доступно.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
              'Не удалось воспроизвести видео.',
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
        ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: CircularProgressIndicator()),
              if (_cacheProgress != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRect(
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: _cacheProgress! >= 1 ? null : _cacheProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2F86FF).withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return _wrapWithEdgeNav(
      ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
            child: ValueListenableBuilder<VideoPlayerValue>(
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
                final basePos = _scrubbing ? _scrubPosition : value.position;
                final position = Duration(
                  milliseconds: basePos.inMilliseconds.clamp(
                    0,
                    duration.inMilliseconds,
                  ),
                );
                final sliderMax = duration.inMilliseconds > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0;
                final sliderValue = position.inMilliseconds.toDouble().clamp(
                  0.0,
                  sliderMax,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_controlsVisible) {
                      if (value.isPlaying) {
                        _hideControlsNow();
                      } else {
                        unawaited(_togglePlayPause());
                      }
                    } else {
                      _showControlsTemporarily(force: true);
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        clipBehavior: Clip.hardEdge,
                        transformationController: _videoZoom,
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: false,
                        child: VideoPlayer(c),
                      ),
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
                                        label: _quality.label,
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _ViewerVideoQuality {
  auto(label: 'Авто', targetHeight: null),
  p1080(label: '1080p', targetHeight: 1080),
  p720(label: '720p', targetHeight: 720),
  p480(label: '480p', targetHeight: 480);

  const _ViewerVideoQuality({required this.label, required this.targetHeight});

  final String label;
  final int? targetHeight;
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
