import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/composer_html_editing.dart';
import '../data/sanitize_message_html.dart';
import '../data/chat_attachment_upload.dart';
import '../data/chat_location_share_factory.dart';
import '../data/partner_presence_line.dart';
import '../data/chat_message_search.dart';
import '../data/pinned_messages_helper.dart';
import '../data/chat_media_gallery.dart';
import '../data/reply_preview_builder.dart';
import '../data/saved_messages_chat.dart';
import '../data/user_profile.dart';
import 'chat_html_composer_controller.dart';
import 'chat_header.dart';
import 'chat_message_search_overlay.dart';
import 'chat_wallpaper_background.dart';
import 'chat_media_viewer_screen.dart';
import 'chat_message_list.dart';
import 'chat_partner_profile_sheet.dart';
import 'chat_pinned_strip.dart';
import 'chat_selection_app_bar.dart';
import 'composer_attachment_menu.dart';
import 'composer_formatting_toolbar.dart';
import 'composer_sticker_gif_sheet.dart';
import 'composer_editing_banner.dart';
import 'composer_pending_attachments_strip.dart';
import 'composer_reply_banner.dart';
import 'photo_video_source_sheet.dart';
import 'share_location_sheet.dart';
import 'video_circle_capture_page.dart';
import 'outgoing_pending_media_album.dart';
import 'live_location_stop_banner.dart';
import 'location_send_preview_sheet.dart';
import 'message_context_menu.dart';
import 'message_html_text.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _limit = 100;
  final _controller = ChatHtmlComposerController();
  final _scrollController = ScrollController();
  final _composerFocusNode = FocusNode();
  /// Ключи строк сообщений — скролл к закреплённому / ответу и якорь подгрузки истории.
  final Map<String, GlobalKey> _messageItemKeys = <String, GlobalKey>{};
  /// Пока не пусто — в списке увеличен [cacheExtent], чтобы смонтировать строку вне экрана (грид и т.д.).
  String? _jumpScrollBoostMessageId;
  bool _loadingOlder = false;
  bool _historyLoadInFlight = false;
  bool _historyRestoreScheduled = false;
  int _historyWaitTicks = 0;
  int _historyCycleId = 0;
  int? _activeHistoryCycleId;
  int _historyBaseCount = 0;
  int _lastMessagesCount = 0;
  String? _pendingAnchorMessageId;
  double? _pendingAnchorAlignment;
  List<ChatMessage> _sortedAscCache = const <ChatMessage>[];
  bool _suppressAutoScrollToBottom = false;
  /// После подгрузки истории не дергать сразу повторный запрос у верхнего края.
  DateTime? _nearOldestCooldownUntil;
  ReplyContext? _replyingTo;
  /// Режим правки: id сообщения + превью для полосы над вводом (plain).
  String? _editingMessageId;
  String? _editingPreviewPlain;
  final Set<String> _selectedMessageIds = <String>{};
  bool _actionBusy = false;
  final List<XFile> _pendingAttachments = <XFile>[];
  /// Локальные файлы + текст, пока грузится альбом в ленте (превью + прогресс).
  _PendingImageAlbumSend? _outgoingImageAlbum;
  bool _sendBusy = false;

  /// Панель «Форматирование» над композером (паритет `FormattingToolbar.tsx`).
  bool _composerFormattingOpen = false;

  /// Поиск по сообщениям в открытом чате (паритет веб `ChatSearchOverlay`).
  bool _inChatSearch = false;
  final _chatSearchController = TextEditingController();
  final _chatSearchFocus = FocusNode();

  /// Паритет веба: какой закреп показан в полосе + индекс после тапа (см. `ChatWindow` / `pickPinnedBarIndexForViewport`).
  int _barPinIndex = 0;
  int _pinnedBarSkipSyncUntilMs = 0;
  List<PinnedMessage> _cachedSortedPins = const <PinnedMessage>[];

  /// Краткая подсветка строки после перехода к сообщению (ответ / закреп / поиск).
  String? _flashHighlightMessageId;
  Timer? _flashHighlightTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onPinnedBarScrollSync);
  }

  Color? _parseHexColor(Object? raw) {
    if (raw is! String) return null;
    final hex = raw.trim().replaceAll('#', '');
    if (hex.length != 6) return null;
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _limit = 100;
      _replyingTo = null;
      _editingMessageId = null;
      _editingPreviewPlain = null;
      _selectedMessageIds.clear();
      _loadingOlder = false;
      _historyLoadInFlight = false;
      _historyRestoreScheduled = false;
      _historyWaitTicks = 0;
      _historyCycleId = 0;
      _activeHistoryCycleId = null;
      _historyBaseCount = 0;
      _lastMessagesCount = 0;
      _pendingAnchorMessageId = null;
      _pendingAnchorAlignment = null;
      _sortedAscCache = const <ChatMessage>[];
      _suppressAutoScrollToBottom = false;
      _nearOldestCooldownUntil = null;
      _messageItemKeys.clear();
      _jumpScrollBoostMessageId = null;
      _outgoingImageAlbum = null;
      _sendBusy = false;
      _barPinIndex = 0;
      _pinnedBarSkipSyncUntilMs = 0;
      _cachedSortedPins = const <PinnedMessage>[];
      _inChatSearch = false;
      _chatSearchController.clear();
      _flashHighlightTimer?.cancel();
      _flashHighlightMessageId = null;
    }
  }

  void _exitChatSearch() {
    setState(() {
      _inChatSearch = false;
      _chatSearchController.clear();
    });
    _chatSearchFocus.unfocus();
  }

  void _openChatSearch() {
    setState(() => _inChatSearch = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chatSearchFocus.requestFocus();
    });
  }

  void _syncMessageItemKeys(List<ChatMessage> msgs) {
    final ids = msgs.map((m) => m.id).toSet();
    _messageItemKeys.removeWhere((id, _) => !ids.contains(id));
    for (final m in msgs) {
      _messageItemKeys.putIfAbsent(m.id, GlobalKey.new);
    }
  }

  void _scrollToMessageId(String messageId) {
    if (messageId.isEmpty) return;
    final idx = _sortedAscCache.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      _toast('Сообщение не найдено в загруженной истории');
      return;
    }

    final sc = _scrollController;
    final n = _sortedAscCache.length;
    if (sc.hasClients && n > 1) {
      final max = sc.position.maxScrollExtent;
      if (max > 0) {
        final frac = idx / (n - 1);
        sc.jumpTo((max * frac).clamp(0.0, max));
      }
    }

    setState(() => _jumpScrollBoostMessageId = messageId);

    _flashHighlightTimer?.cancel();
    setState(() => _flashHighlightMessageId = messageId);
    _flashHighlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _flashHighlightMessageId = null);
      }
    });

    var tries = 0;
    void attempt() {
      if (!mounted) return;
      tries++;
      final ctx = _messageItemKeys[messageId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.12,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
        setState(() => _jumpScrollBoostMessageId = null);
        return;
      }
      if (tries >= 24) {
        setState(() => _jumpScrollBoostMessageId = null);
        _toast('Сообщение не найдено в загруженной истории');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  @override
  void dispose() {
    _flashHighlightTimer?.cancel();
    _scrollController.removeListener(_onPinnedBarScrollSync);
    _composerFocusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _chatSearchController.dispose();
    _chatSearchFocus.dispose();
    super.dispose();
  }

  void _onPinnedBarScrollSync() {
    if (!mounted) return;
    if (_cachedSortedPins.isEmpty) return;
    if (DateTime.now().millisecondsSinceEpoch < _pinnedBarSkipSyncUntilMs) {
      return;
    }
    if (!_scrollController.hasClients) return;
    final asc = _sortedAscCache;
    if (asc.isEmpty) return;

    final flatRows = buildChatPinSyncFlatRows(asc);
    if (flatRows.isEmpty) return;

    final p = _scrollController.position;
    final contentLen = p.maxScrollExtent + p.viewportDimension;
    if (contentLen <= 1) return;

    final flatCount = flatRows.length;
    final startFlat =
        ((p.pixels / contentLen) * flatCount).floor().clamp(0, flatCount - 1);
    final endFlat =
        (((p.pixels + p.viewportDimension) / contentLen) * flatCount)
            .ceil()
            .clamp(0, flatCount - 1);

    final idx = pickPinnedBarIndexForViewport(
      _cachedSortedPins,
      flatRows,
      startFlat,
      endFlat,
    );
    if (idx != _barPinIndex) {
      setState(() => _barPinIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    final conversationId = widget.conversationId;

    if (!firebaseReady) {
      return const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Firebase is not configured yet.'),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Not signed in.'),
            ),
          );
        }

        final userDocAsync = ref.watch(userChatSettingsDocProvider(user.uid));
        final userDoc = userDocAsync.asData?.value ?? const <String, dynamic>{};
        final rawChatSettings = Map<String, dynamic>.from(
          userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
        );
        final fontSize = (rawChatSettings['fontSize'] as String?) ?? 'medium';
        final bubbleRadius =
            (rawChatSettings['bubbleRadius'] as String?) ?? 'rounded';
        final showTimestamps =
            (rawChatSettings['showTimestamps'] as bool?) ?? true;
        final wallpaper = rawChatSettings['chatWallpaper'] as String?;
        final bubbleColor = _parseHexColor(rawChatSettings['bubbleColor']);
        final incomingBubbleColor = _parseHexColor(
          rawChatSettings['incomingBubbleColor'],
        );

        final convAsync = ref.watch(
          conversationsProvider((
            key: conversationIdsCacheKey([widget.conversationId]),
          )),
        );
        final msgsAsync = ref.watch(
          messagesProvider((conversationId: conversationId, limit: _limit)),
        );

        return convAsync.when(
          skipLoadingOnReload: true,
          data: (list) {
            final conv = list.isNotEmpty ? list.first : null;
            String? dmOtherId;
            if (conv != null && !conv.data.isGroup) {
              final others = conv.data.participantIds
                  .where((id) => id != user.uid)
                  .toList();
              dmOtherId = others.isEmpty ? null : others.first;
            }
            final isSaved =
                conv != null &&
                isSavedMessagesConversation(conv.data, user.uid);
            final profilesRepo = ref.watch(userProfilesRepositoryProvider);
            final profileWatchIds = <String>{user.uid};
            if (conv != null && conv.data.isGroup) {
              for (final id in conv.data.participantIds) {
                if (id.isNotEmpty) profileWatchIds.add(id);
              }
            } else if (dmOtherId != null && dmOtherId.isNotEmpty) {
              profileWatchIds.add(dmOtherId);
            }
            final sortedProfileIds = profileWatchIds.toList()..sort();
            final profilesStream = profilesRepo?.watchUsersByIds(
              sortedProfileIds,
            );

            return StreamBuilder<Map<String, UserProfile>>(
              stream: profilesStream,
              builder: (context, snap) {
                final profileMap = snap.data;
                final selfProfile = profileMap == null
                    ? null
                    : profileMap[user.uid];
                final profile = dmOtherId != null && profileMap != null
                    ? profileMap[dmOtherId]
                    : null;
                final partInfo = conv?.data.participantInfo;
                final dmFallbackName = dmOtherId != null && partInfo != null
                    ? partInfo[dmOtherId]?.name
                    : null;
                final title = conv == null
                    ? ((profile?.name ?? dmFallbackName) ?? 'Чат')
                    : conv.data.isGroup
                    ? (conv.data.name ?? 'Групповой чат')
                    : isSaved
                    ? (conv.data.name ?? 'Избранное')
                    : ((profile?.name ?? dmFallbackName) ?? 'Чат');
                final dmFallbackAvatarThumb =
                    dmOtherId != null && partInfo != null
                    ? partInfo[dmOtherId]?.avatarThumb
                    : null;
                final dmFallbackAvatar = dmOtherId != null && partInfo != null
                    ? partInfo[dmOtherId]?.avatar
                    : null;
                final avatarUrl = conv?.data.isGroup == true
                    ? conv?.data.photoUrl
                    : isSaved
                    ? (selfProfile?.avatarThumb ?? selfProfile?.avatar)
                    : (profile?.avatarThumb ??
                          profile?.avatar ??
                          dmFallbackAvatarThumb ??
                          dmFallbackAvatar);
                final subtitle = conv?.data.isGroup == true
                    ? '${conv?.data.participantIds.length ?? 0} участников'
                    : isSaved
                    ? 'Сообщения и заметки только для вас'
                    : partnerPresenceLine(profile);
                final showCalls =
                    conv?.data.isGroup != true &&
                    dmOtherId != null &&
                    dmOtherId.isNotEmpty;
                final threadsUnread =
                    conv?.data.unreadThreadCounts?[user.uid] ?? 0;

                void toast(String msg) => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                void handleBack() {
                  if (_inChatSearch) {
                    _exitChatSearch();
                    return;
                  }
                  if (_selectedMessageIds.isNotEmpty) {
                    _exitSelection();
                    return;
                  }
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    nav.maybePop();
                  } else {
                    context.go('/chats');
                  }
                }

                void openProfile() {
                  if (conv == null) return;
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: ChatPartnerProfileSheet(
                          conversationId: conversationId,
                          conversation: conv.data,
                          currentUserId: user.uid,
                          selfProfile: selfProfile,
                          partnerProfile: profile,
                        ),
                      );
                    },
                  );
                }

                Widget chatShell(
                  List<ChatMessage> msgs, {
                  required bool showSpinner,
                }) {
                  final repo = ref.read(chatRepositoryProvider);
                  final isGroup = conv?.data.isGroup ?? false;
                  final pins = conv == null
                      ? <PinnedMessage>[]
                      : conversationPinnedList(conv.data);
                  final byId = {for (final m in msgs) m.id: m};
                  final sortedPins = sortPinnedMessagesByTime(pins, byId);
                  _cachedSortedPins = sortedPins;
                  final pinCount = sortedPins.length;
                  final displayPinIdx = pinCount == 0
                      ? 0
                      : _barPinIndex.clamp(0, pinCount - 1);
                  final topPin =
                      pinCount == 0 ? null : sortedPins[displayPinIdx];
                  final topInset = MediaQuery.paddingOf(context).top;
                  final headerBar = _selectedMessageIds.isEmpty ? 60.0 : 56.0;
                  final belowHeaderGap = topInset + headerBar;

                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: _selectedMessageIds.isEmpty
                        ? PreferredSize(
                            preferredSize: const Size.fromHeight(60),
                            child: SafeArea(
                              bottom: false,
                              child: ChatHeader(
                                title: title,
                                subtitle: subtitle,
                                avatarUrl: avatarUrl,
                                onBack: handleBack,
                                showCalls: showCalls,
                                threadsUnreadCount: threadsUnread,
                                onThreadsTap: () {
                                  context.push(
                                    '/chats/$conversationId/threads',
                                  );
                                },
                                onSearchTap: _openChatSearch,
                                onVideoCallTap: () =>
                                    toast('Видеозвонок: скоро'),
                                onAudioCallTap: () =>
                                    toast('Аудиозвонок: скоро'),
                                onProfileTap: openProfile,
                                searchActive: _inChatSearch,
                                searchController: _chatSearchController,
                                searchFocusNode: _chatSearchFocus,
                                onSearchClose: _exitChatSearch,
                              ),
                            ),
                          )
                        : PreferredSize(
                            preferredSize: const Size.fromHeight(56),
                            child: SafeArea(
                              bottom: false,
                              child: ChatSelectionAppBar(
                                count: _selectedMessageIds.length,
                                onClose: _exitSelection,
                                onForward: () {
                                  final sel = _selectedMessages(msgs);
                                  if (sel.isEmpty) return;
                                  _exitSelection();
                                  context.push('/chats/forward', extra: sel);
                                },
                                onDelete: () => _confirmDeleteMessages(
                                  _selectedMessages(msgs),
                                ),
                                canDelete: _canBulkDeleteFor(msgs, user.uid),
                                isBusy: _actionBusy,
                              ),
                            ),
                          ),
                    body: ChatWallpaperBackground(
                      wallpaper: wallpaper,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            SizedBox(height: belowHeaderGap),
                            if (topPin != null && conv != null)
                              ChatPinnedStrip(
                                pin: topPin,
                                totalPins: sortedPins.length,
                                onUnpin: () => _unpinMessage(topPin, conv.data),
                                onOpenPinned: () {
                                  final n = sortedPins.length;
                                  if (n == 0) return;
                                  final i = displayPinIdx;
                                  final target = sortedPins[i];
                                  _scrollToMessageId(target.messageId);
                                  setState(() {
                                    _pinnedBarSkipSyncUntilMs =
                                        DateTime.now().millisecondsSinceEpoch +
                                            900;
                                    _barPinIndex = (i - 1 + n) % n;
                                  });
                                },
                              ),
                            Expanded(
                              child: showSpinner
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ChatMessageList(
                                            messagesDesc: msgs,
                                            currentUserId: user.uid,
                                            conversationId: conversationId,
                                            conversation: conv?.data,
                                            scrollController: _scrollController,
                                            onNearOldestEdge: _onScrollLoadOlder,
                                            messageItemKeys: _messageItemKeys,
                                            jumpScrollBoostMessageId:
                                                _jumpScrollBoostMessageId,
                                            onJumpToMessageId: _scrollToMessageId,
                                            flashHighlightMessageId:
                                                _flashHighlightMessageId,
                                            selectionMode:
                                                _selectedMessageIds.isNotEmpty,
                                            selectedMessageIds:
                                                _selectedMessageIds,
                                            onMessageTap:
                                                _toggleMessageSelected,
                                            fontSize: fontSize,
                                            bubbleRadius: bubbleRadius,
                                            showTimestamps: showTimestamps,
                                            outgoingBubbleColor: bubbleColor,
                                            incomingBubbleColor:
                                                incomingBubbleColor,
                                            outgoingMediaFooter:
                                                _outgoingImageAlbum == null ||
                                                        repo == null
                                                    ? null
                                                    : Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child:
                                                            OutgoingPendingMediaAlbum(
                                                          key: ValueKey(
                                                            Object.hash(
                                                              _outgoingImageAlbum!
                                                                  .files.length,
                                                              _outgoingImageAlbum!
                                                                  .text,
                                                              _outgoingImageAlbum!
                                                                  .replyTo
                                                                  ?.messageId,
                                                            ),
                                                          ),
                                                          files:
                                                              _outgoingImageAlbum!
                                                                  .files,
                                                          captionText:
                                                              _outgoingImageAlbum!
                                                                  .text,
                                                          replyTo:
                                                              _outgoingImageAlbum!
                                                                  .replyTo,
                                                          conversationId:
                                                              widget
                                                                  .conversationId,
                                                          senderId: user.uid,
                                                          repo: repo,
                                                          isMine: true,
                                                          outgoingBubbleColor:
                                                              bubbleColor,
                                                          onFinished: () {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _outgoingImageAlbum =
                                                                  null;
                                                              _sendBusy =
                                                                  false;
                                                            });
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback(
                                                                    (_) {
                                                              if (!mounted ||
                                                                  _suppressAutoScrollToBottom) {
                                                                return;
                                                              }
                                                              final sc =
                                                                  _scrollController;
                                                              if (!sc.hasClients) {
                                                                return;
                                                              }
                                                              unawaited(
                                                                sc.animateTo(
                                                                  sc.position
                                                                      .maxScrollExtent,
                                                                  duration:
                                                                      const Duration(
                                                                    milliseconds:
                                                                        220,
                                                                  ),
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                              );
                                                            });
                                                          },
                                                          onFailed: (e) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            final b =
                                                                _outgoingImageAlbum;
                                                            setState(() {
                                                              _outgoingImageAlbum =
                                                                  null;
                                                              _sendBusy =
                                                                  false;
                                                              if (b != null) {
                                                                _pendingAttachments
                                                                  ..clear()
                                                                  ..addAll(
                                                                      b.files);
                                                                _controller
                                                                        .text =
                                                                    b.text;
                                                                _replyingTo =
                                                                    b.replyTo;
                                                              }
                                                            });
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Не удалось отправить: $e',
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                            onMessageLongPress: (m) =>
                                                _onMessageLongPress(
                                                  m,
                                                  user,
                                                  conv,
                                                  isGroup,
                                                  dmOtherId,
                                                  profile,
                                                  fontSize: fontSize,
                                                  savedMessagesChat: isSaved,
                                                ),
                                            onOpenThread: (m) {
                                              context.push(
                                                '/chats/$conversationId/thread/${m.id}',
                                                extra: m,
                                              );
                                            },
                                            onOpenMediaGallery: (att, m) {
                                              _openMediaGallery(
                                                att,
                                                m,
                                                user: user,
                                                isGroup: isGroup,
                                                dmOtherId: dmOtherId,
                                                profile: profile,
                                                profileMap: profileMap,
                                                conv: conv?.data,
                                              );
                                            },
                                          ),
                                        ),
                                        if (_inChatSearch)
                                          ListenableBuilder(
                                            listenable: _chatSearchController,
                                            builder: (context, _) {
                                              final t = _chatSearchController
                                                  .text
                                                  .trim();
                                              if (t.length < 2) {
                                                return const SizedBox.shrink();
                                              }
                                              final results =
                                                  filterMessagesForInChatSearch(
                                                msgs,
                                                _chatSearchController.text,
                                              );
                                              return Positioned.fill(
                                                child:
                                                    ChatMessageSearchOverlay(
                                                  results: results,
                                                  conversation: conv?.data,
                                                  profileMap: profileMap ??
                                                      <String, UserProfile>{},
                                                  onSelectMessageId: (id) {
                                                    _exitChatSearch();
                                                    _scrollToMessageId(id);
                                                  },
                                                  onTapScrim: _exitChatSearch,
                                                ),
                                              );
                                            },
                                          ),
                                        if (_loadingOlder)
                                          const Positioned(
                                            top: 10,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                            if (_selectedMessageIds.isEmpty) ...[
                              const LiveLocationStopBanner(),
                              _ChatComposer(
                                controller: _controller,
                                focusNode: _composerFocusNode,
                                replyingTo: _replyingTo,
                                onCancelReply: () =>
                                    setState(() => _replyingTo = null),
                                editingPreviewPlain: _editingPreviewPlain,
                                onCancelEdit: _editingMessageId != null
                                    ? _cancelInlineEdit
                                    : null,
                                onSend: () => _submitComposer(user.uid),
                                pendingAttachments: _pendingAttachments,
                                onRemovePending: (i) => setState(
                                  () => _pendingAttachments.removeAt(i),
                                ),
                                attachmentsEnabled: _editingMessageId == null,
                                sendBusy:
                                    _sendBusy || _outgoingImageAlbum != null,
                                onAttachmentSelected: (a) =>
                                    unawaited(_handleComposerAttachment(a)),
                                showFormattingToolbar: _composerFormattingOpen,
                                onCloseFormattingToolbar: () => setState(
                                  () => _composerFormattingOpen = false,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return msgsAsync.when(
                  skipLoadingOnReload: true,
                  data: (msgs) {
                    _lastMessagesCount = msgs.length;
                    _sortedAscCache = List<ChatMessage>.from(msgs)
                      ..sort((a, b) {
                        final t = a.createdAt.compareTo(b.createdAt);
                        if (t != 0) return t;
                        return a.id.compareTo(b.id);
                      });
                    _syncMessageItemKeys(_sortedAscCache);
                    _scheduleHistoryAnchorRestore(msgs);
                    return chatShell(msgs, showSpinner: false);
                  },
                  // При смене limit новый family-провайдер даёт loading: не убираем список
                  // (иначе ChatMessageList dispose → снова jump вниз).
                  loading: () {
                    if (_sortedAscCache.isNotEmpty) {
                      _syncMessageItemKeys(_sortedAscCache);
                      return chatShell(_sortedAscCache, showSpinner: false);
                    }
                    return chatShell(const <ChatMessage>[], showSpinner: true);
                  },
                  error: (e, _) => Scaffold(
                    appBar: AppBar(title: const Text('Сообщения')),
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ошибка загрузки сообщений: $e'),
                    ),
                  ),
                );
              },
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Conversation error: $e'),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Auth error: $e'),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _senderLabelForMediaViewer(
    String senderId, {
    required User user,
    required Map<String, UserProfile>? profileMap,
    required Conversation? conv,
  }) {
    if (senderId == user.uid) return 'Вы';
    final p = profileMap?[senderId];
    if ((p?.name ?? '').trim().isNotEmpty) return p!.name.trim();
    final pi = conv?.participantInfo?[senderId];
    final n = pi?.name;
    if ((n ?? '').trim().isNotEmpty) return n!.trim();
    return 'Участник';
  }

  Future<bool> _confirmDeleteMessageForViewer(ChatMessage m) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        content: const Text('Сообщение будет скрыто у всех.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await repo.softDeleteMessage(
        conversationId: widget.conversationId,
        messageId: m.id,
      );
      return true;
    } catch (e) {
      _toast('Не удалось удалить: $e');
      return false;
    }
  }

  void _openMediaGallery(
    ChatAttachment att,
    ChatMessage msg, {
    required User user,
    required bool isGroup,
    required String? dmOtherId,
    required UserProfile? profile,
    required Map<String, UserProfile>? profileMap,
    required Conversation? conv,
  }) {
    if (!mounted) return;
    final items = collectChatMediaGalleryItems(_sortedAscCache);
    if (items.isEmpty) return;
    final ix = indexInChatMediaGallery(items, att.url);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => ChatMediaViewerScreen(
          items: items,
          initialIndex: ix,
          currentUserId: user.uid,
          senderLabel: (sid) => _senderLabelForMediaViewer(
            sid,
            user: user,
            profileMap: profileMap,
            conv: conv,
          ),
          onReply: (m) {
            final leaveEdit = _editingMessageId != null;
            setState(() {
              _editingMessageId = null;
              _editingPreviewPlain = null;
              _replyingTo = buildReplyPreview(
                message: m,
                currentUserId: user.uid,
                isGroup: isGroup,
                otherUserId: dmOtherId,
                otherUserName: profile?.name,
              );
            });
            if (leaveEdit) _controller.clear();
          },
          onForward: (m) {
            if (m.isDeleted) return;
            context.push('/chats/forward', extra: <ChatMessage>[m]);
          },
          onDeleteMessage: (m) => _confirmDeleteMessageForViewer(m),
        ),
      ),
    );
  }

  void _exitSelection() {
    setState(() => _selectedMessageIds.clear());
  }

  void _toggleMessageSelected(ChatMessage m) {
    setState(() {
      if (_selectedMessageIds.contains(m.id)) {
        _selectedMessageIds.remove(m.id);
      } else {
        _selectedMessageIds.add(m.id);
      }
    });
  }

  bool _canBulkDeleteFor(List<ChatMessage> msgs, String uid) {
    if (_selectedMessageIds.isEmpty) return false;
    for (final m in msgs) {
      if (!_selectedMessageIds.contains(m.id)) continue;
      if (m.senderId != uid || m.isDeleted) return false;
    }
    return true;
  }

  List<ChatMessage> _selectedMessages(List<ChatMessage> msgs) {
    final byId = {for (final m in msgs) m.id: m};
    return _selectedMessageIds
        .map((id) => byId[id])
        .whereType<ChatMessage>()
        .toList();
  }

  Future<void> _confirmDeleteMessages(List<ChatMessage> targets) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          targets.length > 1 ? 'Удалить сообщения?' : 'Удалить сообщение?',
        ),
        content: Text(
          targets.length > 1
              ? 'Будет удалено сообщений: ${targets.length}'
              : 'Сообщение будет скрыто у всех.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionBusy = true);
    try {
      for (final m in targets) {
        await repo.softDeleteMessage(
          conversationId: widget.conversationId,
          messageId: m.id,
        );
      }
      _exitSelection();
    } catch (e) {
      _toast('Не удалось удалить: $e');
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  void _cancelInlineEdit() {
    if (!mounted) return;
    setState(() {
      _editingMessageId = null;
      _editingPreviewPlain = null;
      _composerFormattingOpen = false;
    });
    _controller.clear();
  }

  /// Редактирование в строке ввода (паритет веб), без отдельного [TextEditingController] в диалоге.
  void _startInlineEdit(ChatMessage m) {
    final plain = messageHtmlToPlainText(m.text ?? '').trim();
    var preview = plain;
    if (preview.length > 140) {
      preview = '${preview.substring(0, 140)}…';
    }
    final raw = (m.text ?? '').trim();
    final forEdit = raw.isEmpty
        ? ''
        : (raw.contains('<') ? sanitizeMessageHtml(raw) : raw);
    setState(() {
      _editingMessageId = m.id;
      _editingPreviewPlain = preview;
      _replyingTo = null;
      _composerFormattingOpen = false;
      _controller.text = forEdit;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocusNode.requestFocus();
    });
  }

  Future<void> _pinMessage(
    ChatMessage m,
    User user,
    ConversationWithId? convWrap,
    bool isGroup,
    String? otherId,
    UserProfile? profile,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    final conv = convWrap?.data;
    if (repo == null || conv == null) return;
    final existing = conversationPinnedList(conv);
    if (existing.any((p) => p.messageId == m.id)) {
      _toast('Сообщение уже закреплено');
      return;
    }
    if (existing.length >= maxPinnedMessages) {
      _toast('Лимит закреплённых ($maxPinnedMessages)');
      return;
    }
    final entry = buildPinnedMessageFromChatMessage(
      message: m,
      currentUserId: user.uid,
      isGroup: isGroup,
      otherUserId: otherId,
      otherUserName: profile?.name,
    );
    final next = [...existing, entry];
    try {
      await repo.setPinnedMessages(
        conversationId: widget.conversationId,
        pins: next,
      );
    } catch (e) {
      _toast('Не удалось закрепить: $e');
    }
  }

  Future<void> _unpinMessage(PinnedMessage p, Conversation conv) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final existing = conversationPinnedList(conv);
    final next = existing.where((x) => x.messageId != p.messageId).toList();
    try {
      await repo.setPinnedMessages(
        conversationId: widget.conversationId,
        pins: next,
      );
    } catch (e) {
      _toast('Не удалось открепить: $e');
    }
  }

  Future<void> _onMessageLongPress(
    ChatMessage m,
    User user,
    ConversationWithId? convWrap,
    bool isGroup,
    String? otherId,
    UserProfile? profile, {
    required String fontSize,
    required bool savedMessagesChat,
  }) async {
    final isMine = m.senderId == user.uid;
    final canEdit =
        isMine && !m.isDeleted && (m.text?.trim().isNotEmpty ?? false);
    final canDelete = isMine && !m.isDeleted;
    final plain = (m.text ?? '').trim();
    final hasMenuText =
        plain.isNotEmpty &&
        (plain.contains('<') ? messageHtmlToPlainText(plain).trim().isNotEmpty : true);

    final result = await showMessageContextMenu(
      context,
      message: m,
      isCurrentUser: isMine,
      hasText: hasMenuText,
      canEdit: canEdit,
      canDelete: canDelete,
      showStarAction: savedMessagesChat && !m.isDeleted,
      isStarred: false,
      chatFontSize: fontSize,
    );
    if (!mounted || result == null || result.type == MessageMenuActionType.dismissed) {
      return;
    }

    switch (result.type) {
      case MessageMenuActionType.dismissed:
        return;
      case MessageMenuActionType.reply:
        final leaveEdit = _editingMessageId != null;
        setState(() {
          _editingMessageId = null;
          _editingPreviewPlain = null;
          _replyingTo = buildReplyPreview(
            message: m,
            currentUserId: user.uid,
            isGroup: isGroup,
            otherUserId: otherId,
            otherUserName: profile?.name,
          );
        });
        if (leaveEdit) _controller.clear();
      case MessageMenuActionType.thread:
        if (!mounted) return;
        context.push(
          '/chats/${widget.conversationId}/thread/${m.id}',
          extra: m,
        );
      case MessageMenuActionType.copy:
        await copyMessageTextToClipboard(m);
        if (mounted) _toast('Текст скопирован');
      case MessageMenuActionType.edit:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startInlineEdit(m);
        });
      case MessageMenuActionType.pin:
        await _pinMessage(m, user, convWrap, isGroup, otherId, profile);
      case MessageMenuActionType.star:
        _toast('Избранное в сообщениях: скоро');
      case MessageMenuActionType.forward:
        if (m.isDeleted) return;
        if (!mounted) return;
        context.push('/chats/forward', extra: <ChatMessage>[m]);
      case MessageMenuActionType.select:
        setState(() => _selectedMessageIds.add(m.id));
      case MessageMenuActionType.delete:
        await _confirmDeleteMessages([m]);
      case MessageMenuActionType.react:
        final emoji = result.emoji;
        if (emoji == null || emoji.isEmpty || m.isDeleted) return;
        final repo = ref.read(chatRepositoryProvider);
        if (repo == null) return;
        try {
          await repo.toggleMessageReaction(
            conversationId: widget.conversationId,
            messageId: m.id,
            userId: user.uid,
            emoji: emoji,
          );
        } catch (e) {
          if (mounted) _toast('Не удалось поставить реакцию: $e');
        }
    }
  }

  void _onScrollLoadOlder() {
    final now = DateTime.now();
    if (_nearOldestCooldownUntil != null && now.isBefore(_nearOldestCooldownUntil!)) {
      return;
    }
    if (_historyLoadInFlight || _loadingOlder) return;
    _historyLoadInFlight = true;
    _suppressAutoScrollToBottom = true;
    _historyCycleId += 1;
    _activeHistoryCycleId = _historyCycleId;
    _historyWaitTicks = 0;
    _historyBaseCount = _lastMessagesCount;
    _pendingAnchorMessageId = _sortedAscCache.isNotEmpty
        ? _sortedAscCache.first.id
        : null;
    _pendingAnchorAlignment = 0.12;
    setState(() {
      _loadingOlder = true;
      _limit += 50;
    });
  }

  void _scheduleHistoryAnchorRestore(List<ChatMessage> msgs) {
    if (!_historyLoadInFlight || _historyRestoreScheduled) return;
    final scheduledCycleId = _activeHistoryCycleId;
    if (scheduledCycleId == null) return;
    _historyRestoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyRestoreScheduled = false;
      if (!mounted || !_historyLoadInFlight) return;
      if (_activeHistoryCycleId != scheduledCycleId) return;

      final hasCountGrowth = msgs.length > _historyBaseCount;
      if (!hasCountGrowth) {
        if (_historyWaitTicks < 24) {
          _historyWaitTicks += 1;
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            if (!mounted || !_historyLoadInFlight) return;
            if (_activeHistoryCycleId != scheduledCycleId) return;
            _scheduleHistoryAnchorRestore(msgs);
          });
          return;
        }
        // Новых сообщений нет — не вызываем ensureVisible (позиция уже сохранена,
        // если список не снимали с дерева при смене limit).
        _finishHistoryLoad();
        return;
      }

      final anchorId = _pendingAnchorMessageId;
      if (anchorId != null) {
        final ctx = _messageItemKeys[anchorId]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: (_pendingAnchorAlignment ?? 0.12).clamp(0.0, 1.0),
            duration: Duration.zero,
          );
          _finishHistoryLoad();
          return;
        }
        if (_historyWaitTicks < 40) {
          _historyWaitTicks += 1;
          Future<void>.delayed(const Duration(milliseconds: 40), () {
            if (!mounted || !_historyLoadInFlight) return;
            if (_activeHistoryCycleId != scheduledCycleId) return;
            _scheduleHistoryAnchorRestore(msgs);
          });
          return;
        }
      }

      _finishHistoryLoad();
    });
  }

  void _finishHistoryLoad() {
    _nearOldestCooldownUntil = DateTime.now().add(const Duration(milliseconds: 800));
    _historyLoadInFlight = false;
    _suppressAutoScrollToBottom = false;
    _activeHistoryCycleId = null;
    _historyWaitTicks = 0;
    _historyBaseCount = 0;
    _pendingAnchorMessageId = null;
    _pendingAnchorAlignment = null;
    if (mounted && _loadingOlder) {
      setState(() => _loadingOlder = false);
    }
  }

  Future<void> _submitComposer(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    if (_sendBusy) return;
    final rawComposer = _controller.text;
    final prepared =
        ComposerHtmlEditing.prepareChatMessageHtmlForSend(rawComposer);
    final plainOut =
        prepared.isEmpty ? '' : messageHtmlToPlainText(prepared).trim();
    final editingId = _editingMessageId;

    if (editingId != null) {
      if (_pendingAttachments.isNotEmpty) {
        _toast('При редактировании вложения недоступны');
        return;
      }
      if (plainOut.isEmpty) {
        _toast('Текст не может быть пустым');
        return;
      }
    } else if (plainOut.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    if (editingId != null) {
      try {
        await repo.updateMessageText(
          conversationId: widget.conversationId,
          messageId: editingId,
          text: prepared,
        );
        if (!mounted) return;
        setState(() {
          _editingMessageId = null;
          _editingPreviewPlain = null;
          _composerFormattingOpen = false;
        });
        _controller.clear();
      } catch (e) {
        if (mounted) _toast('Не удалось сохранить: $e');
      }
      return;
    }

    final pending = List<XFile>.from(_pendingAttachments);
    if (pending.isNotEmpty) {
      final replySnap = _replyingTo;
      final textSave = prepared;
      if (pending.every(isOutgoingAlbumLocalImage)) {
        setState(() {
          _outgoingImageAlbum = _PendingImageAlbumSend(
            files: pending,
            text: textSave,
            replyTo: replySnap,
          );
          _pendingAttachments.clear();
          _controller.clear();
          _replyingTo = null;
          _composerFormattingOpen = false;
          _sendBusy = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final sc = _scrollController;
          if (sc.hasClients) {
            sc.jumpTo(sc.position.maxScrollExtent);
          }
        });
        return;
      }
      setState(() => _sendBusy = true);
      _controller.clear();
      setState(() => _pendingAttachments.clear());
      try {
        final storage = FirebaseStorage.instance;
        final uploaded = <ChatAttachment>[];
        for (final f in pending) {
          uploaded.add(
            await uploadChatAttachmentFromXFile(
              storage: storage,
              conversationId: widget.conversationId,
              file: f,
            ),
          );
        }
        await repo.sendTextMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: textSave,
          replyTo: replySnap,
          attachments: uploaded,
        );
        if (mounted) {
          setState(() {
            _replyingTo = null;
            _composerFormattingOpen = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _suppressAutoScrollToBottom) return;
            final sc = _scrollController;
            if (!sc.hasClients) return;
            unawaited(
              sc.animateTo(
                sc.position.maxScrollExtent,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              ),
            );
          });
        }
      } catch (e) {
        if (mounted) {
          _controller.text = rawComposer;
          setState(() {
            _pendingAttachments
              ..clear()
              ..addAll(pending);
            _replyingTo = replySnap;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось отправить сообщение: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _sendBusy = false);
      }
      return;
    }

    final replySnap = _replyingTo;
    _controller.clear();
    try {
      await repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: plainOut.isEmpty ? '' : prepared,
        replyTo: replySnap,
      );
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _composerFormattingOpen = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _suppressAutoScrollToBottom) return;
          final sc = _scrollController;
          if (!sc.hasClients) return;
          unawaited(
            sc.animateTo(
              sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        });
      }
    } catch (e) {
      _controller.text = rawComposer;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить сообщение: $e')),
      );
    }
  }

  Future<void> _sendLocationShare() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast('Сервис чата недоступен');
      return;
    }
    final convAsync = ref.read(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final convList = convAsync.asData?.value;
    final conv = convList != null && convList.isNotEmpty ? convList.first : null;
    if (conv == null) {
      _toast('Чат ещё загружается');
      return;
    }
    final participantIds = conv.data.participantIds;
    if (participantIds.isEmpty) {
      _toast('Нет участников чата');
      return;
    }

    final durationId = await showShareLocationSettingsSheet(context);
    if (!mounted || durationId == null) return;

    setState(() => _sendBusy = true);
    try {
      final bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } on MissingPluginException catch (_) {
        if (mounted) {
          _toast(
            'Геолокация не подключена в iOS-сборке. В каталоге mobile/app/ios выполните pod install и пересоберите приложение.',
          );
        }
        return;
      }
      if (!serviceEnabled) {
        if (mounted) _toast('Включите службу геолокации');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _toast('Нет доступа к геолокации');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _sendBusy = false);

      final confirmed = await showLocationSendPreviewSheet(
        context,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyM: pos.accuracy,
      );
      if (!mounted || !confirmed) return;

      setState(() => _sendBusy = true);

      final share = buildChatLocationShareFromPosition(
        pos,
        durationId: durationId,
      );
      final activate = shouldActivateUserLiveShare(durationId);
      final userLiveExp = userLiveExpiresAtForSend(durationId);
      final replySnap = _replyingTo;

      await repo.sendLocationShareMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        participantIds: participantIds,
        locationShare: share,
        replyTo: replySnap,
        activateUserLiveShare: activate,
        userLiveExpiresAt: userLiveExp,
      );

      if (mounted) {
        setState(() => _replyingTo = null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _suppressAutoScrollToBottom) return;
          final sc = _scrollController;
          if (!sc.hasClients) return;
          unawaited(
            sc.animateTo(
              sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить геолокацию: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _openVideoCircleCapture() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast('Сервис чата недоступен');
      return;
    }
    if (_editingMessageId != null) {
      _toast('Сначала завершите редактирование');
      return;
    }
    await pushVideoCircleCapturePage(
      context,
      onSend: (raw) => _sendVideoCircleFile(uid, repo, raw),
    );
  }

  Future<void> _sendVideoCircleFile(
    String uid,
    ChatRepository repo,
    XFile raw,
  ) async {
    final lower = raw.path.toLowerCase();
    final ext = lower.endsWith('.mov') || lower.endsWith('.qt')
        ? 'mov'
        : 'mp4';
    final mime = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    final name =
        'video-circle_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = XFile(raw.path, name: name, mimeType: mime);
    final replySnap = _replyingTo;
    setState(() => _sendBusy = true);
    try {
      final uploaded = await uploadChatAttachmentFromXFile(
        storage: FirebaseStorage.instance,
        conversationId: widget.conversationId,
        file: file,
      );
      await repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: '',
        replyTo: replySnap,
        attachments: [uploaded],
      );
      if (mounted) {
        setState(() => _replyingTo = null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _suppressAutoScrollToBottom) return;
          final sc = _scrollController;
          if (!sc.hasClients) return;
          unawaited(
            sc.animateTo(
              sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _openStickersGifPanel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast('Войдите в аккаунт');
      return;
    }
    final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    if (stickerRepo == null || chatRepo == null) {
      _toast('Сервис недоступен');
      return;
    }
    await showComposerStickerGifSheet(
      context: context,
      userId: uid,
      repo: stickerRepo,
      onPickAttachment: (att) {
        unawaited(_sendStickerOrGifAttachment(uid, chatRepo, att));
      },
    );
  }

  Future<void> _sendStickerOrGifAttachment(
    String uid,
    ChatRepository repo,
    ChatAttachment att,
  ) async {
    final replySnap = _replyingTo;
    setState(() => _sendBusy = true);
    try {
      await repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: '',
        replyTo: replySnap,
        attachments: [att],
      );
      if (mounted) {
        setState(() => _replyingTo = null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _suppressAutoScrollToBottom) return;
          final sc = _scrollController;
          if (!sc.hasClients) return;
          unawaited(
            sc.animateTo(
              sc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _handleComposerAttachment(ComposerAttachmentAction action) async {
    if (_editingMessageId != null) {
      _toast('Сначала завершите редактирование');
      return;
    }
    switch (action) {
      case ComposerAttachmentAction.photoVideo:
        final choice = await showPhotoVideoSourceSheet(context);
        if (!mounted || choice == null) return;
        final picker = ImagePicker();
        try {
          switch (choice) {
            case 'gallery':
              final list = await picker.pickMultipleMedia();
              if (!mounted || list.isEmpty) return;
              setState(() => _pendingAttachments.addAll(list));
              break;
            case 'camera_photo':
              final x = await picker.pickImage(source: ImageSource.camera);
              if (!mounted || x == null) return;
              setState(() => _pendingAttachments.add(x));
              break;
            case 'camera_video':
              final xv = await picker.pickVideo(source: ImageSource.camera);
              if (!mounted || xv == null) return;
              setState(() => _pendingAttachments.add(xv));
              break;
            default:
              break;
          }
        } catch (e) {
          if (mounted) _toast('Не удалось выбрать медиа: $e');
        }
        break;
      case ComposerAttachmentAction.deviceFiles:
        try {
          final r = await FilePicker.pickFiles(allowMultiple: true);
          if (!mounted || r == null || r.files.isEmpty) return;
          final add = <XFile>[];
          for (final p in r.files) {
            final path = p.path;
            if (path != null) {
              add.add(XFile(path, name: p.name));
            }
          }
          if (add.isNotEmpty) {
            setState(() => _pendingAttachments.addAll(add));
          }
        } catch (e) {
          if (mounted) _toast('Не удалось выбрать файл: $e');
        }
        break;
      case ComposerAttachmentAction.videoCircle:
        unawaited(_openVideoCircleCapture());
        break;
      case ComposerAttachmentAction.location:
        unawaited(_sendLocationShare());
        break;
      case ComposerAttachmentAction.poll:
        _toast('Опрос: скоро');
        break;
      case ComposerAttachmentAction.stickersGif:
        unawaited(_openStickersGifPanel());
        break;
      case ComposerAttachmentAction.format:
        setState(() => _composerFormattingOpen = true);
        break;
    }
  }
}

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachmentSelected,
    required this.pendingAttachments,
    required this.onRemovePending,
    required this.attachmentsEnabled,
    required this.sendBusy,
    this.replyingTo,
    this.onCancelReply,
    this.editingPreviewPlain,
    this.onCancelEdit,
    this.showFormattingToolbar = false,
    this.onCloseFormattingToolbar,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final void Function(ComposerAttachmentAction action) onAttachmentSelected;
  final List<XFile> pendingAttachments;
  final void Function(int index) onRemovePending;
  final bool attachmentsEnabled;
  final bool sendBusy;
  final ReplyContext? replyingTo;
  final VoidCallback? onCancelReply;
  final String? editingPreviewPlain;
  final VoidCallback? onCancelEdit;
  final bool showFormattingToolbar;
  final VoidCallback? onCloseFormattingToolbar;

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  final GlobalKey _composerColumnKey = GlobalKey();
  OverlayEntry? _attachmentOverlayEntry;

  @override
  void dispose() {
    _attachmentOverlayEntry?.remove();
    super.dispose();
  }

  void _closeAttachmentMenu() {
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
  }

  void _openAttachmentMenu() {
    if (!widget.attachmentsEnabled || widget.sendBusy) return;
    _closeAttachmentMenu();
    final box =
        _composerColumnKey.currentContext?.findRenderObject() as RenderBox?;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    var bottomFrom = 100.0;
    if (box != null && box.hasSize) {
      final topY = box.localToGlobal(Offset.zero).dy;
      bottomFrom = (screenH - topY).clamp(56.0, screenH);
    }
    _attachmentOverlayEntry = showComposerAttachmentOverlay(
      context: context,
      bottomFromScreenBottom: bottomFrom,
      onDismissed: () {
        _attachmentOverlayEntry = null;
      },
      onSelected: widget.onAttachmentSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          key: _composerColumnKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editingPreviewPlain != null && widget.onCancelEdit != null)
              ComposerEditingBanner(
                previewPlain: widget.editingPreviewPlain!,
                onCancel: widget.onCancelEdit!,
              )
            else if (widget.replyingTo != null && widget.onCancelReply != null)
              ComposerReplyBanner(
                replyTo: widget.replyingTo!,
                onCancel: widget.onCancelReply!,
              ),
            ComposerPendingAttachmentsStrip(
              files: widget.pendingAttachments,
              onRemoveAt: widget.onRemovePending,
            ),
            if (widget.showFormattingToolbar &&
                widget.onCloseFormattingToolbar != null) ...[
              ComposerFormattingToolbar(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onBack: widget.onCloseFormattingToolbar!,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: 'Вложения',
                  onPressed: widget.attachmentsEnabled && !widget.sendBusy
                      ? _openAttachmentMenu
                      : null,
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: widget.attachmentsEnabled && !widget.sendBusy
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withValues(alpha: dark ? 0.08 : 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: dark ? 0.12 : 0.35,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      strutStyle: const StrutStyle(
                        forceStrutHeight: true,
                        height: 1.25,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Сообщение',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.primary.withValues(alpha: 0.80),
                  ),
                  child: widget.sendBusy
                      ? Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: widget.onSend,
                          icon: Icon(
                            Icons.send_rounded,
                            color: scheme.onPrimary,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingImageAlbumSend {
  _PendingImageAlbumSend({
    required this.files,
    required this.text,
    this.replyTo,
  });

  final List<XFile> files;
  final String text;
  final ReplyContext? replyTo;
}
