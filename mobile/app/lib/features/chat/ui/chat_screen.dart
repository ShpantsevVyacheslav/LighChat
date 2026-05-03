import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../data/composer_clipboard_paste.dart';
import '../data/e2ee_decryption_orchestrator.dart';
import '../data/e2ee_data_type_policy.dart';
import '../data/e2ee_runtime.dart';
import '../data/e2ee_attachment_send_helper.dart';
import '../data/composer_html_editing.dart';
import '../data/chat_attachment_upload.dart';
import '../data/chat_location_share_factory.dart';
import '../data/partner_presence_line.dart';
import '../data/chat_message_search.dart';
import '../data/pinned_messages_helper.dart';
import '../data/chat_media_gallery.dart';
import '../data/reply_preview_builder.dart';
import '../data/saved_messages_chat.dart';
import '../data/group_mention_candidates.dart';
import '../data/contact_display_name.dart';
import '../data/emoji_burst_animation_profile.dart';
import '../data/user_profile.dart';
import '../data/user_contacts_repository.dart';
import '../data/chat_message_draft_storage.dart';
import '../data/recent_stickers_store.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_html_composer_controller.dart';
import 'chat_audio_call_screen.dart';
import 'chat_video_call_screen.dart';
import 'chat_header.dart';
import 'schedule_message_sheet.dart';
import 'scheduled_messages_screen.dart';
import 'chat_message_search_overlay.dart';
import 'effective_chat_wallpaper.dart';
import 'chat_wallpaper_background.dart';
import 'chat_media_viewer_screen.dart';
import 'chat_message_list.dart';
import 'chat_partner_profile_sheet.dart';
import 'chat_pinned_strip.dart';
import 'chat_scroll_anchor_button.dart';
import 'chat_selection_app_bar.dart';
import 'composer_attachment_menu.dart';
import 'composer_sticker_gif_sheet.dart';
import 'composer_sticker_suggestion_row.dart';
import 'e2ee_mobile_block_banner.dart';
import 'deleted_account_readonly_banner.dart';
import 'chat_image_editor_screen.dart';
import 'chat_video_editor_screen.dart';
import 'photo_video_source_sheet.dart';
import 'chat_poll_create_sheet.dart';
import 'share_location_sheet.dart';
import 'video_circle_capture_page.dart';
import 'voice_message_record_sheet.dart';
import '../data/chat_outbox_attachment_notifier.dart';
import '../data/user_block_providers.dart';
import '../data/user_block_utils.dart';
import '../data/chat_pending_album_provider.dart';
import '../data/outgoing_album_e2ee_context.dart';
import '../data/pending_image_album_send.dart';
import 'outgoing_pending_media_album.dart';
import 'live_location_stop_banner.dart';
import 'dm_game_lobby_banner.dart';
import 'location_send_preview_sheet.dart';
import 'message_context_menu.dart';
import 'message_html_text.dart';
import 'chat_composer.dart';
import 'thread_route_payload.dart';
import 'secret_chat_secure_scope.dart';
import 'secret_chat_unlock_sheet.dart';
import '../data/secret_chat_media_open_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const bool _messageListReversed = true;

  int _limit = 100;
  final _controller = ChatHtmlComposerController();
  final _scrollController = ScrollController();
  final _composerFocusNode = FocusNode();

  /// Per-message override origin for the 30s stale-pending window. Set when
  /// the user invokes «Повторить» on a stuck Firestore-pending message.
  final Map<String, DateTime> _pendingRetryAt = <String, DateTime>{};

  /// Ключи строк сообщений — скролл к закреплённому / ответу и якорь подгрузки истории.
  final Map<String, GlobalKey> _messageItemKeys = <String, GlobalKey>{};

  /// Пока не пусто — в списке увеличен [cacheExtent], чтобы смонтировать строку вне экрана (грид и т.д.).
  String? _jumpScrollBoostMessageId;
  bool _loadingOlder = false;
  bool _historyLoadInFlight = false;
  bool _historyExhausted = false;
  int _historyNoGrowthStreak = 0;
  bool _historyRestoreScheduled = false;
  int _historyWaitTicks = 0;
  int _historyCycleId = 0;
  int? _activeHistoryCycleId;
  int _historyBaseCount = 0;
  double? _historyStartPixels;
  double? _historyStartMaxScrollExtent;
  bool _historyStartedNearOldestEdge = false;
  int _lastMessagesCount = 0;
  String? _pendingAnchorMessageId;
  double? _pendingAnchorAlignment;
  List<ChatMessage> _sortedAscCache = const <ChatMessage>[];
  List<ChatMessage> _sortedHydratedAscCache = const <ChatMessage>[];
  DateTime _messageExpiryNow = DateTime.now();
  Timer? _messageExpiryTimer;
  bool _suppressAutoScrollToBottom = false;
  bool _chatAtBottom = true;
  int _anchorUnreadStep = 0;
  final Set<String> _sessionReadIds = <String>{};
  bool _initialOpenPositionResolved = false;

  /// Сессионный id сообщения перед которым рисуется «Непрочитанные»; не следует за
  /// «текущим» oldest-unread при прочитке (паритет web `unreadSeparatorId`).
  String? _sessionUnreadSeparatorAnchorMessageId;
  String _suppressReadConversationResetKey = '';

  /// После подгрузки истории не дергать сразу повторный запрос у верхнего края.
  DateTime? _nearOldestCooldownUntil;
  ReplyContext? _replyingTo;

  /// Режим правки: id сообщения + превью для полосы над вводом (plain).
  String? _editingMessageId;
  String? _editingPreviewPlain;
  final Set<String> _selectedMessageIds = <String>{};
  bool _actionBusy = false;
  final List<XFile> _pendingAttachments = <XFile>[];

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

  /// Счётчик собственных pending-scheduled сообщений в этом чате.
  /// Подписка устанавливается в [didChangeDependencies] и переустанавливается
  /// при смене conversationId.
  int _scheduledPendingCount = 0;
  StreamSubscription<List<ScheduledChatMessage>>? _scheduledCountSub;
  String? _scheduledCountSubKey;

  List<ChatMessage> _filterByClearedAt(
    List<ChatMessage> messages,
    String? clearedAtIso,
  ) {
    final cutoff = DateTime.tryParse(clearedAtIso ?? '')?.toUtc();
    if (cutoff == null) return messages;
    return messages
        .where((m) => m.createdAt.toUtc().isAfter(cutoff))
        .toList(growable: false);
  }

  List<ChatMessage> _filterExpiredMessages(List<ChatMessage> messages) {
    final now = _messageExpiryNow.toUtc();
    return messages
        .where((m) => m.expireAt == null || m.expireAt!.toUtc().isAfter(now))
        .toList(growable: false);
  }

  void _scheduleMessageExpiryRefresh(List<ChatMessage> messages) {
    _messageExpiryTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? next;
    for (final m in messages) {
      final exp = m.expireAt?.toUtc();
      if (exp == null || !exp.isAfter(now)) continue;
      if (next == null || exp.isBefore(next)) next = exp;
    }
    if (next == null) return;
    final delay = next.difference(now) + const Duration(milliseconds: 250);
    _messageExpiryTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _messageExpiryNow = DateTime.now());
    });
  }

  bool _looksLikeVideoAttachment(XFile f) {
    final m = (f.mimeType ?? '').toLowerCase();
    if (m.startsWith('video/')) return true;
    final p = f.path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.webm') ||
        p.endsWith('.m4v') ||
        p.endsWith('.3gp');
  }

  List<PinnedMessage> _cachedSortedPins = const <PinnedMessage>[];

  /// Краткая подсветка строки после перехода к сообщению (ответ / закреп / поиск).
  String? _flashHighlightMessageId;
  Timer? _flashHighlightTimer;

  Timer? _chatDraftDebounce;
  String? _lastChatDraftScheduleKey;
  String? _chatDraftRestoredForConvId;
  bool _callScreenOpening = false;
  String? _handledIncomingCallId;
  List<ChatMessage> _holdPendingE2eeAlbumPreviewUntilHydrated({
    required List<ChatMessage> hydratedMsgs,
    required PendingImageAlbumSend? pendingAlbum,
    required Set<String> e2eeFailedIds,
    required String userId,
  }) {
    final pendingMessageId = pendingAlbum?.e2eeContext?.messageId.trim();
    if (pendingMessageId == null || pendingMessageId.isEmpty) {
      return hydratedMsgs;
    }

    ChatMessage? pendingMessage;
    for (final m in hydratedMsgs) {
      if (m.id == pendingMessageId) {
        pendingMessage = m;
        break;
      }
    }

    final ready = (pendingMessage?.attachments.isNotEmpty ?? false);
    final decryptFailed = e2eeFailedIds.contains(pendingMessageId);
    if (ready || decryptFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentPending = ref.read(
          pendingImageAlbumNotifierProvider,
        )[widget.conversationId];
        if (currentPending?.e2eeContext?.messageId == pendingMessageId) {
          ref
              .read(pendingImageAlbumNotifierProvider.notifier)
              .setFor(widget.conversationId, null);
          unawaited(clearChatMessageDraft(userId, widget.conversationId));
        }
      });
      return hydratedMsgs;
    }

    return hydratedMsgs
        .where((m) => m.id != pendingMessageId)
        .toList(growable: false);
  }

  double _chatBottomOffset(ScrollController c) {
    if (!c.hasClients) return 0;
    return _messageListReversed
        ? c.position.minScrollExtent
        : c.position.maxScrollExtent;
  }

  void _jumpToChatBottom() {
    final sc = _scrollController;
    if (!sc.hasClients) return;
    sc.jumpTo(_chatBottomOffset(sc));
  }

  Future<void> _animateToChatBottom() async {
    final sc = _scrollController;
    if (!sc.hasClients) return;
    await sc.animateTo(
      _chatBottomOffset(sc),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _scheduleAutoScrollToBottomIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_suppressAutoScrollToBottom) return;
      if (!_chatAtBottom) return;
      unawaited(_animateToChatBottom());
    });
  }

  void _preserveViewportOnIncomingGrowth({
    required int previousCount,
    required int nextCount,
  }) {
    if (previousCount <= 0 || nextCount <= previousCount) return;
    if (_chatAtBottom) return;
    if (_historyLoadInFlight || _loadingOlder) return;
    final sc = _scrollController;
    if (!sc.hasClients) return;
    final beforeMax = sc.position.maxScrollExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_chatAtBottom) return;
      if (_historyLoadInFlight || _loadingOlder) return;
      if (!sc.hasClients) return;
      final pos = sc.position;
      final delta = pos.maxScrollExtent - beforeMax;
      if (delta <= 0.5) return;
      final target = (pos.pixels + delta).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      if ((target - pos.pixels).abs() <= 0.5) return;
      pos.jumpTo(target);
    });
  }

  void _maybeResolveInitialOpenPosition({
    required String? unreadSeparatorMessageId,
  }) {
    if (_initialOpenPositionResolved) return;
    _initialOpenPositionResolved = true;
    final targetId = unreadSeparatorMessageId?.trim();
    if (targetId == null || targetId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToMessageId(targetId);
      if (!mounted || _anchorUnreadStep != 0) return;
      setState(() => _anchorUnreadStep = 1);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onPinnedBarScrollSync);
    _controller.addListener(_scheduleChatDraftSave);
  }

  void _scheduleChatDraftSave() {
    _chatDraftDebounce?.cancel();
    _chatDraftDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      unawaited(_persistChatDraftNow(uid));
    });
  }

  Future<void> _persistChatDraftNow(String uid) async {
    final scope = widget.conversationId;
    final html = _controller.text;
    final plain = chatDraftPlainFromHtml(html);
    final hasReply = _replyingTo != null;
    final hasPending = _pendingAttachments.isNotEmpty;
    if (plain.isEmpty && !hasReply && !hasPending) {
      await clearChatMessageDraft(uid, scope);
      return;
    }
    await saveChatMessageDraft(
      uid,
      scope,
      StoredChatMessageDraft(
        html: html,
        replyTo: _replyingTo,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _persistChatDraftSnapshotForConv(
    String uid,
    String conversationId,
  ) async {
    final html = _controller.text;
    final plain = chatDraftPlainFromHtml(html);
    final hasReply = _replyingTo != null;
    final hasPending = _pendingAttachments.isNotEmpty;
    if (plain.isEmpty && !hasReply && !hasPending) {
      await clearChatMessageDraft(uid, conversationId);
      return;
    }
    await saveChatMessageDraft(
      uid,
      conversationId,
      StoredChatMessageDraft(
        html: html,
        replyTo: _replyingTo,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _scheduleChatDraftRestoreIfNeeded(String uid) {
    final key = '$uid|${widget.conversationId}';
    if (_lastChatDraftScheduleKey == key) return;
    _lastChatDraftScheduleKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_applyChatDraftFromStorage(uid));
    });
  }

  Future<void> _applyChatDraftFromStorage(String uid) async {
    final conv = widget.conversationId;
    final d = await getChatMessageDraft(uid, conv);
    if (!mounted || widget.conversationId != conv) return;
    if (_chatDraftRestoredForConvId == conv) return;
    _chatDraftRestoredForConvId = conv;
    if (d == null) return;
    final plain = chatDraftPlainFromHtml(d.html);
    final hasReply = d.replyTo != null;
    if (plain.isEmpty && !hasReply) return;
    _controller.text = d.html;
    setState(() => _replyingTo = d.replyTo);
  }

  Future<void> _openCallScreen({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserAvatarUrl,
    required String peerUserId,
    required String peerUserName,
    required String? peerAvatarUrl,
    required bool isVideo,
    String? existingCallId,
  }) async {
    if (_callScreenOpening) return;
    _callScreenOpening = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => isVideo
              ? ChatVideoCallScreen(
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  currentUserAvatarUrl: currentUserAvatarUrl,
                  peerUserId: peerUserId,
                  peerUserName: peerUserName,
                  peerAvatarUrl: peerAvatarUrl,
                  existingCallId: existingCallId,
                )
              : ChatAudioCallScreen(
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  currentUserAvatarUrl: currentUserAvatarUrl,
                  peerUserId: peerUserId,
                  peerUserName: peerUserName,
                  peerAvatarUrl: peerAvatarUrl,
                  existingCallId: existingCallId,
                ),
        ),
      );
    } finally {
      _callScreenOpening = false;
    }
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
      ref
          .read(pendingImageAlbumNotifierProvider.notifier)
          .setFor(oldWidget.conversationId, null);
    }
    if (oldWidget.conversationId != widget.conversationId) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(
          _persistChatDraftSnapshotForConv(uid, oldWidget.conversationId),
        );
      }
      _chatDraftDebounce?.cancel();
      _controller.clear();
      _pendingAttachments.clear();
      _lastChatDraftScheduleKey = null;
      _chatDraftRestoredForConvId = null;
      _limit = 100;
      _replyingTo = null;
      _editingMessageId = null;
      _editingPreviewPlain = null;
      _selectedMessageIds.clear();
      _loadingOlder = false;
      _historyLoadInFlight = false;
      _historyExhausted = false;
      _historyNoGrowthStreak = 0;
      _historyRestoreScheduled = false;
      _historyWaitTicks = 0;
      _historyCycleId = 0;
      _activeHistoryCycleId = null;
      _historyBaseCount = 0;
      _historyStartPixels = null;
      _historyStartMaxScrollExtent = null;
      _historyStartedNearOldestEdge = false;
      _lastMessagesCount = 0;
      _messageExpiryNow = DateTime.now();
      _messageExpiryTimer?.cancel();
      _pendingAnchorMessageId = null;
      _pendingAnchorAlignment = null;
      _sortedAscCache = const <ChatMessage>[];
      _sortedHydratedAscCache = const <ChatMessage>[];
      _suppressAutoScrollToBottom = false;
      _chatAtBottom = true;
      _anchorUnreadStep = 0;
      _initialOpenPositionResolved = false;
      _sessionUnreadSeparatorAnchorMessageId = null;
      _sessionReadIds.clear();
      _suppressReadConversationResetKey = '';
      _nearOldestCooldownUntil = null;
      _messageItemKeys.clear();
      _jumpScrollBoostMessageId = null;
      ref
          .read(pendingImageAlbumNotifierProvider.notifier)
          .setFor(widget.conversationId, null);
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

  bool _isIncomingUnreadForViewer(ChatMessage m, String viewerId) {
    // System timeline markers (E2EE state changes etc.) are informational and
    // must not appear as unread messages.
    if (m.senderId == '__system__' || m.systemEvent != null) return false;
    if (m.senderId == viewerId) return false;
    return m.readAt == null;
  }

  int _loadedIncomingUnreadCount(List<ChatMessage> sortedAsc, String viewerId) {
    var count = 0;
    for (final m in sortedAsc) {
      if (_isIncomingUnreadForViewer(m, viewerId)) {
        count += 1;
      }
    }
    return count;
  }

  String? _oldestIncomingUnreadId(
    List<ChatMessage> sortedAsc,
    String viewerId,
  ) {
    for (final m in sortedAsc) {
      if (_isIncomingUnreadForViewer(m, viewerId)) {
        return m.id;
      }
    }
    return null;
  }

  List<String> _incomingUnreadIds(
    List<ChatMessage> sortedAsc,
    String viewerId,
  ) {
    final out = <String>[];
    for (final m in sortedAsc) {
      if (_isIncomingUnreadForViewer(m, viewerId)) {
        out.add(m.id);
      }
    }
    return out;
  }

  void _syncSessionUnreadSeparatorAnchor({
    required List<ChatMessage> sortedAsc,
    required String viewerId,
  }) {
    if (_loadedIncomingUnreadCount(sortedAsc, viewerId) == 0) {
      _sessionUnreadSeparatorAnchorMessageId = null;
      return;
    }
    _sessionUnreadSeparatorAnchorMessageId ??= _oldestIncomingUnreadId(
      sortedAsc,
      viewerId,
    );
  }

  Future<void> _markVisibleMessageAsRead(
    ChatMessage message,
    String userId,
    bool allowReadReceipts,
  ) async {
    if (!allowReadReceipts) return;
    if (!_isIncomingUnreadForViewer(message, userId)) return;
    final id = message.id.trim();
    if (id.isEmpty) return;
    if (id.startsWith(kLocalOutboxMessageIdPrefix)) return;
    if (_sessionReadIds.contains(id)) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    _sessionReadIds.add(id);
    try {
      await repo.markMessagesAsRead(
        conversationId: widget.conversationId,
        userId: userId,
        messageIds: <String>[id],
      );
    } catch (_) {
      _sessionReadIds.remove(id);
    }
  }

  Future<void> _markManyUnreadAsReadAndConversation({
    required String userId,
    required List<String> unreadIds,
    required bool allowReadReceipts,
    bool forceConversationReset = false,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    if (!allowReadReceipts) {
      try {
        await repo.markConversationAsRead(
          conversationId: widget.conversationId,
          userId: userId,
        );
      } catch (_) {}
      return;
    }
    final toMark = unreadIds
        .where((id) => !_sessionReadIds.contains(id))
        .toList(growable: false);
    if (toMark.isNotEmpty) {
      _sessionReadIds.addAll(toMark);
      try {
        await repo.markManyMessagesAsRead(
          conversationId: widget.conversationId,
          userId: userId,
          messageIds: toMark,
        );
      } catch (_) {
        _sessionReadIds.removeAll(toMark);
      }
    }
    if (!forceConversationReset && toMark.isEmpty) return;
    try {
      await repo.markConversationAsRead(
        conversationId: widget.conversationId,
        userId: userId,
      );
    } catch (_) {}
  }

  _AnchorReactionTarget? _latestAnchorReaction({
    required Conversation? conversation,
    required String currentUserId,
  }) {
    if (conversation == null) return null;
    final ts = (conversation.lastReactionTimestamp ?? '').trim();
    final emoji = (conversation.lastReactionEmoji ?? '').trim();
    final messageId = (conversation.lastReactionMessageId ?? '').trim();
    if (ts.isEmpty || emoji.isEmpty || messageId.isEmpty) return null;
    if ((conversation.lastReactionSenderId ?? '').trim() == currentUserId) {
      return null;
    }
    final seenAt = (conversation.lastReactionSeenAt?[currentUserId] ?? '')
        .trim();
    if (seenAt.isNotEmpty && ts.compareTo(seenAt) <= 0) return null;
    final parentId = (conversation.lastReactionParentId ?? '').trim();
    return _AnchorReactionTarget(
      emoji: emoji,
      messageId: messageId,
      parentId: parentId.isEmpty ? null : parentId,
    );
  }

  Future<void> _handleReactionAnchorTap({
    required _AnchorReactionTarget reaction,
    required String userId,
  }) async {
    if (reaction.parentId == null) {
      _scrollToMessageId(reaction.messageId);
    } else {
      ChatMessage? parentMessage;
      for (final m in _sortedAscCache) {
        if (m.id == reaction.parentId) {
          parentMessage = m;
          break;
        }
      }
      unawaited(
        context.push(
          '/chats/${widget.conversationId}/thread/${reaction.parentId}',
          extra: ThreadRoutePayload(
            parentMessage: parentMessage,
            focusMessageId: reaction.messageId,
          ),
        ),
      );
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    try {
      await repo.markReactionSeen(
        conversationId: widget.conversationId,
        userId: userId,
      );
    } catch (_) {}
  }

  void _onChatAtBottomChanged(bool atBottom) {
    if (!mounted) return;
    if (_chatAtBottom == atBottom) return;
    setState(() {
      _chatAtBottom = atBottom;
      if (atBottom) {
        _anchorUnreadStep = 0;
      }
    });
  }

  void _scrollToMessageId(String messageId) {
    if (messageId.isEmpty) return;
    final idx = _sortedAscCache.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      _toast(
        AppLocalizations.of(context)!.chat_message_not_found_in_loaded_history,
      );
      return;
    }

    final sc = _scrollController;
    final n = _sortedAscCache.length;
    if (sc.hasClients && n > 1) {
      final max = sc.position.maxScrollExtent;
      if (max > 0) {
        final frac = idx / (n - 1);
        final raw = _messageListReversed ? (max * (1 - frac)) : (max * frac);
        sc.jumpTo(raw.clamp(0.0, max));
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
        _toast(
          AppLocalizations.of(
            context,
          )!.chat_message_not_found_in_loaded_history,
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  @override
  void dispose() {
    _chatDraftDebounce?.cancel();
    _messageExpiryTimer?.cancel();
    _scheduledCountSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(_persistChatDraftSnapshotForConv(uid, widget.conversationId));
    }
    _flashHighlightTimer?.cancel();
    _scrollController.removeListener(_onPinnedBarScrollSync);
    _controller.removeListener(_scheduleChatDraftSave);
    _composerFocusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _chatSearchController.dispose();
    _chatSearchFocus.dispose();
    super.dispose();
  }

  /// Подписка на счётчик запланированных сообщений.
  /// Вызывается из build() с актуальным uid, чтобы переустанавливать подписку
  /// при смене conversationId или авторизации.
  void _ensureScheduledCountSub(String uid) {
    final key = '$uid|${widget.conversationId}';
    if (_scheduledCountSubKey == key) return;
    _scheduledCountSub?.cancel();
    _scheduledCountSubKey = key;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _scheduledPendingCount = 0;
      return;
    }
    _scheduledCountSub = repo
        .watchScheduledMessages(
          conversationId: widget.conversationId,
          userId: uid,
        )
        .listen((items) {
      if (!mounted) return;
      final next = items.length;
      if (next != _scheduledPendingCount) {
        setState(() => _scheduledPendingCount = next);
      }
    });
  }

  void _openScheduledMessagesScreen(
    String uid, {
    required bool e2eeActive,
  }) {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduledMessagesScreen(
          repository: repo,
          conversationId: widget.conversationId,
          currentUserId: uid,
          e2eeEnabled: e2eeActive,
        ),
      ),
    );
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
    final startFlat = ((p.pixels / contentLen) * flatCount).floor().clamp(
      0,
      flatCount - 1,
    );
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
    final l10n = AppLocalizations.of(context)!;

    final conversationId = widget.conversationId;

    if (!firebaseReady) {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text(l10n.chat_list_firebase_not_configured),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user != null) {
          _ensureScheduledCountSub(user.uid);
        }
        if (user == null) {
          return Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Text(l10n.forward_error_not_authorized),
            ),
          );
        }

        final userDocAsync = ref.watch(userChatSettingsDocProvider(user.uid));
        final starredIdsAsync = ref.watch(
          starredMessageIdsInConversationProvider((
            userId: user.uid,
            conversationId: widget.conversationId,
          )),
        );
        final userDoc = userDocAsync.asData?.value ?? const <String, dynamic>{};
        final rawChatSettings = Map<String, dynamic>.from(
          userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
        );
        final rawPrivacySettings = Map<String, dynamic>.from(
          userDoc['privacySettings'] as Map? ?? const <String, dynamic>{},
        );
        final allowReadReceipts =
            rawPrivacySettings['showReadReceipts'] != false;
        final fontSize = (rawChatSettings['fontSize'] as String?) ?? 'medium';
        final bubbleRadius =
            (rawChatSettings['bubbleRadius'] as String?) ?? 'rounded';
        final showTimestamps =
            (rawChatSettings['showTimestamps'] as bool?) ?? true;
        final emojiBurstAnimationProfile =
            normalizeChatEmojiBurstAnimationProfile(
              rawChatSettings['emojiBurstAnimationProfile'] as String?,
            );
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
        final contactsAsync = ref.watch(userContactsIndexProvider(user.uid));

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
            final isSecret = conv?.data.secretChat?.enabled == true;
            final secretLockRequired =
                conv?.data.secretChat?.lockPolicy.required == true;
            final secretUnlocked = (isSecret && secretLockRequired)
                ? (ref
                          .watch(
                            secretChatAccessActiveProvider((
                              conversationId: widget.conversationId,
                              userId: user.uid,
                            )),
                          )
                          .asData
                          ?.value ==
                      true)
                : true;
            final isSaved =
                conv != null &&
                isSavedMessagesConversation(conv.data, user.uid);

            if (isSecret && secretLockRequired && !secretUnlocked) {
              return SecretChatSecureScope(
                enabled: true,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      AppLocalizations.of(context)!.secret_chat_title,
                    ),
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.secret_chat_locked_title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.secret_chat_locked_subtitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: () async {
                              final res =
                                  await showModalBottomSheet<
                                    SecretChatUnlockResult
                                  >(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => SecretChatUnlockSheet(
                                      conversationId: widget.conversationId,
                                    ),
                                  );
                              if (!mounted) return;
                              if (res?.unlocked == true) {
                                setState(() {});
                              }
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.secret_chat_unlock_action,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              context.push(
                                '/chats/${widget.conversationId}/secret-settings',
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.secret_chat_settings_title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // IMPORTANT: In Secret Chats, Firestore rules deny reading `messages/*`
            // without an active `secretAccess` grant. Do not even subscribe to the
            // messages stream until the chat is unlocked, otherwise the UI gets a
            // permission-denied error even though we render the lock screen.
            final msgsAsync = ref.watch(
              messagesProvider((conversationId: conversationId, limit: _limit)),
            );
            final myBlockedAsync = ref.watch(
              userBlockedUserIdsProvider(user.uid),
            );
            final partnerBlockedAsync =
                (dmOtherId != null && dmOtherId.isNotEmpty)
                ? ref.watch(userBlockedUserIdsProvider(dmOtherId))
                : null;
            final dmCallsBlocked =
                conv?.data.isGroup != true &&
                dmOtherId != null &&
                dmOtherId.isNotEmpty &&
                isEitherBlockingFromUserIds(
                  viewerId: user.uid,
                  viewerBlockedIds: myBlockedAsync.value ?? const <String>[],
                  partnerId: dmOtherId,
                  partnerBlockedIds:
                      partnerBlockedAsync?.value ?? const <String>[],
                  partnerUserDocDenied: partnerBlockedAsync?.hasError == true,
                );
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
                _scheduleChatDraftRestoreIfNeeded(user.uid);
                final profileMap = snap.data;
                final selfProfile = profileMap == null
                    ? null
                    : profileMap[user.uid];
                final profile = dmOtherId != null && profileMap != null
                    ? profileMap[dmOtherId]
                    : null;
                final contactProfiles =
                    contactsAsync.value?.contactProfiles ??
                    const <String, ContactLocalProfile>{};
                final partInfo = conv?.data.participantInfo;
                final dmFallbackName = dmOtherId != null && partInfo != null
                    ? partInfo[dmOtherId]?.name
                    : null;
                final resolvedDmName = resolveContactDisplayName(
                  contactProfiles: contactProfiles,
                  contactUserId: dmOtherId,
                  fallbackName:
                      ((profile?.name ?? dmFallbackName) ??
                              AppLocalizations.of(
                                context,
                              )!.partner_profile_title_fallback_chat)
                          .trim(),
                );
                final title = conv == null
                    ? resolvedDmName
                    : conv.data.isGroup
                    ? (conv.data.name ??
                          AppLocalizations.of(
                            context,
                          )!.partner_profile_title_fallback_group)
                    : isSaved
                    ? (conv.data.name ??
                          AppLocalizations.of(
                            context,
                          )!.partner_profile_title_fallback_saved)
                    : resolvedDmName;
                final profileForSheet = profile == null
                    ? null
                    : UserProfile(
                        id: profile.id,
                        name: resolvedDmName,
                        username: profile.username,
                        avatar: profile.avatar,
                        avatarThumb: profile.avatarThumb,
                        email: profile.email,
                        phone: profile.phone,
                        bio: profile.bio,
                        role: profile.role,
                        online: profile.online,
                        lastSeenAt: profile.lastSeenAt,
                        dateOfBirth: profile.dateOfBirth,
                        deletedAt: profile.deletedAt,
                        privacySettings: profile.privacySettings,
                        blockedUserIds: profile.blockedUserIds,
                      );
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
                    ? AppLocalizations.of(
                        context,
                      )!.partner_profile_subtitle_group_member_count(
                        conv?.data.participantIds.length ?? 0,
                      )
                    : isSaved
                    ? AppLocalizations.of(
                        context,
                      )!.partner_profile_subtitle_saved_messages
                    : partnerPresenceLine(profile, AppLocalizations.of(context)!);
                final showCalls =
                    conv?.data.isGroup != true &&
                    dmOtherId != null &&
                    dmOtherId.isNotEmpty &&
                    !dmCallsBlocked;
                final threadsUnread =
                    conv?.data.unreadThreadCounts?[user.uid] ?? 0;
                final prefsStream = ref
                    .read(chatSettingsRepositoryProvider)
                    ?.watchChatConversationPrefs(
                      userId: user.uid,
                      conversationId: conversationId,
                    );

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
                  Navigator.of(context).push<void>(
                    CupertinoPageRoute(
                      builder: (_) => ChatPartnerProfileSheet(
                        conversationId: conversationId,
                        conversation: conv.data,
                        currentUserId: user.uid,
                        selfProfile: selfProfile,
                        partnerProfile: profileForSheet,
                        onJumpToMessageId: _scrollToMessageId,
                        fullScreen: true,
                      ),
                    ),
                  );
                }

                Widget chatShell(
                  List<ChatMessage> msgs, {
                  required bool showSpinner,
                  required String? effectiveWallpaper,
                }) {
                  final pendingAlbum = ref.watch(
                    pendingImageAlbumNotifierProvider.select(
                      (m) => m[widget.conversationId],
                    ),
                  );
                  final outboxJobs = ref.watch(
                    chatOutboxAttachmentNotifierProvider,
                  );
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
                  final topPin = pinCount == 0
                      ? null
                      : sortedPins[displayPinIdx];
                  final topInset = MediaQuery.paddingOf(context).top;
                  final headerBar = _selectedMessageIds.isEmpty ? 56.0 : 56.0;
                  final belowHeaderGap = topInset + headerBar;
                  final sortedAscForAnchor = List<ChatMessage>.from(msgs)
                    ..sort((a, b) {
                      final t = a.createdAt.compareTo(b.createdAt);
                      if (t != 0) return t;
                      return a.id.compareTo(b.id);
                    });
                  final loadedIncomingUnreadCount = _loadedIncomingUnreadCount(
                    sortedAscForAnchor,
                    user.uid,
                  );
                  final loadedIncomingUnreadIds = _incomingUnreadIds(
                    sortedAscForAnchor,
                    user.uid,
                  );
                  if (!allowReadReceipts) {
                    final suppressKey =
                        '${widget.conversationId}:$loadedIncomingUnreadCount';
                    if (loadedIncomingUnreadCount > 0 &&
                        _suppressReadConversationResetKey != suppressKey) {
                      _suppressReadConversationResetKey = suppressKey;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        unawaited(
                          _markManyUnreadAsReadAndConversation(
                            userId: user.uid,
                            unreadIds: loadedIncomingUnreadIds,
                            allowReadReceipts: false,
                            forceConversationReset: true,
                          ),
                        );
                      });
                    } else if (loadedIncomingUnreadCount == 0 &&
                        _suppressReadConversationResetKey.isNotEmpty) {
                      _suppressReadConversationResetKey = '';
                    }
                  } else if (_suppressReadConversationResetKey.isNotEmpty) {
                    _suppressReadConversationResetKey = '';
                  }
                  _syncSessionUnreadSeparatorAnchor(
                    sortedAsc: sortedAscForAnchor,
                    viewerId: user.uid,
                  );
                  final unreadSeparatorMessageId =
                      _sessionUnreadSeparatorAnchorMessageId;
                  _maybeResolveInitialOpenPosition(
                    unreadSeparatorMessageId: unreadSeparatorMessageId,
                  );
                  final serverUnreadCount =
                      conv?.data.unreadCounts?[user.uid] ?? 0;
                  final anchorUnreadBadgeCount = loadedIncomingUnreadCount > 0
                      ? loadedIncomingUnreadCount
                      : serverUnreadCount;
                  final latestReaction = _latestAnchorReaction(
                    conversation: conv?.data,
                    currentUserId: user.uid,
                  );
                  final anchorSuppressed =
                      _inChatSearch ||
                      _selectedMessageIds.isNotEmpty ||
                      showSpinner;
                  final showScrollAnchor =
                      !anchorSuppressed &&
                      (latestReaction != null ||
                          !_chatAtBottom ||
                          anchorUnreadBadgeCount > 0);
                  if (loadedIncomingUnreadCount == 0 &&
                      _anchorUnreadStep != 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _anchorUnreadStep == 0) return;
                      setState(() => _anchorUnreadStep = 0);
                    });
                  }

                  void onScrollAnchorTap() {
                    if (latestReaction != null) {
                      unawaited(
                        _handleReactionAnchorTap(
                          reaction: latestReaction,
                          userId: user.uid,
                        ),
                      );
                      return;
                    }
                    final canJumpToUnread =
                        anchorUnreadBadgeCount > 0 &&
                        _anchorUnreadStep == 0 &&
                        unreadSeparatorMessageId != null;
                    if (canJumpToUnread) {
                      _scrollToMessageId(unreadSeparatorMessageId);
                      setState(() => _anchorUnreadStep = 1);
                      return;
                    }
                    if (_anchorUnreadStep != 0) {
                      setState(() => _anchorUnreadStep = 0);
                    }
                    unawaited(_animateToChatBottom());
                    if (anchorUnreadBadgeCount > 0) {
                      unawaited(
                        _markManyUnreadAsReadAndConversation(
                          userId: user.uid,
                          unreadIds: loadedIncomingUnreadIds,
                          allowReadReceipts: allowReadReceipts,
                          forceConversationReset: true,
                        ),
                      );
                    }
                  }

                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: _selectedMessageIds.isEmpty
                        ? PreferredSize(
                            preferredSize: const Size.fromHeight(56),
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
                                onVideoCallTap: () async {
                                  if (dmOtherId == null ||
                                      dmOtherId.isEmpty ||
                                      _callScreenOpening) {
                                    return;
                                  }
                                  final peerName =
                                      (resolvedDmName.trim().isNotEmpty
                                                  ? resolvedDmName
                                                  : title)
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? resolvedDmName
                                      : AppLocalizations.of(
                                          context,
                                        )!.partner_profile_call_peer_fallback;
                                  final peerAvatar =
                                      profile?.avatarThumb ??
                                      profile?.avatar ??
                                      dmFallbackAvatarThumb ??
                                      dmFallbackAvatar;
                                  final meName =
                                      (selfProfile?.name ?? user.uid)
                                          .trim()
                                          .isNotEmpty
                                      ? (selfProfile?.name ?? user.uid)
                                      : user.uid;
                                  final meAvatar =
                                      selfProfile?.avatarThumb ??
                                      selfProfile?.avatar;
                                  await _openCallScreen(
                                    currentUserId: user.uid,
                                    currentUserName: meName,
                                    currentUserAvatarUrl: meAvatar,
                                    peerUserId: dmOtherId,
                                    peerUserName: peerName,
                                    peerAvatarUrl: peerAvatar,
                                    isVideo: true,
                                  );
                                },
                                onAudioCallTap: () async {
                                  if (dmOtherId == null ||
                                      dmOtherId.isEmpty ||
                                      _callScreenOpening) {
                                    return;
                                  }
                                  final peerName =
                                      (resolvedDmName.trim().isNotEmpty
                                                  ? resolvedDmName
                                                  : title)
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? resolvedDmName
                                      : AppLocalizations.of(
                                          context,
                                        )!.partner_profile_call_peer_fallback;
                                  final peerAvatar =
                                      profile?.avatarThumb ??
                                      profile?.avatar ??
                                      dmFallbackAvatarThumb ??
                                      dmFallbackAvatar;
                                  final meName =
                                      (selfProfile?.name ?? user.uid)
                                          .trim()
                                          .isNotEmpty
                                      ? (selfProfile?.name ?? user.uid)
                                      : user.uid;
                                  final meAvatar =
                                      selfProfile?.avatarThumb ??
                                      selfProfile?.avatar;
                                  await _openCallScreen(
                                    currentUserId: user.uid,
                                    currentUserName: meName,
                                    currentUserAvatarUrl: meAvatar,
                                    peerUserId: dmOtherId,
                                    peerUserName: peerName,
                                    peerAvatarUrl: peerAvatar,
                                    isVideo: false,
                                  );
                                },
                                onProfileTap: openProfile,
                                searchActive: _inChatSearch,
                                searchController: _chatSearchController,
                                searchFocusNode: _chatSearchFocus,
                                onSearchClose: _exitChatSearch,
                                scheduledCount: _scheduledPendingCount,
                                onScheduledTap: _scheduledPendingCount > 0
                                    ? () => _openScheduledMessagesScreen(
                                        user.uid,
                                        e2eeActive: isConversationE2eeActive(
                                          conv?.data,
                                        ),
                                      )
                                    : null,
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
                      wallpaper: effectiveWallpaper,
                      child: Stack(
                        children: [
                          SafeArea(
                            top: false,
                            child: Column(
                              children: [
                                SizedBox(height: belowHeaderGap),
                                if (conv != null)
                                  DmGameLobbyBanner(
                                    conversationId: conversationId,
                                    isGroup: conv.data.isGroup,
                                  ),
                                if (topPin != null && conv != null)
                                  ChatPinnedStrip(
                                    pin: topPin,
                                    totalPins: sortedPins.length,
                                    onUnpin: () =>
                                        _unpinMessage(topPin, conv.data),
                                    onOpenPinned: () {
                                      final n = sortedPins.length;
                                      if (n == 0) return;
                                      final i = displayPinIdx;
                                      final target = sortedPins[i];
                                      _scrollToMessageId(target.messageId);
                                      setState(() {
                                        _pinnedBarSkipSyncUntilMs =
                                            DateTime.now()
                                                .millisecondsSinceEpoch +
                                            900;
                                        _barPinIndex = (i - 1 + n) % n;
                                      });
                                    },
                                  ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    child: showSpinner
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Stack(
                                            children: [
                                              Positioned.fill(
                                                child: E2eeMessagesResolver(
                                                  conversationId:
                                                      conversationId,
                                                  secretChat:
                                                      conv?.data.secretChat,
                                                  messages: msgs,
                                                  builder:
                                                      (
                                                        context,
                                                        hydratedMsgs,
                                                        e2eeDecryptedMap,
                                                        e2eeFailedIds,
                                                      ) {
                                                        final visualMsgs =
                                                            _holdPendingE2eeAlbumPreviewUntilHydrated(
                                                              hydratedMsgs:
                                                                  hydratedMsgs,
                                                              pendingAlbum:
                                                                  pendingAlbum,
                                                              e2eeFailedIds:
                                                                  e2eeFailedIds,
                                                              userId: user.uid,
                                                            );
                                                        _sortedHydratedAscCache =
                                                            List<
                                                                ChatMessage
                                                              >.from(
                                                                hydratedMsgs,
                                                              )
                                                              ..sort((a, b) {
                                                                final t = a
                                                                    .createdAt
                                                                    .compareTo(
                                                                      b.createdAt,
                                                                    );
                                                                if (t != 0) {
                                                                  return t;
                                                                }
                                                                return a.id
                                                                    .compareTo(
                                                                      b.id,
                                                                    );
                                                              });
                                                        return ChatMessageList(
                                                          messagesDesc:
                                                              buildDescWithOutboxMessages(
                                                                hydratedDesc:
                                                                    visualMsgs,
                                                                jobs:
                                                                    outboxJobs,
                                                                conversationId:
                                                                    conversationId,
                                                                senderId:
                                                                    user.uid,
                                                              ),
                                                          currentUserId:
                                                              user.uid,
                                                          conversationId:
                                                              conversationId,
                                                          e2eeDecryptedTextByMessageId:
                                                              e2eeDecryptedMap,
                                                          e2eeDecryptionFailedMessageIds:
                                                              e2eeFailedIds,
                                                          reversed:
                                                              _messageListReversed,
                                                          conversation:
                                                              conv?.data,
                                                          scrollController:
                                                              _scrollController,
                                                          onNearOldestEdge:
                                                              _historyExhausted
                                                              ? null
                                                              : _onScrollLoadOlder,
                                                          unreadSeparatorMessageId:
                                                              unreadSeparatorMessageId,
                                                          onAtBottomChanged:
                                                              _onChatAtBottomChanged,
                                                          onMessageVisible:
                                                              (message, _) {
                                                                unawaited(
                                                                  _markVisibleMessageAsRead(
                                                                    message,
                                                                    user.uid,
                                                                    allowReadReceipts,
                                                                  ),
                                                                );
                                                              },
                                                          messageItemKeys:
                                                              _messageItemKeys,
                                                          jumpScrollBoostMessageId:
                                                              _jumpScrollBoostMessageId,
                                                          onJumpToMessageId:
                                                              _scrollToMessageId,
                                                          flashHighlightMessageId:
                                                              _flashHighlightMessageId,
                                                          selectionMode:
                                                              _selectedMessageIds
                                                                  .isNotEmpty,
                                                          selectedMessageIds:
                                                              _selectedMessageIds,
                                                          onMessageTap:
                                                              _toggleMessageSelected,
                                                          onRetryMediaNorm:
                                                              _retryMediaNormForMainChat,
                                                          onEmitEmojiBurstEvent:
                                                              _emitEmojiBurstEvent,
                                                          onSwipeReply: (m) {
                                                            if (_editingMessageId !=
                                                                null) {
                                                              _toast(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.chat_finish_editing_first,
                                                              );
                                                              return;
                                                            }
                                                            if (_selectedMessageIds
                                                                .isNotEmpty) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _editingMessageId =
                                                                  null;
                                                              _editingPreviewPlain =
                                                                  null;
                                                              _replyingTo = buildReplyPreview(
                                                      l10n: AppLocalizations.of(context)!,
                                                      message: m,
                                                                currentUserId:
                                                                    user.uid,
                                                                isGroup:
                                                                    conv
                                                                        ?.data
                                                                        .isGroup ??
                                                                    false,
                                                                otherUserId:
                                                                    dmOtherId,
                                                                otherUserName:
                                                                    profile
                                                                        ?.name,
                                                              );
                                                            });
                                                            _scheduleChatDraftSave();
                                                            _composerFocusNode
                                                                .requestFocus();
                                                          },
                                                          onSwipeBack: () {
                                                            if (context
                                                                .canPop()) {
                                                              context.pop();
                                                            }
                                                          },
                                                          onOutboxRetry: (mid) {
                                                            handleOutboxRetry(
                                                              ref,
                                                              mid,
                                                            );
                                                          },
                                                          onOutboxDismiss: (mid) {
                                                            unawaited(
                                                              handleOutboxDismiss(
                                                                ref,
                                                                mid,
                                                              ),
                                                            );
                                                          },
                                                          pendingRetryAt:
                                                              _pendingRetryAt,
                                                          fontSize: fontSize,
                                                          bubbleRadius:
                                                              bubbleRadius,
                                                          showTimestamps:
                                                              showTimestamps,
                                                          emojiBurstAnimationProfile:
                                                              emojiBurstAnimationProfile,
                                                          outgoingBubbleColor:
                                                              bubbleColor,
                                                          incomingBubbleColor:
                                                              incomingBubbleColor,
                                                          outgoingMediaFooter:
                                                              pendingAlbum ==
                                                                      null ||
                                                                  repo == null
                                                              ? null
                                                              : Builder(
                                                                  builder: (_) {
                                                                    final album =
                                                                        pendingAlbum;
                                                                    return Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child: OutgoingPendingMediaAlbum(
                                                                        key: ValueKey(
                                                                          Object.hash(
                                                                            album.files.length,
                                                                            album.text,
                                                                            album.replyTo?.messageId,
                                                                          ),
                                                                        ),
                                                                        files: album
                                                                            .files,
                                                                        captionText:
                                                                            album.text,
                                                                        replyTo:
                                                                            album.replyTo,
                                                                        conversationId:
                                                                            widget.conversationId,
                                                                        senderId:
                                                                            user.uid,
                                                                        repo:
                                                                            repo,
                                                                        isMine:
                                                                            true,
                                                                        outgoingBubbleColor:
                                                                            bubbleColor,
                                                                        e2eeContext:
                                                                            album.e2eeContext,
                                                                        onFinished: () {
                                                                          if (mounted) {
                                                                            setState(
                                                                              () => _sendBusy = false,
                                                                            );
                                                                            final pendingMessageId =
                                                                                album.e2eeContext?.messageId.trim();
                                                                            final shouldKeepPreview =
                                                                                pendingMessageId !=
                                                                                    null &&
                                                                                pendingMessageId.isNotEmpty;
                                                                            if (!shouldKeepPreview) {
                                                                              ref
                                                                                  .read(
                                                                                    pendingImageAlbumNotifierProvider.notifier,
                                                                                  )
                                                                                  .setFor(
                                                                                    widget.conversationId,
                                                                                    null,
                                                                                  );
                                                                              unawaited(
                                                                                clearChatMessageDraft(
                                                                                  user.uid,
                                                                                  widget.conversationId,
                                                                                ),
                                                                              );
                                                                            }
                                                                            WidgetsBinding.instance.addPostFrameCallback((
                                                                              _,
                                                                            ) {
                                                                              _scheduleAutoScrollToBottomIfNeeded();
                                                                            });
                                                                          }
                                                                        },
                                                                        onFailed: (e) {
                                                                          final b = ref.read(
                                                                            pendingImageAlbumNotifierProvider,
                                                                          )[widget.conversationId];
                                                                          ref
                                                                              .read(
                                                                                pendingImageAlbumNotifierProvider.notifier,
                                                                              )
                                                                              .setFor(
                                                                                widget.conversationId,
                                                                                null,
                                                                              );
                                                                          if (mounted) {
                                                                            setState(() {
                                                                              _sendBusy = false;
                                                                              if (b !=
                                                                                  null) {
                                                                                _pendingAttachments
                                                                                  ..clear()
                                                                                  ..addAll(
                                                                                    b.files,
                                                                                  );
                                                                                _controller.text = b.text;
                                                                                _replyingTo = b.replyTo;
                                                                              }
                                                                            });
                                                                            ScaffoldMessenger.of(
                                                                              context,
                                                                            ).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  AppLocalizations.of(
                                                                                    context,
                                                                                  )!.chat_send_failed(
                                                                                    e,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
                                                                        },
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                          onMessageLongPress: (m) =>
                                                              _onMessageLongPress(
                                                                m,
                                                                user,
                                                                conv,
                                                                isGroup,
                                                                dmOtherId,
                                                                profile,
                                                                fontSize:
                                                                    fontSize,
                                                                outgoingBubbleColor:
                                                                    bubbleColor,
                                                                incomingBubbleColor:
                                                                    incomingBubbleColor,
                                                                starredMessageIds:
                                                                    starredIdsAsync
                                                                        .value ??
                                                                    const <
                                                                      String
                                                                    >{},
                                                              ),
                                                          onOpenThread: (m) {
                                                            context.push(
                                                              '/chats/$conversationId/thread/${m.id}',
                                                              extra: m,
                                                            );
                                                          },
                                                          onOpenMediaGallery:
                                                              (att, m) {
                                                                _openMediaGallery(
                                                                  att,
                                                                  m,
                                                                  user: user,
                                                                  isGroup:
                                                                      isGroup,
                                                                  dmOtherId:
                                                                      dmOtherId,
                                                                  profile:
                                                                      profile,
                                                                  profileMap:
                                                                      profileMap,
                                                                  conv: conv
                                                                      ?.data,
                                                                );
                                                              },
                                                          profileMap:
                                                              profileMap,
                                                          contactProfiles:
                                                              contactProfiles,
                                                          onToggleReaction: (m, emoji) async {
                                                            final r = ref.read(
                                                              chatRepositoryProvider,
                                                            );
                                                            if (r == null ||
                                                                emoji
                                                                    .trim()
                                                                    .isEmpty) {
                                                              return;
                                                            }
                                                            try {
                                                              await r.toggleMessageReaction(
                                                                conversationId:
                                                                    widget
                                                                        .conversationId,
                                                                messageId: m.id,
                                                                userId:
                                                                    user.uid,
                                                                emoji: emoji
                                                                    .trim(),
                                                              );
                                                            } catch (e) {
                                                              if (!context
                                                                  .mounted) {
                                                                return;
                                                              }
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    AppLocalizations.of(
                                                                      context,
                                                                    )!.chat_reaction_toggle_failed(
                                                                      e,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        );
                                                      },
                                                ),
                                              ),
                                              if (_inChatSearch)
                                                ListenableBuilder(
                                                  listenable:
                                                      _chatSearchController,
                                                  builder: (context, _) {
                                                    final t =
                                                        _chatSearchController
                                                            .text
                                                            .trim();
                                                    if (t.length < 2) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    final results =
                                                        filterMessagesForInChatSearch(
                                                          msgs,
                                                          _chatSearchController
                                                              .text,
                                                        );
                                                    return Positioned.fill(
                                                      child: ChatMessageSearchOverlay(
                                                        results: results,
                                                        conversation:
                                                            conv?.data,
                                                        profileMap:
                                                            profileMap ??
                                                            <
                                                              String,
                                                              UserProfile
                                                            >{},
                                                        onSelectMessageId: (id) {
                                                          _exitChatSearch();
                                                          _scrollToMessageId(
                                                            id,
                                                          );
                                                        },
                                                        onTapScrim:
                                                            _exitChatSearch,
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
                                              Positioned(
                                                right: 12,
                                                bottom: 12,
                                                child: ChatScrollAnchorButton(
                                                  isVisible: showScrollAnchor,
                                                  unreadCount:
                                                      anchorUnreadBadgeCount,
                                                  reactionEmoji:
                                                      latestReaction?.emoji,
                                                  onReactionTap:
                                                      latestReaction == null
                                                      ? null
                                                      : () {
                                                          unawaited(
                                                            _handleReactionAnchorTap(
                                                              reaction:
                                                                  latestReaction,
                                                              userId: user.uid,
                                                            ),
                                                          );
                                                        },
                                                  onTap: onScrollAnchorTap,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (_selectedMessageIds.isEmpty) ...[
                                  const LiveLocationStopBanner(),
                                  ChatComposer(
                                    controller: _controller,
                                    focusNode: _composerFocusNode,
                                    e2eeDisabledBanner:
                                        (conv != null &&
                                            conv.data.isGroup != true &&
                                            dmOtherId != null &&
                                            dmOtherId.isNotEmpty &&
                                            profile == null)
                                        ? const DeletedAccountReadOnlyBanner()
                                        : dmComposerBlockBanner(
                                            context: context,
                                            ref: ref,
                                            currentUserId: user.uid,
                                            conv: conv?.data,
                                          ),
                                    // Phase 4: в E2EE-чатах текст отправляется
                                    // зашифрованным через [MobileE2eeRuntime].
                                    // Баннер оставляем только когда runtime ещё
                                    // не готов (нет identity) — на практике это
                                    // краткий старт.
                                    replyingTo: _replyingTo,
                                    onCancelReply: () {
                                      setState(() => _replyingTo = null);
                                      _scheduleChatDraftSave();
                                    },
                                    editingPreviewPlain: _editingPreviewPlain,
                                    onCancelEdit: _editingMessageId != null
                                        ? _cancelInlineEdit
                                        : null,
                                    onSend: () {
                                      final globalPolicy =
                                          E2eeDataTypePolicy.fromFirestore(
                                            rawPrivacySettings['e2eeEncryptedDataTypes'],
                                          );
                                      final convData = conv?.data;
                                      final overrideRaw = convData
                                          ?.e2eeEncryptedDataTypesOverride;
                                      final overridePolicy = overrideRaw == null
                                          ? null
                                          : E2eeDataTypePolicy.fromFirestore(
                                              overrideRaw,
                                            );
                                      final effectivePolicy =
                                          resolveE2eeEffectivePolicy(
                                            global: globalPolicy,
                                            override: overridePolicy,
                                          );
                                      unawaited(
                                        _submitComposer(
                                          user.uid,
                                          conv: convData,
                                          e2eePolicy: effectivePolicy,
                                        ),
                                      );
                                    },
                                    onSendLongPress: () {
                                      unawaited(
                                        _openScheduleSheet(
                                          user.uid,
                                          conv: conv?.data,
                                        ),
                                      );
                                    },
                                    groupMentionCandidates:
                                        conv != null && conv.data.isGroup
                                        ? buildGroupMentionCandidates(
                                            conversation: conv.data,
                                            currentUserId: user.uid,
                                            profileMap: profileMap,
                                            contactProfiles: contactProfiles,
                                            l10n: AppLocalizations.of(context),
                                          )
                                        : null,
                                    pendingAttachments: _pendingAttachments,
                                    onRemovePending: (i) {
                                      setState(
                                        () => _pendingAttachments.removeAt(i),
                                      );
                                      _scheduleChatDraftSave();
                                    },
                                    onEditPending: (i) async {
                                      if (i < 0 ||
                                          i >= _pendingAttachments.length) {
                                        return;
                                      }
                                      final target = _pendingAttachments[i];
                                      if (isOutgoingAlbumLocalImage(target)) {
                                        final imageIndices = <int>[];
                                        final imageFiles = <XFile>[];
                                        for (
                                          var idx = 0;
                                          idx < _pendingAttachments.length;
                                          idx++
                                        ) {
                                          final f = _pendingAttachments[idx];
                                          if (isOutgoingAlbumLocalImage(f)) {
                                            imageIndices.add(idx);
                                            imageFiles.add(f);
                                          }
                                        }
                                        if (imageFiles.isEmpty) return;

                                        final initialImageIndex = imageIndices
                                            .indexOf(i);
                                        if (initialImageIndex < 0) return;

                                        final edited =
                                            await ChatImageEditorScreen.open(
                                              context,
                                              files: imageFiles,
                                              initialIndex: initialImageIndex,
                                              initialCaption: _controller.text,
                                            );
                                        if (edited == null || !mounted) return;

                                        setState(() {
                                          final merged = <XFile>[];
                                          var editedImageCursor = 0;
                                          for (final f in _pendingAttachments) {
                                            if (isOutgoingAlbumLocalImage(f)) {
                                              if (editedImageCursor <
                                                  edited.files.length) {
                                                merged.add(
                                                  edited
                                                      .files[editedImageCursor],
                                                );
                                                editedImageCursor += 1;
                                              }
                                              continue;
                                            }
                                            merged.add(f);
                                          }
                                          while (editedImageCursor <
                                              edited.files.length) {
                                            merged.add(
                                              edited.files[editedImageCursor],
                                            );
                                            editedImageCursor += 1;
                                          }
                                          _pendingAttachments
                                            ..clear()
                                            ..addAll(merged);
                                        });
                                        _controller.text = edited.caption;
                                        _scheduleChatDraftSave();
                                        return;
                                      }

                                      if (_looksLikeVideoAttachment(target)) {
                                        final edited =
                                            await ChatVideoEditorScreen.open(
                                              context,
                                              file: target,
                                              initialCaption: _controller.text,
                                            );
                                        if (edited == null || !mounted) return;
                                        setState(() {
                                          if (i < 0 ||
                                              i >= _pendingAttachments.length) {
                                            return;
                                          }
                                          _pendingAttachments[i] = edited.file;
                                        });
                                        _controller.text = edited.caption;
                                        _scheduleChatDraftSave();
                                      }
                                    },
                                    attachmentsEnabled:
                                        _editingMessageId == null,
                                    sendBusy: _sendBusy || pendingAlbum != null,
                                    onAttachmentSelected: (a) =>
                                        unawaited(_handleComposerAttachment(a)),
                                    onMicTap: () =>
                                        unawaited(_sendVoiceMessage(user.uid)),
                                    onVoiceHoldRecorded: (rec) async {
                                      await _sendVoiceMessageFromRecord(
                                        user.uid,
                                        rec,
                                      );
                                    },
                                    onStickersTap: () =>
                                        unawaited(_openStickersGifPanel()),
                                    stickerSuggestionBuilder: () {
                                      final repo = ref.read(
                                        userStickerPacksRepositoryProvider,
                                      );
                                      final chatRepo = ref.read(
                                        chatRepositoryProvider,
                                      );
                                      if (repo == null || chatRepo == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return ComposerStickerSuggestionRow(
                                        userId: user.uid,
                                        repo: repo,
                                        onPickAttachment: (att) => unawaited(
                                          _sendStickerOrGifAttachment(
                                            user.uid,
                                            chatRepo,
                                            att,
                                          ),
                                        ),
                                      );
                                    },
                                    onClipboardToolbarPaste:
                                        _pasteContentFromClipboard,
                                    showFormattingToolbar:
                                        _composerFormattingOpen,
                                    onCloseFormattingToolbar: () => setState(
                                      () => _composerFormattingOpen = false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (showCalls &&
                              dmOtherId != null &&
                              dmOtherId.isNotEmpty)
                            Positioned(
                              top: belowHeaderGap + 8,
                              left: 12,
                              right: 12,
                              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('calls')
                                    .where('receiverId', isEqualTo: user.uid)
                                    .snapshots(),
                                builder: (context, callSnap) {
                                  if (!callSnap.hasData ||
                                      callSnap.data!.docs.isEmpty ||
                                      _callScreenOpening) {
                                    return const SizedBox.shrink();
                                  }
                                  final activeDocs =
                                      callSnap.data!.docs.where((d) {
                                        final m = d.data();
                                        if ((m['callerId'] as String?) !=
                                            dmOtherId) {
                                          return false;
                                        }
                                        final status =
                                            (m['status'] as String?) ?? '';
                                        return status == 'calling' ||
                                            status == 'ongoing';
                                      }).toList()..sort((a, b) {
                                        final ta =
                                            (a.data()['createdAt']
                                                as String?) ??
                                            '';
                                        final tb =
                                            (b.data()['createdAt']
                                                as String?) ??
                                            '';
                                        return tb.compareTo(ta);
                                      });
                                  if (activeDocs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final doc = activeDocs.first;
                                  final callId = doc.id;
                                  final map = doc.data();
                                  final status =
                                      (map['status'] as String?) ?? 'calling';
                                  final isVideo = map['isVideo'] == true;

                                  if (status == 'calling' &&
                                      _handledIncomingCallId != callId &&
                                      !_callScreenOpening) {
                                    _handledIncomingCallId = callId;
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) {
                                      if (!mounted) return;
                                      final meName =
                                          (selfProfile?.name ?? user.uid)
                                              .trim()
                                              .isNotEmpty
                                          ? (selfProfile?.name ?? user.uid)
                                          : user.uid;
                                      final meAvatar =
                                          selfProfile?.avatarThumb ??
                                          selfProfile?.avatar;
                                      final peerName =
                                          (profile?.name ??
                                                      dmFallbackName ??
                                                      title)
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? (profile?.name ??
                                                dmFallbackName ??
                                                title)
                                          : AppLocalizations.of(
                                              context,
                                            )!.partner_profile_call_peer_fallback;
                                      final peerAvatar =
                                          profile?.avatarThumb ??
                                          profile?.avatar ??
                                          dmFallbackAvatarThumb ??
                                          dmFallbackAvatar;
                                      unawaited(
                                        _openCallScreen(
                                          currentUserId: user.uid,
                                          currentUserName: meName,
                                          currentUserAvatarUrl: meAvatar,
                                          peerUserId: dmOtherId!,
                                          peerUserName: peerName,
                                          peerAvatarUrl: peerAvatar,
                                          isVideo: isVideo,
                                          existingCallId: callId,
                                        ),
                                      );
                                    });
                                  }

                                  final incomingLabel = status == 'ongoing'
                                      ? (isVideo
                                            ? AppLocalizations.of(
                                                context,
                                              )!.chat_call_ongoing_video
                                            : AppLocalizations.of(
                                                context,
                                              )!.chat_call_ongoing_audio)
                                      : (isVideo
                                            ? AppLocalizations.of(
                                                context,
                                              )!.chat_call_incoming_video
                                            : AppLocalizations.of(
                                                context,
                                              )!.chat_call_incoming_audio);
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.52,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        10,
                                        10,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isVideo
                                                ? Icons.videocam_rounded
                                                : Icons.call_rounded,
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              incomingLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (status != 'ongoing')
                                            TextButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('calls')
                                                    .doc(callId)
                                                    .update(<String, Object?>{
                                                      'status': 'cancelled',
                                                      'endedAt': DateTime.now()
                                                          .toUtc()
                                                          .toIso8601String(),
                                                    });
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.chat_call_decline,
                                              ),
                                            ),
                                          TextButton(
                                            onPressed: () async {
                                              final meName =
                                                  (selfProfile?.name ??
                                                          user.uid)
                                                      .trim()
                                                      .isNotEmpty
                                                  ? (selfProfile?.name ??
                                                        user.uid)
                                                  : user.uid;
                                              final meAvatar =
                                                  selfProfile?.avatarThumb ??
                                                  selfProfile?.avatar;
                                              final peerName =
                                                  (profile?.name ??
                                                              dmFallbackName ??
                                                              title)
                                                          .trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? (profile?.name ??
                                                        dmFallbackName ??
                                                        title)
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.partner_profile_call_peer_fallback;
                                              final peerAvatar =
                                                  profile?.avatarThumb ??
                                                  profile?.avatar ??
                                                  dmFallbackAvatarThumb ??
                                                  dmFallbackAvatar;
                                              await _openCallScreen(
                                                currentUserId: user.uid,
                                                currentUserName: meName,
                                                currentUserAvatarUrl: meAvatar,
                                                peerUserId: dmOtherId!,
                                                peerUserName: peerName,
                                                peerAvatarUrl: peerAvatar,
                                                isVideo: isVideo,
                                                existingCallId: callId,
                                              );
                                            },
                                            child: Text(
                                              status == 'ongoing'
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.chat_call_open
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.chat_call_accept,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                String? wallpaperForPrefs(Map<String, dynamic>? prefData) {
                  return resolveEffectiveChatWallpaper(
                    globalChatWallpaper: wallpaper,
                    conversationPrefs: prefData ?? const <String, dynamic>{},
                  );
                }

                Widget messagesShell(String? effectiveWp) {
                  return msgsAsync.when(
                    skipLoadingOnReload: true,
                    data: (msgs) {
                      final clearedAtIso = conv?.data.clearedAt?[user.uid];
                      _scheduleMessageExpiryRefresh(msgs);
                      final visibleMsgs = _filterExpiredMessages(
                        _filterByClearedAt(msgs, clearedAtIso),
                      );
                      final previousVisibleCount = _lastMessagesCount;
                      _lastMessagesCount = visibleMsgs.length;
                      _sortedAscCache = List<ChatMessage>.from(visibleMsgs)
                        ..sort((a, b) {
                          final t = a.createdAt.compareTo(b.createdAt);
                          if (t != 0) return t;
                          return a.id.compareTo(b.id);
                        });
                      _sortedHydratedAscCache = const <ChatMessage>[];
                      _syncMessageItemKeys(_sortedAscCache);
                      if (visibleMsgs.length < _limit) {
                        _historyExhausted = true;
                      } else if (visibleMsgs.length > _historyBaseCount) {
                        _historyExhausted = false;
                      }
                      _preserveViewportOnIncomingGrowth(
                        previousCount: previousVisibleCount,
                        nextCount: visibleMsgs.length,
                      );
                      _scheduleHistoryAnchorRestore(visibleMsgs);
                      return chatShell(
                        visibleMsgs,
                        showSpinner: false,
                        effectiveWallpaper: effectiveWp,
                      );
                    },
                    // При смене limit новый family-провайдер даёт loading: не убираем список
                    // (иначе ChatMessageList dispose → снова jump вниз).
                    loading: () {
                      if (_sortedAscCache.isNotEmpty) {
                        _syncMessageItemKeys(_sortedAscCache);
                        return chatShell(
                          _sortedAscCache,
                          showSpinner: false,
                          effectiveWallpaper: effectiveWp,
                        );
                      }
                      return chatShell(
                        const <ChatMessage>[],
                        showSpinner: true,
                        effectiveWallpaper: effectiveWp,
                      );
                    },
                    error: (e, _) {
                      final l10n = AppLocalizations.of(context)!;
                      final fbCode = (e is FirebaseException)
                          ? e.code.toLowerCase().trim()
                          : '';
                      final isDenied = fbCode == 'permission-denied';
                      String diagHint = '';
                      if (isDenied) {
                        // ignore: discarded_futures
                        logChatOpenDiagnostics(
                          stage: 'chat_screen.messages.error',
                          conversationId: conversationId,
                          error: e,
                        );
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        diagHint =
                            '\n\nDiagnostics:\n- uid: ${uid.isEmpty ? '(null)' : uid}';
                      }
                      final msg = isDenied
                          ? 'Permission denied.\n\n'
                                'Most common reasons:\n'
                                '- you are not a participant of this chat\n'
                                '- in 1:1 chat the other user blocked you (chat is hidden)\n'
                                '- the chat was deleted or access was revoked\n'
                          : l10n.chat_load_messages_error(e);
                      return Scaffold(
                        appBar: AppBar(title: Text(l10n.chat_messages_title)),
                        body: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('$msg$diagHint'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: Text(l10n.common_close),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                if (prefsStream == null) {
                  return messagesShell(wallpaperForPrefs(null));
                }
                return StreamBuilder<Map<String, dynamic>>(
                  stream: prefsStream,
                  initialData: const <String, dynamic>{},
                  builder: (context, snap) {
                    return messagesShell(wallpaperForPrefs(snap.data));
                  },
                );
              },
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.chat_conversation_error(e),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context)!.chat_auth_error(e)),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _insertComposerTextAtCursor(String rawText) {
    final t = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (t.trim().isEmpty) return;
    final escaped = ComposerHtmlEditing.escapeHtmlText(t);
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    final next = text.replaceRange(start, end, escaped);
    _controller.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: start + escaped.length),
      composing: TextRange.empty,
    );
    _scheduleChatDraftSave();
  }

  Future<void> _pasteContentFromClipboard() async {
    try {
      final payload = await readComposerClipboardPayload();
      if (!mounted) return;
      if (payload.files.isNotEmpty) {
        setState(() => _pendingAttachments.addAll(payload.files));
        _scheduleChatDraftSave();
      }
      final pastedText = payload.text ?? '';
      if (pastedText.trim().isNotEmpty) {
        _insertComposerTextAtCursor(pastedText);
      }
      if (payload.files.isEmpty && pastedText.trim().isEmpty) {
        _toast(AppLocalizations.of(context)!.chat_clipboard_nothing_to_paste);
      }
    } catch (e) {
      // Безопасный фолбэк: даже если расширенный клипборд недоступен,
      // стараемся хотя бы вставить plain text.
      final fallback = await Clipboard.getData(Clipboard.kTextPlain);
      final text = fallback?.text ?? '';
      if (!mounted) return;
      if (text.trim().isNotEmpty) {
        _insertComposerTextAtCursor(text);
      } else {
        _toast(AppLocalizations.of(context)!.chat_clipboard_paste_failed(e));
      }
    }
  }

  String _starredDocId(String conversationId, String messageId) {
    return 's_${conversationId}_$messageId';
  }

  String _starredPreviewText(ChatMessage m) {
    final raw = (m.text ?? '').trim();
    var plain = raw;
    if (raw.contains('<')) {
      plain = messageHtmlToPlainText(raw);
    }
    plain = plain.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain.isEmpty) {
      if ((m.chatPollId ?? '').trim().isNotEmpty) {
        plain = AppLocalizations.of(context)!.chat_poll_label;
      } else if (m.locationShare != null) {
        plain = AppLocalizations.of(context)!.chat_location_label;
      } else if (m.attachments.isNotEmpty) {
        plain = AppLocalizations.of(context)!.chat_attachment_label;
      } else {
        plain = AppLocalizations.of(context)!.chat_message_empty_placeholder;
      }
    }
    if (plain.length > 240) {
      plain = '${plain.substring(0, 240)}…';
    }
    return plain;
  }

  Future<void> _toggleMessageStar({
    required ChatMessage message,
    required String currentUserId,
    required bool isStarredNow,
  }) async {
    if (message.id.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('starredChatMessages')
        .doc(_starredDocId(widget.conversationId, message.id));
    try {
      if (isStarredNow) {
        await ref.delete();
        if (mounted) _toast(l10n.chat_starred_removed);
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await ref.set(<String, Object?>{
        'conversationId': widget.conversationId,
        'messageId': message.id,
        'createdAt': now,
        'previewText': _starredPreviewText(message),
      }, SetOptions(merge: true));
      if (mounted) _toast(l10n.chat_starred_added);
    } catch (e) {
      if (mounted) _toast(l10n.chat_starred_toggle_failed(e));
    }
  }

  String _senderLabelForMediaViewer(
    String senderId, {
    required User user,
    required Map<String, UserProfile>? profileMap,
    required Conversation? conv,
  }) {
    if (senderId == user.uid) {
      return AppLocalizations.of(context)!.chat_sender_you;
    }
    final p = profileMap?[senderId];
    if ((p?.name ?? '').trim().isNotEmpty) return p!.name.trim();
    final pi = conv?.participantInfo?[senderId];
    final n = pi?.name;
    if ((n ?? '').trim().isNotEmpty) return n!.trim();
    return AppLocalizations.of(context)!.forward_sender_fallback;
  }

  Future<bool> _confirmDeleteMessageForViewer(ChatMessage m) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return false;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chat_delete_message_title_single),
        content: Text(l10n.chat_delete_message_body_single),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.common_delete),
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
      if (mounted) _toast(l10n.chat_delete_action_failed(e));
      return false;
    }
  }

  Future<void> _retryMediaNormForMainChat(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(chatRepositoryProvider);
      if (repo == null) return;
      await repo.retryChatMediaTranscode(
        conversationId: widget.conversationId,
        messageId: message.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chat_media_transcode_retry_started)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chat_media_transcode_retry_failed(e))),
      );
    }
  }

  Future<void> _emitEmojiBurstEvent(
    ChatMessage message,
    String emoji,
    String eventId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(chatRepositoryProvider);
      if (repo == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.trim().isEmpty) return;
      await repo.emitEmojiBurstEvent(
        conversationId: widget.conversationId,
        messageId: message.id,
        senderId: uid,
        emoji: emoji,
        eventId: eventId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chat_emoji_burst_sync_failed(e))),
      );
    }
  }

  Future<bool> _confirmDeleteMediaGalleryItem(ChatMediaGalleryItem item) async {
    final m = item.message;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return false;
    final l10n = AppLocalizations.of(context)!;
    if (m.attachments.length <= 1) {
      return _confirmDeleteMessageForViewer(m);
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chat_delete_file_title),
        content: Text(l10n.chat_delete_file_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await repo.removeMessageAttachment(
        conversationId: widget.conversationId,
        messageId: m.id,
        attachmentUrl: item.attachment.url,
      );
      return true;
    } catch (e) {
      if (mounted) _toast(l10n.chat_delete_action_failed(e));
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
    final l10n = AppLocalizations.of(context)!;
    final isSecret = conv?.secretChat?.enabled == true;
    if (isSecret && SecretChatMediaOpenService.isLockedSecretAttachment(att)) {
      unawaited(() async {
        final rt = ref.read(mobileE2eeRuntimeProvider);
        if (rt == null) return;
        try {
          final resolved = await const SecretChatMediaOpenService().openForView(
            runtime: rt,
            conversationId: widget.conversationId,
            message: msg,
            lockedAttachment: att,
          );
          if (!mounted) return;
          Navigator.of(context).push<void>(
            chatMediaViewerPageRoute<void>(
              ChatMediaViewerScreen(
                items: [
                  ChatMediaGalleryItem(attachment: resolved, message: msg),
                ],
                initialIndex: 0,
                conversationId: widget.conversationId,
                currentUserId: user.uid,
                senderLabel: (sid) => _senderLabelForMediaViewer(
                  sid,
                  user: user,
                  profileMap: profileMap,
                  conv: conv,
                ),
                onForward: (_) => _toast(l10n.secret_chat_action_not_allowed),
                onDeleteItem: _confirmDeleteMediaGalleryItem,
                allowForward: false,
                allowSave: false,
                allowExternalShare: false,
              ),
            ),
          );
        } catch (_) {
          if (mounted) _toast(l10n.secret_chat_unlock_failed);
        }
      }());
      return;
    }
    final source = _sortedHydratedAscCache.isNotEmpty
        ? _sortedHydratedAscCache
        : _sortedAscCache;
    final items = collectChatMediaGalleryItems(source);
    if (items.isEmpty) return;
    final ix = indexInChatMediaGallery(items, att.url);
    final secretRestrictions = conv?.secretChat?.restrictions;
    final allowForward = !(secretRestrictions?.noForward == true);
    final allowSave = !(secretRestrictions?.noSave == true);
    Navigator.of(context).push<void>(
      chatMediaViewerPageRoute<void>(
        ChatMediaViewerScreen(
          items: items,
          initialIndex: ix,
          conversationId: widget.conversationId,
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
                                                      l10n: AppLocalizations.of(context)!,
                                                      message: m,
                currentUserId: user.uid,
                isGroup: isGroup,
                otherUserId: dmOtherId,
                otherUserName: profile?.name,
              );
            });
            if (leaveEdit) _controller.clear();
            _scheduleChatDraftSave();
          },
          onForward: (galleryItem) {
            if (!allowForward) {
              _toast(
                AppLocalizations.of(context)!.secret_chat_action_not_allowed,
              );
              return;
            }
            if (galleryItem.message.isDeleted) return;
            final m = chatMessageForSingleAttachmentForward(
              galleryItem.message,
              galleryItem.attachment,
            );
            context.push('/chats/forward', extra: <ChatMessage>[m]);
          },
          allowForward: allowForward,
          allowSave: allowSave,
          allowExternalShare: allowSave,
          onDeleteItem: _confirmDeleteMediaGalleryItem,
          onShowInChat: (galleryItem) {
            _scrollToMessageId(galleryItem.message.id);
          },
        ),
      ),
    );
  }

  void _exitSelection() {
    setState(() => _selectedMessageIds.clear());
  }

  void _toggleMessageSelected(ChatMessage m) {
    if (m.id.startsWith(kLocalOutboxMessageIdPrefix)) return;
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          targets.length > 1
              ? l10n.chat_delete_message_title_multi
              : l10n.chat_delete_message_title_single,
        ),
        content: Text(
          targets.length > 1
              ? l10n.chat_delete_message_body_multi(targets.length)
              : l10n.chat_delete_message_body_single,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.common_delete),
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
      _toast(l10n.chat_delete_action_failed(e));
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
    // В инпут кладём plain-текст, чтобы пользователь не видел системные HTML-теги
    // (`<p>`, `</p>`, `<br>`) при обычном редактировании/удалении символов.
    final raw = (m.text ?? '').trim();
    final forEdit = raw.isEmpty ? '' : messageHtmlToPlainText(raw);
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
    final l10n = AppLocalizations.of(context)!;
    final existing = conversationPinnedList(conv);
    if (existing.any((p) => p.messageId == m.id)) {
      _toast(l10n.chat_pin_already_pinned);
      return;
    }
    if (existing.length >= maxPinnedMessages) {
      _toast(l10n.chat_pin_limit_reached(maxPinnedMessages));
      return;
    }
    final entry = buildPinnedMessageFromChatMessage(
          l10n: AppLocalizations.of(context)!,
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
      if (mounted) _toast(l10n.chat_pin_failed(e));
    }
  }

  Future<void> _unpinMessage(PinnedMessage p, Conversation conv) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final l10n = AppLocalizations.of(context)!;
    final existing = conversationPinnedList(conv);
    final next = existing.where((x) => x.messageId != p.messageId).toList();
    try {
      await repo.setPinnedMessages(
        conversationId: widget.conversationId,
        pins: next,
      );
    } catch (e) {
      if (mounted) _toast(l10n.chat_unpin_failed(e));
    }
  }

  bool _isMessageStalePending(ChatMessage m) {
    if (m.id.startsWith(kLocalOutboxMessageIdPrefix)) return false;
    if ((m.deliveryStatus ?? '') != 'sending') return false;
    final origin = _pendingRetryAt[m.id] ?? m.createdAt;
    return DateTime.now().difference(origin) >=
        const Duration(seconds: 30);
  }

  Future<void> _cancelStalePendingMessage(ChatMessage m) async {
    _pendingRetryAt.remove(m.id);
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(m.id)
          .delete();
    } catch (e) {
      debugPrint('cancel stale-pending message $m.id failed: $e');
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
    required Color? outgoingBubbleColor,
    required Color? incomingBubbleColor,
    required Set<String> starredMessageIds,
  }) async {
    if (m.id.startsWith(kLocalOutboxMessageIdPrefix) &&
        (m.deliveryStatus ?? '') == 'failed') {
      final result = await showOutboxFailedContextMenu(
        context,
        message: m,
        chatFontSize: fontSize,
        outgoingBubbleColor: outgoingBubbleColor,
      );
      if (!mounted ||
          result == null ||
          result.type == MessageMenuActionType.dismissed) {
        return;
      }
      switch (result.type) {
        case MessageMenuActionType.outboxRetry:
          handleOutboxRetry(ref, m.id);
        case MessageMenuActionType.outboxCancel:
          unawaited(handleOutboxDismiss(ref, m.id));
        default:
          break;
      }
      return;
    }
    if (_isMessageStalePending(m)) {
      final result = await showOutboxFailedContextMenu(
        context,
        message: m,
        chatFontSize: fontSize,
        outgoingBubbleColor: outgoingBubbleColor,
      );
      if (!mounted ||
          result == null ||
          result.type == MessageMenuActionType.dismissed) {
        return;
      }
      switch (result.type) {
        case MessageMenuActionType.outboxRetry:
          setState(() => _pendingRetryAt[m.id] = DateTime.now());
        case MessageMenuActionType.outboxCancel:
          unawaited(_cancelStalePendingMessage(m));
        default:
          break;
      }
      return;
    }
    final isMine = m.senderId == user.uid;
    final canEdit =
        isMine && !m.isDeleted && (m.text?.trim().isNotEmpty ?? false);
    final canDelete = isMine && !m.isDeleted;
    final plain = (m.text ?? '').trim();
    final hasMenuText =
        plain.isNotEmpty &&
        (plain.contains('<')
            ? messageHtmlToPlainText(plain).trim().isNotEmpty
            : true);

    final secretRestrictions = convWrap?.data.secretChat?.restrictions;
    final allowCopy = !(secretRestrictions?.noCopy == true);
    final allowForward = !(secretRestrictions?.noForward == true);
    final result = await showMessageContextMenu(
      context,
      message: m,
      isCurrentUser: isMine,
      hasText: hasMenuText,
      canEdit: canEdit,
      canDelete: canDelete,
      allowCopy: allowCopy,
      allowForward: allowForward,
      showStarAction: !m.isDeleted,
      isStarred: starredMessageIds.contains(m.id),
      chatFontSize: fontSize,
      outgoingBubbleColor: outgoingBubbleColor,
      incomingBubbleColor: incomingBubbleColor,
    );
    if (!mounted ||
        result == null ||
        result.type == MessageMenuActionType.dismissed) {
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
                                                      l10n: AppLocalizations.of(context)!,
                                                      message: m,
            currentUserId: user.uid,
            isGroup: isGroup,
            otherUserId: otherId,
            otherUserName: profile?.name,
          );
        });
        if (leaveEdit) _controller.clear();
        _scheduleChatDraftSave();
      case MessageMenuActionType.thread:
        if (!mounted) return;
        context.push(
          '/chats/${widget.conversationId}/thread/${m.id}',
          extra: m,
        );
      case MessageMenuActionType.copy:
        if (!allowCopy) {
          if (mounted) {
            _toast(
              AppLocalizations.of(context)!.secret_chat_action_not_allowed,
            );
          }
          return;
        }
        await copyMessageTextToClipboard(m);
        if (mounted) _toast(AppLocalizations.of(context)!.chat_text_copied);
      case MessageMenuActionType.edit:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startInlineEdit(m);
        });
      case MessageMenuActionType.pin:
        await _pinMessage(m, user, convWrap, isGroup, otherId, profile);
      case MessageMenuActionType.star:
        await _toggleMessageStar(
          message: m,
          currentUserId: user.uid,
          isStarredNow: starredMessageIds.contains(m.id),
        );
      case MessageMenuActionType.forward:
        if (!allowForward) {
          if (mounted) {
            _toast(
              AppLocalizations.of(context)!.secret_chat_action_not_allowed,
            );
          }
          return;
        }
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
          if (mounted) {
            _toast(
              AppLocalizations.of(context)!.chat_reaction_toggle_failed(e),
            );
          }
        }
      case MessageMenuActionType.outboxRetry:
      case MessageMenuActionType.outboxCancel:
        break;
    }
  }

  void _onScrollLoadOlder() {
    final now = DateTime.now();
    if (_nearOldestCooldownUntil != null &&
        now.isBefore(_nearOldestCooldownUntil!)) {
      return;
    }
    if (_historyLoadInFlight || _loadingOlder || _historyExhausted) return;
    _historyLoadInFlight = true;
    _suppressAutoScrollToBottom = true;
    _historyCycleId += 1;
    _activeHistoryCycleId = _historyCycleId;
    _historyWaitTicks = 0;
    _historyBaseCount = _lastMessagesCount;
    final sc = _scrollController;
    if (sc.hasClients) {
      final pos = sc.position;
      _historyStartPixels = pos.pixels;
      _historyStartMaxScrollExtent = pos.maxScrollExtent;
      _historyStartedNearOldestEdge = _messageListReversed
          ? (pos.maxScrollExtent - pos.pixels) <= 72
          : (pos.pixels - pos.minScrollExtent) <= 72;
    } else {
      _historyStartPixels = null;
      _historyStartMaxScrollExtent = null;
      _historyStartedNearOldestEdge = false;
    }
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
        _historyNoGrowthStreak += 1;
        if (_historyNoGrowthStreak >= 2) {
          _historyExhausted = true;
        }
        // Новых сообщений нет — не вызываем ensureVisible (позиция уже сохранена,
        // если список не снимали с дерева при смене limit). Для iOS-bounce
        // дополнительно фиксируем текущий viewport, чтобы не было "отскока"
        // вниз на несколько сообщений.
        _restoreViewportAfterNoHistoryGrowth();
        _finishHistoryLoad();
        return;
      }
      _historyNoGrowthStreak = 0;
      _historyExhausted = false;

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

  void _restoreViewportAfterNoHistoryGrowth() {
    final sc = _scrollController;
    if (!sc.hasClients) return;
    final pos = sc.position;
    if (_historyStartedNearOldestEdge) {
      final target = _messageListReversed
          ? pos.maxScrollExtent
          : pos.minScrollExtent;
      if ((target - pos.pixels).abs() > 0.5) {
        pos.jumpTo(target);
      }
      return;
    }
    final startPixels = _historyStartPixels;
    final startMax = _historyStartMaxScrollExtent;
    if (startPixels == null || startMax == null) return;
    final deltaMax = pos.maxScrollExtent - startMax;
    final target = (startPixels + deltaMax).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if ((target - pos.pixels).abs() <= 0.5) return;
    pos.jumpTo(target);
  }

  void _finishHistoryLoad() {
    _nearOldestCooldownUntil = DateTime.now().add(
      const Duration(milliseconds: 800),
    );
    _historyLoadInFlight = false;
    _suppressAutoScrollToBottom = false;
    _activeHistoryCycleId = null;
    _historyWaitTicks = 0;
    _historyBaseCount = 0;
    _historyStartPixels = null;
    _historyStartMaxScrollExtent = null;
    _historyStartedNearOldestEdge = false;
    _pendingAnchorMessageId = null;
    _pendingAnchorAlignment = null;
    if (mounted && _loadingOlder) {
      setState(() => _loadingOlder = false);
    }
  }

  ReplyContext? _stripReplyPreviewByPolicy(
    ReplyContext? input,
    E2eeDataTypePolicy policy,
  ) {
    if (input == null) return null;
    if (policy.replyPreview) return input;
    return ReplyContext(
      messageId: input.messageId,
      senderName: input.senderName,
      mediaType: input.mediaType,
      // intentionally omit plaintext preview fields
      text: null,
      mediaPreviewUrl: null,
    );
  }

  /// Открыть sheet «запланировать сообщение» (long-press на send).
  /// MVP mobile: только текст без вложений. При наличии вложений — toast.
  Future<void> _openScheduleSheet(String uid, {Conversation? conv}) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final l10n = AppLocalizations.of(context)!;
    final raw = _controller.text;
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(raw);
    final plain = prepared.isEmpty
        ? ''
        : messageHtmlToPlainText(prepared).trim();
    if (plain.isEmpty) {
      _toast(l10n.schedule_message_text_required);
      return;
    }
    if (_pendingAttachments.isNotEmpty) {
      _toast(l10n.schedule_message_attachments_unsupported_mobile);
      return;
    }
    if (_editingMessageId != null) return;

    final e2eeActive = isConversationE2eeActive(conv);
    final picked = await showScheduleMessageSheet(
      context: context,
      showE2eeWarning: e2eeActive,
    );
    if (picked == null || !mounted) return;

    final replyTo = _replyingTo;
    try {
      await repo.scheduleMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        sendAt: picked,
        text: prepared,
        replyTo: replyTo,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _replyingTo = null;
      });
      unawaited(clearChatMessageDraft(uid, widget.conversationId));
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      final fmt = DateFormat('d MMM, HH:mm', localeTag);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.schedule_message_scheduled_toast(fmt.format(picked)),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _toast(l10n.schedule_message_failed_toast(e.toString()));
      }
    }
  }

  Future<void> _submitComposer(
    String uid, {
    Conversation? conv,
    required E2eeDataTypePolicy e2eePolicy,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    // Phase 4: если чат в E2EE, нам нужны (а) заранее известный messageId,
    // чтобы включить его в AAD, и (б) encrypted envelope. Все места ниже,
    // отправляющие простой текст, используют этот helper.
    final bool convIsE2ee = isConversationE2eeActive(conv);
    final effectiveE2eePolicy = convIsE2ee
        ? e2eePolicy.copyWith(text: true, media: true)
        : e2eePolicy;
    final MobileE2eeRuntime? e2eeRuntime = convIsE2ee
        ? ref.read(mobileE2eeRuntimeProvider)
        : null;
    final int? e2eeEpoch = conv?.e2eeKeyEpoch;

    if (_sendBusy) return;
    final rawComposer = _controller.text;
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      rawComposer,
    );
    final plainOut = prepared.isEmpty
        ? ''
        : messageHtmlToPlainText(prepared).trim();
    final editingId = _editingMessageId;

    if (editingId != null) {
      if (_pendingAttachments.isNotEmpty) {
        _toast(AppLocalizations.of(context)!.chat_edit_attachments_not_allowed);
        return;
      }
      if (plainOut.isEmpty) {
        _toast(AppLocalizations.of(context)!.chat_edit_text_empty);
        return;
      }
    } else if (plainOut.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    if (editingId != null) {
      try {
        Map<String, Object?>? editEnvelope;
        if (convIsE2ee &&
            effectiveE2eePolicy.text &&
            e2eeRuntime != null &&
            e2eeEpoch != null) {
          try {
            editEnvelope = await e2eeRuntime.encryptOutgoing(
              conversationId: widget.conversationId,
              messageId: editingId,
              epoch: e2eeEpoch,
              plaintext: prepared,
            );
          } on MobileE2eeEncryptException catch (e) {
            if (mounted) {
              _toast(
                AppLocalizations.of(context)!.chat_e2ee_unavailable(e.code),
              );
            }
            return;
          }
        }
        await repo.updateMessageText(
          conversationId: widget.conversationId,
          messageId: editingId,
          text: prepared,
          e2eeEnvelope: editEnvelope,
        );
        if (!mounted) return;
        setState(() {
          _editingMessageId = null;
          _editingPreviewPlain = null;
          _composerFormattingOpen = false;
        });
        _controller.clear();
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
      } catch (e) {
        if (mounted) _toast(AppLocalizations.of(context)!.chat_save_failed(e));
      }
      return;
    }

    final pending = List<XFile>.from(_pendingAttachments);
    if (pending.isNotEmpty) {
      final replySnap = _stripReplyPreviewByPolicy(
        _replyingTo,
        effectiveE2eePolicy,
      );
      final textSave = prepared;
      if (pending.every(isOutgoingAlbumLocalImage)) {
        // E2EE v2 Phase 9: для E2EE-active чата заранее резервируем messageId и
        // готовим контекст для альбома (runtime + epoch + messageId) — всё для
        // того, чтобы AAD включал тот же messageId, под которым будет записано
        // сообщение в Firestore.
        OutgoingAlbumE2eeContext? albumE2eeContext;
        if (convIsE2ee &&
            effectiveE2eePolicy.media &&
            e2eeRuntime != null &&
            e2eeEpoch != null) {
          final reservedId = FirebaseFirestore.instance
              .collection('conversations')
              .doc(widget.conversationId)
              .collection('messages')
              .doc()
              .id;
          albumE2eeContext = OutgoingAlbumE2eeContext(
            runtime: e2eeRuntime,
            epoch: e2eeEpoch,
            messageId: reservedId,
            encryptText: effectiveE2eePolicy.text,
          );
        }
        ref
            .read(pendingImageAlbumNotifierProvider.notifier)
            .setFor(
              widget.conversationId,
              PendingImageAlbumSend(
                files: pending,
                text: textSave,
                replyTo: replySnap,
                e2eeContext: albumE2eeContext,
              ),
            );
        setState(() {
          _pendingAttachments.clear();
          _controller.clear();
          _replyingTo = null;
          _composerFormattingOpen = false;
          _sendBusy = true;
        });
        if (_chatAtBottom && !_suppressAutoScrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _jumpToChatBottom();
          });
        }
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        return;
      }
      setState(() => _sendBusy = true);
      await ref
          .read(chatOutboxAttachmentNotifierProvider.notifier)
          .enqueueFromComposer(
            conversationId: widget.conversationId,
            senderId: uid,
            files: pending,
            rawCaptionHtml: prepared,
            replyTo: replySnap,
            convIsE2ee: convIsE2ee,
            e2eeEncryptText: effectiveE2eePolicy.text,
            e2eeEncryptMedia: effectiveE2eePolicy.media,
            e2eeEpoch: e2eeEpoch,
          );
      if (mounted) {
        setState(() {
          _sendBusy = false;
          _pendingAttachments.clear();
          _controller.clear();
          _replyingTo = null;
          _composerFormattingOpen = false;
        });
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        _scheduleAutoScrollToBottomIfNeeded();
      }
      return;
    }

    final replySnap = _stripReplyPreviewByPolicy(
      _replyingTo,
      effectiveE2eePolicy,
    );
    _controller.clear();
    setState(() => _sendBusy = true);
    await ref
        .read(chatOutboxAttachmentNotifierProvider.notifier)
        .enqueueFromComposer(
          conversationId: widget.conversationId,
          senderId: uid,
          files: const <XFile>[],
          rawCaptionHtml: prepared,
          replyTo: replySnap,
          convIsE2ee: convIsE2ee,
          e2eeEncryptText: effectiveE2eePolicy.text,
          e2eeEncryptMedia: effectiveE2eePolicy.media,
          e2eeEpoch: e2eeEpoch,
        );
    if (mounted) {
      setState(() {
        _sendBusy = false;
        _replyingTo = null;
        _composerFormattingOpen = false;
      });
      unawaited(clearChatMessageDraft(uid, widget.conversationId));
      _scheduleAutoScrollToBottomIfNeeded();
    }
  }

  Future<void> _sendLocationShare() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast(AppLocalizations.of(context)!.chat_repository_unavailable);
      return;
    }
    final convAsync = ref.read(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final convList = convAsync.asData?.value;
    final conv = convList != null && convList.isNotEmpty
        ? convList.first
        : null;
    if (conv == null) {
      _toast(AppLocalizations.of(context)!.chat_still_loading);
      return;
    }
    final participantIds = conv.data.participantIds;
    if (participantIds.isEmpty) {
      _toast(AppLocalizations.of(context)!.chat_no_participants);
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
            AppLocalizations.of(context)!.chat_location_ios_geolocator_missing,
          );
        }
        return;
      }
      if (!serviceEnabled) {
        if (mounted) {
          _toast(AppLocalizations.of(context)!.chat_location_services_disabled);
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _toast(AppLocalizations.of(context)!.chat_location_permission_denied);
        }
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
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        setState(() => _replyingTo = null);
        _scheduleAutoScrollToBottomIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.chat_location_send_failed(e),
            ),
          ),
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
      _toast(AppLocalizations.of(context)!.chat_repository_unavailable);
      return;
    }
    if (_editingMessageId != null) {
      _toast(AppLocalizations.of(context)!.chat_finish_editing_first);
      return;
    }
    await pushVideoCircleCapturePage(
      context,
      onSend: (raw) => _sendVideoCircleFile(uid, repo, raw),
    );
  }

  /// E2EE v2 Phase 9: читает текущий conversation snapshot из
  /// `conversationsProvider` и, если чат E2EE-active, возвращает тройку
  /// (runtime, epoch, reservedMessageId) для media-only отправки. Возвращает
  /// null, если E2EE не активирован или данные недоступны.
  E2eeDataTypePolicy _resolveEffectiveE2eePolicyForChat(String uid) {
    final userDoc =
        ref.read(userChatSettingsDocProvider(uid)).asData?.value ??
        const <String, dynamic>{};
    final rawPrivacy =
        userDoc['privacySettings'] as Map? ?? const <String, dynamic>{};
    final global = E2eeDataTypePolicy.fromFirestore(
      rawPrivacy['e2eeEncryptedDataTypes'],
    );
    final convAsync = ref.read(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final convList = convAsync.asData?.value;
    final conv = convList != null && convList.isNotEmpty
        ? convList.first.data
        : null;
    final overrideRaw = conv?.e2eeEncryptedDataTypesOverride;
    final overridePolicy = overrideRaw == null
        ? null
        : E2eeDataTypePolicy.fromFirestore(overrideRaw);
    final base = resolveE2eeEffectivePolicy(
      global: global,
      override: overridePolicy,
    );
    if (isConversationE2eeActive(conv)) {
      // Для E2EE-активного чата исходящие сообщения обязаны уходить в envelope.
      return base.copyWith(text: true, media: true);
    }
    return base;
  }

  ({MobileE2eeRuntime runtime, int epoch, String messageId})?
  _resolveMediaOnlyE2eeContext(String uid) {
    final convAsync = ref.read(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final convList = convAsync.asData?.value;
    final conv = convList != null && convList.isNotEmpty
        ? convList.first.data
        : null;
    if (!isConversationE2eeActive(conv)) return null;
    final policy = _resolveEffectiveE2eePolicyForChat(uid);
    if (!policy.media) return null;
    final runtime = ref.read(mobileE2eeRuntimeProvider);
    final epoch = conv?.e2eeKeyEpoch;
    if (runtime == null || epoch == null) return null;
    final reservedId = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc()
        .id;
    return (runtime: runtime, epoch: epoch, messageId: reservedId);
  }

  Future<void> _sendVideoCircleFile(
    String uid,
    ChatRepository repo,
    XFile raw,
  ) async {
    final lower = raw.path.toLowerCase();
    final ext = lower.endsWith('.mov') || lower.endsWith('.qt') ? 'mov' : 'mp4';
    final mime = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    final name = 'video-circle_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = XFile(raw.path, mimeType: mime);
    final policy = _resolveEffectiveE2eePolicyForChat(uid);
    final replySnap = _stripReplyPreviewByPolicy(_replyingTo, policy);
    setState(() => _sendBusy = true);
    try {
      // E2EE v2 Phase 9: кружок шифруется, если чат E2EE-active.
      final e2ee = _resolveMediaOnlyE2eeContext(uid);
      if (e2ee != null) {
        final bytes = await file.readAsBytes();
        final envelope = await e2ee.runtime.encryptMediaForSend(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          messageId: e2ee.messageId,
          epoch: e2ee.epoch,
          data: bytes,
          mime: mime,
          kindHint: MediaKindV2.videoCircle,
        );
        // Пустой text-envelope (plaintext='') нужен, чтобы валидный iv/ct
        // попали в `message.e2ee`: без них приёмник не распознает сообщение
        // как E2EE и «Зашифрованное сообщение» preview не сработает.
        final emptyTextEnvelope = await e2ee.runtime.encryptOutgoing(
          conversationId: widget.conversationId,
          messageId: e2ee.messageId,
          epoch: e2ee.epoch,
          plaintext: '',
        );
        final mergedE2ee = mergeE2eeEnvelopeWithMedia(
          textEnvelope: emptyTextEnvelope,
          mediaEnvelopes: [envelope.toWireJson()],
          epoch: e2ee.epoch,
        );
        await repo.sendTextMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: '',
          replyTo: replySnap,
          e2eeEnvelope: mergedE2ee,
          messageIdOverride: e2ee.messageId,
        );
      } else {
        final uploaded = await uploadChatAttachmentFromXFile(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          file: file,
          displayName: name,
        );
        await repo.sendTextMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: '',
          replyTo: replySnap,
          attachments: [uploaded],
        );
      }
      if (mounted) {
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        setState(() => _replyingTo = null);
        _scheduleAutoScrollToBottomIfNeeded();
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _sendVoiceMessage(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _sendBusy) return;
    final rec = await showVoiceMessageRecordSheet(context);
    if (!mounted || rec == null) return;
    await _sendVoiceMessageFromRecord(uid, rec);
  }

  Future<void> _sendVoiceMessageFromRecord(
    String uid,
    VoiceMessageRecordResult rec,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _sendBusy) return;
    setState(() => _sendBusy = true);
    try {
      final audioName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = XFile(rec.filePath, mimeType: 'audio/m4a');
      final policy = _resolveEffectiveE2eePolicyForChat(uid);
      // E2EE v2 Phase 9: голосовые также шифруются в E2EE-active чате.
      final e2ee = _resolveMediaOnlyE2eeContext(uid);
      if (e2ee != null) {
        final bytes = await file.readAsBytes();
        final envelope = await e2ee.runtime.encryptMediaForSend(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          messageId: e2ee.messageId,
          epoch: e2ee.epoch,
          data: bytes,
          mime: 'audio/m4a',
        );
        final emptyTextEnvelope = await e2ee.runtime.encryptOutgoing(
          conversationId: widget.conversationId,
          messageId: e2ee.messageId,
          epoch: e2ee.epoch,
          plaintext: '',
        );
        final mergedE2ee = mergeE2eeEnvelopeWithMedia(
          textEnvelope: emptyTextEnvelope,
          mediaEnvelopes: [envelope.toWireJson()],
          epoch: e2ee.epoch,
        );
        await repo.sendTextMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: '',
          replyTo: _stripReplyPreviewByPolicy(_replyingTo, policy),
          e2eeEnvelope: mergedE2ee,
          messageIdOverride: e2ee.messageId,
        );
      } else {
        final uploaded = await uploadChatAttachmentFromXFile(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          file: file,
          displayName: audioName,
        );
        await repo.sendTextMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: '',
          replyTo: _stripReplyPreviewByPolicy(_replyingTo, policy),
          attachments: [uploaded],
        );
      }
      if (mounted) {
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        setState(() {
          _replyingTo = null;
          _composerFormattingOpen = false;
        });
        _scheduleAutoScrollToBottomIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        _toast(AppLocalizations.of(context)!.chat_send_voice_failed(e));
      }
    } finally {
      unawaited(_deleteFileSilently(rec.filePath));
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _deleteFileSilently(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _openStickersGifPanel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast(AppLocalizations.of(context)!.forward_error_not_authorized);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    if (stickerRepo == null || chatRepo == null) {
      _toast(AppLocalizations.of(context)!.chat_service_unavailable);
      return;
    }
    await showComposerStickerGifSheet(
      context: context,
      userId: uid,
      repo: stickerRepo,
      directUploadConversationId: widget.conversationId,
      onPickAttachment: (att) {
        unawaited(_sendStickerOrGifAttachment(uid, chatRepo, att));
      },
      onEmojiTapped: _insertEmojiIntoComposer,
    );
  }

  void _insertEmojiIntoComposer(String emoji) {
    final ctrl = _controller;
    final sel = ctrl.selection;
    final text = ctrl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    final newOffset = start + emoji.length;
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  Future<void> _sendStickerOrGifAttachment(
    String uid,
    ChatRepository repo,
    ChatAttachment att,
  ) async {
    final policy = _resolveEffectiveE2eePolicyForChat(uid);
    final replySnap = _stripReplyPreviewByPolicy(_replyingTo, policy);
    setState(() => _sendBusy = true);
    try {
      // E2EE v2 Phase 9: стикеры/GIFs шифровать нельзя (animated/format), но
      // в E2EE-active чате repo требует envelope — отправляем «пустой» text
      // envelope (plaintext='') чтобы push-notification трактовал сообщение
      // как «Зашифрованное сообщение» и не раскрывал вложения через summary.
      final e2ee = _resolveMediaOnlyE2eeContext(uid);
      Map<String, Object?>? outgoingEnvelope;
      String? msgIdOverride;
      if (e2ee != null) {
        final textEnvelope = await e2ee.runtime.encryptOutgoing(
          conversationId: widget.conversationId,
          messageId: e2ee.messageId,
          epoch: e2ee.epoch,
          plaintext: '',
        );
        outgoingEnvelope = mergeE2eeEnvelopeWithMedia(
          textEnvelope: textEnvelope,
          mediaEnvelopes: const <Map<String, Object?>>[],
          epoch: e2ee.epoch,
        );
        msgIdOverride = e2ee.messageId;
      }
      await repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: '',
        replyTo: replySnap,
        attachments: [att],
        e2eeEnvelope: outgoingEnvelope,
        messageIdOverride: msgIdOverride,
      );
      unawaited(RecentStickersStore.instance.addRecent(att));
      if (mounted) {
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        setState(() => _replyingTo = null);
        _scheduleAutoScrollToBottomIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chat_send_failed(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _sendChatPoll() async {
    if (_sendBusy) return;
    if (_editingMessageId != null) {
      _toast(AppLocalizations.of(context)!.chat_finish_editing_first);
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast(AppLocalizations.of(context)!.forward_error_not_authorized);
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast(AppLocalizations.of(context)!.chat_repository_unavailable);
      return;
    }
    final convAsync = ref.read(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final convList = convAsync.asData?.value;
    final conv = convList != null && convList.isNotEmpty
        ? convList.first
        : null;
    if (conv == null) {
      _toast(AppLocalizations.of(context)!.chat_still_loading);
      return;
    }
    final participantIds = conv.data.participantIds;
    if (participantIds.isEmpty) {
      _toast(AppLocalizations.of(context)!.chat_no_participants);
      return;
    }
    final payload = await showChatPollCreateSheet(context);
    if (!mounted || payload == null) return;
    setState(() => _sendBusy = true);
    try {
      await repo
          .sendChatPollMessage(
            conversationId: widget.conversationId,
            senderId: uid,
            participantIds: participantIds,
            pollPayload: payload,
            replyTo: _replyingTo,
          )
          .timeout(const Duration(seconds: 20));
      if (mounted) {
        unawaited(clearChatMessageDraft(uid, widget.conversationId));
        setState(() => _replyingTo = null);
        _scheduleAutoScrollToBottomIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        String message;
        if (e is TimeoutException) {
          message = AppLocalizations.of(context)!.chat_poll_send_timeout;
        } else if (raw.contains('poll_send_timeout:')) {
          message = AppLocalizations.of(context)!.chat_poll_send_timeout;
        } else if (raw.contains('poll_send_firebase:')) {
          final details = raw.split('poll_send_firebase:').last;
          message = AppLocalizations.of(
            context,
          )!.chat_poll_send_firebase(details);
        } else if (raw.contains('poll_send_error:')) {
          final details = raw.split('poll_send_error:').last;
          message = AppLocalizations.of(
            context,
          )!.chat_poll_send_known_error(details);
        } else {
          message = AppLocalizations.of(context)!.chat_poll_send_failed(e);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _handleComposerAttachment(
    ComposerAttachmentAction action,
  ) async {
    if (_editingMessageId != null) {
      _toast(AppLocalizations.of(context)!.chat_finish_editing_first);
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
              _scheduleChatDraftSave();
              break;
            case 'camera_photo':
              final x = await picker.pickImage(source: ImageSource.camera);
              if (!mounted || x == null) return;
              setState(() => _pendingAttachments.add(x));
              _scheduleChatDraftSave();
              break;
            case 'camera_video':
              final xv = await picker.pickVideo(source: ImageSource.camera);
              if (!mounted || xv == null) return;
              setState(() => _pendingAttachments.add(xv));
              _scheduleChatDraftSave();
              break;
            default:
              break;
          }
        } catch (e) {
          if (mounted) {
            _toast(AppLocalizations.of(context)!.chat_media_pick_failed(e));
          }
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
            _scheduleChatDraftSave();
          }
        } catch (e) {
          if (mounted) {
            _toast(AppLocalizations.of(context)!.chat_file_pick_failed(e));
          }
        }
        break;
      case ComposerAttachmentAction.clipboard:
        await _pasteContentFromClipboard();
        break;
      case ComposerAttachmentAction.videoCircle:
        unawaited(_openVideoCircleCapture());
        break;
      case ComposerAttachmentAction.location:
        unawaited(_sendLocationShare());
        break;
      case ComposerAttachmentAction.poll:
        unawaited(_sendChatPoll());
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

class _AnchorReactionTarget {
  const _AnchorReactionTarget({
    required this.emoji,
    required this.messageId,
    this.parentId,
  });

  final String emoji;
  final String messageId;
  final String? parentId;
}
