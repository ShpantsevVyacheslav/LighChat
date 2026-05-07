import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../data/link_preview_diagnostics.dart';
import '../data/link_preview_metadata.dart';
import '../data/profile_qr_link.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'link_webview_screen.dart';

final LinkPreviewMetadataCache _linkPreviewCache = LinkPreviewMetadataCache();

class MessageLinkPreviewCard extends StatelessWidget {
  const MessageLinkPreviewCard({
    super.key,
    required this.url,
    required this.isMine,
    this.maxWidth = 320,
  });

  final String url;
  final bool isMine;
  final double maxWidth;

  void _open(BuildContext context) {
    final u = Uri.tryParse(url.trim());
    if (u == null || !(u.isScheme('http') || u.isScheme('https'))) return;
    LinkWebViewScreen.open(context, url.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final border = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.onSurface.withValues(alpha: dark ? 0.14 : 0.10);
    final bg = isMine
        ? Colors.white.withValues(alpha: 0.10)
        : (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.06 : 0.88,
          );
    final contactTarget = extractProfileTargetFromQrPayload(url);
    if (contactTarget.userId != null || contactTarget.username != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _ContactProfileLinkPreviewCard(
          target: contactTarget,
          url: url,
          isMine: isMine,
          border: border,
          bg: bg,
          onOpenUrl: () => _open(context),
        ),
      );
    }

    // Синхронная ветка — главный анти-flicker фикс. `FutureBuilder` после
    // unmount/remount (cacheExtent в reverse: true CustomScrollView) ВСЕГДА
    // проходит через `ConnectionState.waiting` один кадр в `initState`, даже
    // если наш Future уже зарезолвен. Это даёт мерцание skeleton↔контент
    // на каждом возврате карточки в viewport. Кеш умеет отвечать
    // синхронно через `peekResolved` — если данные уже видели, рендерим
    // сразу контент без `FutureBuilder` и без waiting-кадра.
    final cached = _linkPreviewCache.peekResolved(url);
    if (cached.isResolved) {
      LinkPreviewFlickerDetector.recordDone(url);
      final data = cached.data;
      if (data == null) {
        return const SizedBox.shrink();
      }
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _buildContent(context, data, scheme, border, bg),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FutureBuilder<LinkPreviewMetadata?>(
        future: _linkPreviewCache.get(url),
        builder: (context, snap) {
          final data = snap.data;
          if (snap.connectionState != ConnectionState.done) {
            LinkPreviewFlickerDetector.recordWaiting(url);
            return _skeleton(border: border, bg: bg);
          }
          LinkPreviewFlickerDetector.recordDone(url);
          if (data == null) {
            return const SizedBox.shrink();
          }
          return _buildContent(context, data, scheme, border, bg);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LinkPreviewMetadata data,
    ColorScheme scheme,
    Color border,
    Color bg,
  ) {
    final hasPlayableVideo = _isPlayableVideo(data);
    final textSection = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.siteName != null) ...[
            Text(
              data.siteName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: (isMine ? Colors.white : scheme.onSurface).withValues(
                  alpha: 0.65,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: (isMine ? Colors.white : scheme.onSurface).withValues(
                alpha: 0.92,
              ),
              height: 1.15,
            ),
          ),
          if (data.description != null) ...[
            const SizedBox(height: 6),
            Text(
              data.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (isMine ? Colors.white : scheme.onSurface).withValues(
                  alpha: 0.68,
                ),
                height: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: (isMine ? Colors.white : scheme.primary).withValues(
                alpha: 0.85,
              ),
            ),
          ),
        ],
      ),
    );

    // For the video case we want tap-on-video to control playback and
    // tap-on-text to open the URL — so we don't wrap the whole card in
    // a single InkWell.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPlayableVideo)
            _LinkPreviewInlineVideo(
              videoUrl: data.videoUrl!,
              posterUrl: data.imageUrl,
            )
          else if (data.imageUrl != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _open(context),
                child: SizedBox(
                  height: 140,
                  child: Image.network(
                    data.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => _open(context), child: textSection),
          ),
        ],
      ),
    );
  }

  Widget _skeleton({required Color border, required Color bg}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactProfileLinkPreviewCard extends StatelessWidget {
  const _ContactProfileLinkPreviewCard({
    required this.target,
    required this.url,
    required this.isMine,
    required this.border,
    required this.bg,
    required this.onOpenUrl,
  });

  final ProfileQrTarget target;
  final String url;
  final bool isMine;
  final Color border;
  final Color bg;
  final VoidCallback onOpenUrl;

  Future<UserProfile?> _resolveProfile() async {
    final db = FirebaseFirestore.instance;
    String? resolvedUserId = target.userId?.trim();
    if ((resolvedUserId == null || resolvedUserId.isEmpty) &&
        (target.username ?? '').trim().isNotEmpty) {
      final key =
          'u_${target.username!.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase()}';
      final regSnap = await db.collection('registrationIndex').doc(key).get();
      final uid = regSnap.data()?['uid'];
      if (uid is String && uid.trim().isNotEmpty) {
        resolvedUserId = uid.trim();
      }
    }
    if (resolvedUserId == null || resolvedUserId.isEmpty) return null;
    final userSnap = await db.collection('users').doc(resolvedUserId).get();
    if (!userSnap.exists) return null;
    final data = userSnap.data();
    if (data == null) return null;
    return UserProfile.fromJson(
      userSnap.id,
      data.map((k, v) => MapEntry(k, v)),
    );
  }

  void _openProfileOrUrl(BuildContext context, UserProfile? profile) {
    final uid = profile?.id.trim() ?? '';
    if (uid.isNotEmpty) {
      context.push('/contacts/user/${Uri.encodeComponent(uid)}');
      return;
    }
    onOpenUrl();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryText = (isMine ? Colors.white : scheme.onSurface).withValues(
      alpha: 0.92,
    );
    final secondaryText = (isMine ? Colors.white : scheme.onSurface).withValues(
      alpha: 0.68,
    );

    return FutureBuilder<UserProfile?>(
      future: _resolveProfile(),
      builder: (context, snap) {
        final profile = snap.data;
        final isLoading = snap.connectionState != ConnectionState.done;
        final displayName = (profile?.name ?? '').trim();
        final username = (profile?.username ?? target.username ?? '')
            .trim()
            .replaceFirst(RegExp(r'^@'), '');
        final subtitle = username.isNotEmpty
            ? '@$username'
            : 'LighChat contact';
        final title = displayName.isNotEmpty
            ? displayName
            : (isLoading ? 'Loading contact...' : 'LighChat contact');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openProfileOrUrl(context, profile),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: bg,
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ChatAvatar(
                    title: title,
                    avatarUrl: profile?.avatarThumb ?? profile?.avatar,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (isMine ? Colors.white : scheme.primary)
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: secondaryText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Decides whether `og:video` actually points to a stream we can feed
/// `video_player`. Many sites set `og:video` to an HTML player page
/// (`text/html`) — those we cannot play inline, so we keep the static image.
bool _isPlayableVideo(LinkPreviewMetadata data) {
  final v = data.videoUrl?.trim();
  if (v == null || v.isEmpty) return false;
  final type = data.videoType ?? '';
  if (type.startsWith('video/')) return true;
  if (type.startsWith('application/x-mpegurl') ||
      type.startsWith('application/vnd.apple.mpegurl')) {
    return true;
  }
  if (type.startsWith('text/html')) return false;
  // No type — guess by extension.
  final lower = Uri.tryParse(v)?.path.toLowerCase() ?? v.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov');
}

/// Tap-to-play inline video. We deliberately do NOT auto-init the controller:
/// 1) opening a chat with many video previews would hammer the network,
/// 2) iOS can hold only a small number of concurrent video pipelines.
class _LinkPreviewInlineVideo extends StatefulWidget {
  const _LinkPreviewInlineVideo({
    required this.videoUrl,
    required this.posterUrl,
  });

  final String videoUrl;
  final String? posterUrl;

  @override
  State<_LinkPreviewInlineVideo> createState() =>
      _LinkPreviewInlineVideoState();
}

class _LinkPreviewInlineVideoState extends State<_LinkPreviewInlineVideo> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;

  Future<void> _start() async {
    if (_controller != null || _initializing) return;
    setState(() => _initializing = true);
    if (kLogLinkPreviewDiagnostics) {
      debugPrint('[link-preview-video] init start url=${widget.videoUrl}');
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await c.initialize();
      if (!mounted) {
        unawaited(c.dispose());
        return;
      }
      c.setLooping(true);
      unawaited(c.play());
      if (kLogLinkPreviewDiagnostics) {
        debugPrint(
          '[link-preview-video] init OK url=${widget.videoUrl} '
          'natural=${c.value.size} natAR=${c.value.aspectRatio.toStringAsFixed(2)} '
          '(карточка остаётся 16:9, FittedBox cover)',
        );
      }
      setState(() {
        _controller = c;
        _initializing = false;
      });
    } catch (e) {
      unawaited(c.dispose());
      if (!mounted) return;
      if (kLogLinkPreviewDiagnostics) {
        debugPrint(
          '[link-preview-video] init FAIL url=${widget.videoUrl} err=$e',
        );
      }
      setState(() {
        _initializing = false;
        _failed = true;
      });
    }
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      unawaited(c.pause());
    } else {
      unawaited(c.play());
    }
    setState(() {});
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    c.setVolume(c.value.volume > 0 ? 0 : 1);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    /* Соотношение сторон карточки фиксируем на 16/9 на весь жизненный цикл, даже после инициализации
       контроллера: иначе при tap-to-play высота карточки разово меняется (особенно у вертикальных видео:
       9/16 → ~2× выше), и список под пальцем «прыгает». BoxFit.cover (через FittedBox в VideoPlayer)
       подгоняет содержимое — у портретных лента-кропа лучше, чем перекладка ListView под весь чат. */
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else if (widget.posterUrl != null)
            Image.network(
              widget.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
            )
          else
            const ColoredBox(color: Colors.black),
          // Dim overlay only when nothing is playing yet.
          if (c == null) Container(color: Colors.black.withValues(alpha: 0.25)),
          // Controls.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: c == null ? () => unawaited(_start()) : _togglePlayPause,
              child: Center(
                child: _initializing
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : (c == null || !c.value.isPlaying
                          ? Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _failed
                                    ? Icons.error_outline
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            )
                          : const SizedBox.shrink()),
              ),
            ),
          ),
          if (c != null && c.value.isInitialized)
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggleMute,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      c.value.volume > 0
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
