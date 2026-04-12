import 'dart:async';
import 'dart:io' show Directory, File, HttpException;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:lighchat_models/lighchat_models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../data/chat_media_gallery.dart';
import 'chat_cached_network_image.dart';
import 'chat_vlc_network_media.dart';
import 'vlc_ios_simulator_stub.dart'
    if (dart.library.io) 'vlc_ios_simulator_io.dart' as vlc_sim;

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
    required this.onDeleteMessage,
  });

  final List<ChatMediaGalleryItem> items;
  final int initialIndex;
  final String currentUserId;
  final String Function(String senderId) senderLabel;
  /// Если `null`, кнопки «Ответить» скрыты (например, экран ветки без превью ответа).
  final void Function(ChatMessage message)? onReply;
  final void Function(ChatMessage message) onForward;
  /// `true`, если сообщение удалено (диалог подтверждения — на стороне родителя).
  final Future<bool> Function(ChatMessage message) onDeleteMessage;

  @override
  State<ChatMediaViewerScreen> createState() => _ChatMediaViewerScreenState();
}

class _ChatMediaViewerScreenState extends State<ChatMediaViewerScreen> {
  late List<ChatMediaGalleryItem> _items;
  late PageController _pageController;
  late int _index;
  final Map<int, TransformationController> _imageTransforms = {};
  bool _zoomed = false;

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

  Future<void> _saveCurrent() async {
    final item = _current;
    if (item == null) return;
    final url = item.attachment.url;
    final rawName = item.attachment.name.trim();
    final name = rawName.isNotEmpty
        ? rawName.replaceAll(RegExp(r'[/\\]'), '_')
        : 'media';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final f = File(
        '${Directory.systemTemp.path}/lighchat_${DateTime.now().millisecondsSinceEpoch}_$name',
      );
      await f.writeAsBytes(res.bodyBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: $e')),
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
    final m = _current?.message;
    if (m == null) return;
    Navigator.of(context).pop();
    widget.onForward(m);
  }

  Future<void> _delete() async {
    final m = _current?.message;
    if (m == null) return;
    final ok = await widget.onDeleteMessage(m);
    if (!ok || !mounted) return;
    final mid = m.id;
    setState(() {
      _items.removeWhere((e) => e.message.id == mid);
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
    final canDelete =
        cur != null && cur.message.senderId == widget.currentUserId;
    final showReply = widget.onReply != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
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
                      url: att.url,
                      mimeType: att.type,
                    );
                  }
                  final tc = _transformFor(i);
                  return Center(
                    child: InteractiveViewer(
                      transformationController: tc,
                      minScale: 1,
                      maxScale: 5,
                      clipBehavior: Clip.none,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: ChatCachedNetworkImage(
                        url: att.url,
                        fit: BoxFit.contain,
                        showProgressIndicator: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!_zoomed)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: const EdgeInsets.symmetric(
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
                                          color: Colors.white
                                              .withValues(alpha: 0.10),
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
                                      color: Colors.white
                                          .withValues(alpha: 0.52),
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
                            case 'forward':
                              _forward();
                            case 'save':
                              unawaited(_saveCurrent());
                            case 'delete':
                              unawaited(_delete());
                            default:
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (showReply)
                            const PopupMenuItem(
                              value: 'reply',
                              child: ListTile(
                                leading: Icon(Icons.reply_rounded),
                                title: Text('Ответить'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'forward',
                            child: ListTile(
                              leading: Icon(Icons.forward_rounded),
                              title: Text('Переслать'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'save',
                            child: ListTile(
                              leading: Icon(Icons.download_rounded),
                              title: Text('Сохранить'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                title: Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_items.length > 1 && !_zoomed) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: _index > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: _index < _items.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ],
            if (!_zoomed)
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
            colors: [
              Color(0xFF27272A),
              Color(0xFF09090B),
              Color(0xFF000000),
            ],
          ),
        ),
      );
    }
    final url = att.url;
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Transform.scale(
            scale: 1.18,
            child: Image(
              image: CachedNetworkImageProvider(url),
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

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: enabled ? 0.35 : 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.35),
            size: 30,
          ),
        ),
      ),
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
    required this.url,
    this.mimeType,
  });

  final String url;
  final String? mimeType;

  @override
  State<_GalleryVideoPage> createState() => _GalleryVideoPageState();
}

class _GalleryVideoPageState extends State<_GalleryVideoPage> {
  VideoPlayerController? _av;
  VlcPlayerController? _vlc;
  bool _failed = false;
  bool _vlcMode = false;

  @override
  void initState() {
    super.initState();
    _vlcMode = _needVlc;
    if (_vlcMode) {
      if (vlc_sim.vlcIosSimulatorHost()) {
        setState(() => _failed = true);
        return;
      }
      _vlc = VlcPlayerController.network(
        widget.url,
        hwAcc: HwAcc.auto,
        autoPlay: false,
        autoInitialize: true,
      );
      _vlc!.addListener(_onVlc);
    } else {
      unawaited(_initAv());
    }
  }

  bool get _needVlc =>
      chatMediaNeedsVlcOnIos(widget.url, mimeType: widget.mimeType);

  void _onVlc() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initAv() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      if (c.value.hasError) {
        await c.dispose();
        setState(() => _failed = true);
        return;
      }
      setState(() => _av = c);
    } catch (_) {
      await c?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    final v = _vlc;
    if (v != null) {
      v.removeListener(_onVlc);
      unawaited(v.dispose());
    }
    _av?.dispose();
    super.dispose();
  }

  Future<void> _toggleVlcPlay() async {
    final v = _vlc;
    if (v == null) return;
    final s = v.value;
    if (!s.isInitialized || s.hasError) return;
    if (s.isPlaying) {
      await v.pause();
    } else {
      await v.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
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
      );
    }

    if (_vlcMode) {
      final v = _vlc!;
      final s = v.value;
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: s.hasError
              ? const Text(
                  'Ошибка воспроизведения',
                  style: TextStyle(color: Colors.white70),
                )
              : !s.isInitialized
              ? const CircularProgressIndicator()
              : AspectRatio(
                  aspectRatio: s.aspectRatio > 0 ? s.aspectRatio : 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VlcPlayer(
                        controller: v,
                        aspectRatio:
                            s.aspectRatio > 0 ? s.aspectRatio : 16 / 9,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleVlcPlay,
                          child: AnimatedOpacity(
                            opacity: s.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 72,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final c = _av;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(c),
              VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                colors: VideoProgressColors(
                  playedColor: Colors.white.withValues(alpha: 0.92),
                  bufferedColor: Colors.white.withValues(alpha: 0.35),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (c.value.isPlaying) {
                      await c.pause();
                    } else {
                      await c.play();
                    }
                    setState(() {});
                  },
                  child: AnimatedOpacity(
                    opacity: c.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
