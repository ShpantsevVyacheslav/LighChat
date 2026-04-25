import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../data/chat_media_gallery.dart';
import '../data/e2ee_decryption_orchestrator.dart';
import '../data/video_circle_utils.dart';
import 'chat_cached_network_image.dart';
import 'chat_media_viewer_screen.dart';
import 'video_cached_thumb_image.dart';
import 'video_circle_gallery.dart';

enum _MediaTab { media, circles, files, links }

class _AttachmentEntry {
  const _AttachmentEntry({required this.message, required this.attachment});

  final ChatMessage message;
  final ChatAttachment attachment;
}

class _LinkEntry {
  const _LinkEntry({required this.message, required this.url});

  final ChatMessage message;
  final String url;
}

class ConversationMediaLinksFilesScreen extends ConsumerStatefulWidget {
  const ConversationMediaLinksFilesScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
  });

  final String conversationId;
  final String currentUserId;
  final Conversation conversation;

  @override
  ConsumerState<ConversationMediaLinksFilesScreen> createState() =>
      _ConversationMediaLinksFilesScreenState();
}

class _ConversationMediaLinksFilesScreenState
    extends ConsumerState<ConversationMediaLinksFilesScreen> {
  _MediaTab _tab = _MediaTab.media;
  String? _activeCircleUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final messagesAsync = ref.watch(
      messagesProvider((conversationId: widget.conversationId, limit: 1200)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 14),
              _tabsBar(),
              const SizedBox(height: 16),
              Expanded(
                child: messagesAsync.when(
                  data: (msgsDesc) => E2eeMessagesResolver(
                    conversationId: widget.conversationId,
                    messages: msgsDesc,
                    builder:
                        (
                          context,
                          hydratedMessages,
                          ignoredDecryptedMap,
                          ignoredFailedIds,
                        ) => _content(context, hydratedMessages),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Ошибка загрузки медиа: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
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

  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(9),
                minimumSize: const Size(36, 36),
              ),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Медиа, ссылки и файлы',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: scheme.onSurface.withValues(alpha: 0.98),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabsBar() {
    final tabs = <(_MediaTab, String)>[
      (_MediaTab.media, 'Медиа'),
      (_MediaTab.circles, 'Кружки'),
      (_MediaTab.files, 'Файлы'),
      (_MediaTab.links, 'Ссылки'),
    ];
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : Colors.black).withValues(
                alpha: dark ? 0.05 : 0.04,
              ),
              border: Border.all(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: dark ? 0.08 : 0.06,
                ),
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                for (final t in tabs) Expanded(child: _tabButton(t.$1, t.$2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(_MediaTab tab, String title) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final selected = _tab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _tab = tab),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected
                ? (dark ? Colors.black : Colors.white).withValues(
                    alpha: dark ? 0.46 : 0.70,
                  )
                : Colors.transparent,
            border: selected
                ? Border.all(
                    color: (dark ? Colors.white : Colors.black).withValues(
                      alpha: dark ? 0.10 : 0.06,
                    ),
                  )
                : null,
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? scheme.onSurface.withValues(alpha: 0.98)
                  : scheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<ChatMessage> msgsDesc) {
    final msgsAsc = [...msgsDesc]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final mediaItems = collectChatMediaGalleryItems(msgsAsc);
    final circles = _collectCircleItems(msgsAsc);
    final files = _collectFileItems(msgsAsc);
    final links = _collectLinks(msgsAsc);

    return switch (_tab) {
      _MediaTab.media => _mediaGrid(mediaItems),
      _MediaTab.circles => _circlesGrid(circles),
      _MediaTab.files => _attachmentsList(files, emptyText: 'Нет файлов'),
      _MediaTab.links => _linksList(links),
    };
  }

  Widget _mediaGrid(List<ChatMediaGalleryItem> items) {
    if (items.isEmpty) {
      return _emptyBody('Нет медиа');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final att = item.attachment;
        final isVideo = isChatGridGalleryVideo(att);
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openMediaViewer(items, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isVideo)
                  VideoCachedThumbImage(videoUrl: att.url, fit: BoxFit.cover)
                else
                  ChatCachedNetworkImage(url: att.url, fit: BoxFit.cover),
                if (isVideo)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMediaViewer(
    List<ChatMediaGalleryItem> items,
    int index,
  ) async {
    if (items.isEmpty) return;
    await Navigator.of(context).push(
      chatMediaViewerPageRoute(
        ChatMediaViewerScreen(
          items: items,
          initialIndex: index,
          currentUserId: widget.currentUserId,
          senderLabel: _senderLabel,
          onReply: null,
          onForward: (item) {
            final one = chatMessageForSingleAttachmentForward(
              item.message,
              item.attachment,
            );
            context.push('/chats/forward', extra: <ChatMessage>[one]);
          },
          onDeleteItem: (_) async => false,
          onShowInChat: (_) {
            if (!mounted) return;
            Navigator.of(context).pop();
            context.go('/chats/${widget.conversationId}');
          },
        ),
      ),
    );
  }

  Widget _attachmentsList(
    List<_AttachmentEntry> items, {
    required String emptyText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return _emptyBody(emptyText);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        final a = e.attachment;
        final date = _formatTime(e.message.createdAt.toLocal());
        final title = (a.name.trim().isEmpty ? 'Вложение' : a.name.trim());
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openExternalUrl(a.url),
            child: _glass(
              radius: 16,
              child: ListTile(
                leading: Icon(
                  _iconForAttachment(a),
                  color: scheme.onSurface.withValues(alpha: 0.9),
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  date,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circlesGrid(List<_AttachmentEntry> items) {
    if (items.isEmpty) return _emptyBody('Нет кружков');
    final mapped = items
        .map((e) => (message: e.message, attachment: e.attachment))
        .toList(growable: false);
    return VideoCircleGallery(
      items: mapped,
      activeUrl: _activeCircleUrl,
      onActiveUrlChanged: (url) => setState(() => _activeCircleUrl = url),
    );
  }

  Widget _linksList(List<_LinkEntry> links) {
    final scheme = Theme.of(context).colorScheme;
    if (links.isEmpty) return _emptyBody('Нет ссылок');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: links.length,
      itemBuilder: (context, i) {
        final e = links[i];
        final date = _formatTime(e.message.createdAt.toLocal());
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openExternalUrl(e.url),
            child: _glass(
              radius: 16,
              child: ListTile(
                leading: Icon(
                  Icons.link_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.9),
                ),
                title: Text(
                  e.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  date,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyBody(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.78),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<_AttachmentEntry> _collectCircleItems(List<ChatMessage> msgsAsc) {
    final seen = <String>{};
    final out = <_AttachmentEntry>[];
    for (final m in msgsAsc) {
      if (m.isDeleted) continue;
      for (final a in m.attachments) {
        if (!isVideoCircleAttachment(a)) continue;
        if (!seen.add(a.url)) continue;
        out.add(_AttachmentEntry(message: m, attachment: a));
      }
    }
    return out.reversed.toList(growable: false);
  }

  List<_AttachmentEntry> _collectFileItems(List<ChatMessage> msgsAsc) {
    final seen = <String>{};
    final out = <_AttachmentEntry>[];
    for (final m in msgsAsc) {
      if (m.isDeleted) continue;
      for (final a in m.attachments) {
        final t = (a.type ?? '').toLowerCase();
        final n = a.name.toLowerCase();
        final isSticker = n.startsWith('sticker_') || t.contains('svg');
        final isGif = n.startsWith('gif_');
        final isCircle = isVideoCircleAttachment(a);
        final isMedia = isChatGridGalleryAttachment(a);
        // Audio attachments are shown in the "Файлы" tab (the separate
        // "Аудио" tab was removed to match the new design).
        if (isSticker || isGif || isCircle || isMedia) continue;
        if (!seen.add(a.url)) continue;
        out.add(_AttachmentEntry(message: m, attachment: a));
      }
    }
    return out.reversed.toList(growable: false);
  }

  List<_LinkEntry> _collectLinks(List<ChatMessage> msgsAsc) {
    final out = <_LinkEntry>[];
    final seen = <String>{};
    final re = RegExp(r'''(https?:\/\/[^\s<>"']+)''', caseSensitive: false);
    for (final m in msgsAsc.reversed) {
      if (m.isDeleted) continue;
      final raw = (m.text ?? '');
      if (raw.isEmpty) continue;
      for (final match in re.allMatches(raw)) {
        final url = (match.group(0) ?? '').trim();
        if (url.isEmpty) continue;
        final key = '${m.id}|$url';
        if (!seen.add(key)) continue;
        out.add(_LinkEntry(message: m, url: url));
      }
    }
    return out;
  }

  Future<void> _openExternalUrl(String raw) async {
    final u = Uri.tryParse(raw.trim());
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  IconData _iconForAttachment(ChatAttachment a) {
    final t = (a.type ?? '').toLowerCase();
    final n = a.name.toLowerCase();
    if (isVideoCircleAttachment(a)) return Icons.play_circle_rounded;
    if (t.startsWith('audio/') || n.startsWith('audio_')) {
      return Icons.graphic_eq_rounded;
    }
    if (t.startsWith('video/')) return Icons.videocam_rounded;
    if (t.startsWith('image/')) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _senderLabel(String senderId) {
    if (senderId == widget.currentUserId) return 'Вы';
    final info = widget.conversation.participantInfo?[senderId];
    if ((info?.name ?? '').trim().isNotEmpty) return info!.name.trim();
    return 'Участник';
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }

  Widget _glass({required Widget child, double radius = 20}) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? scheme.surfaceContainerHighest : scheme.surface)
                .withValues(alpha: dark ? 0.30 : 0.82),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: dark ? 0.14 : 0.10),
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
