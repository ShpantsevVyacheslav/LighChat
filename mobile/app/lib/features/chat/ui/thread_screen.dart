import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';

import '../data/chat_media_gallery.dart';
import '../data/e2ee_decryption_orchestrator.dart';
import '../data/e2ee_attachment_send_helper.dart';
import '../data/e2ee_data_type_policy.dart';
import '../data/e2ee_plaintext_cache.dart';
import '../data/e2ee_runtime.dart';
import '../data/secret_chat_media_open_service.dart';

import '../data/chat_emoji_only.dart';
import '../data/chat_location_share_factory.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/chat_poll_stub_text.dart';
import '../data/pinned_messages_helper.dart';
import '../data/reply_preview_builder.dart';
import '../data/chat_attachment_upload.dart';
import '../data/chat_outbox_attachment_notifier.dart';
import 'message_context_menu.dart';
import 'report_sheet.dart';
import '../data/chat_message_search.dart';
import '../data/user_block_providers.dart';
import '../data/composer_clipboard_paste.dart';
import '../data/group_mention_candidates.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'chat_drag_drop_target.dart';
import 'chat_message_list.dart';
import 'chat_scroll_anchor_button.dart';
import 'chat_message_search_overlay.dart';
import 'chat_selection_app_bar.dart';
import 'composer_attachment_menu.dart';
import 'composer_sticker_gif_sheet.dart';
import 'composer_sticker_suggestion_row.dart';
import 'e2ee_mobile_block_banner.dart';
import 'message_attachments.dart';
import 'message_bubble_delivery_icons.dart';
import 'message_chat_poll.dart';
import 'message_deleted_stub.dart';
import '../data/composer_html_editing.dart';
import 'message_html_text.dart';
import 'message_location_card.dart';
import 'chat_media_viewer_screen.dart';
import 'chat_poll_create_sheet.dart';
import 'chat_wallpaper_background.dart';
import 'effective_chat_wallpaper.dart';
import 'chat_composer.dart';
import 'chat_document_open.dart';
import 'location_send_preview_sheet.dart';
import 'share_location_sheet.dart';
import 'thread_header.dart';
import 'video_circle_capture_page.dart';
import 'voice_message_record_sheet.dart';

Widget threadWallpaperBackdrop({
  required WidgetRef ref,
  required String userId,
  required String conversationId,
  required String? globalWallpaper,
  required Widget child,
}) {
  final repo = ref.read(chatSettingsRepositoryProvider);
  if (repo == null) {
    return ChatWallpaperBackground(
      wallpaper: resolveEffectiveChatWallpaper(
        globalChatWallpaper: globalWallpaper,
        conversationPrefs: const <String, dynamic>{},
      ),
      child: child,
    );
  }
  return StreamBuilder<Map<String, dynamic>>(
    stream: repo.watchChatConversationPrefs(
      userId: userId,
      conversationId: conversationId,
    ),
    initialData: const <String, dynamic>{},
    builder: (context, snap) {
      return ChatWallpaperBackground(
        wallpaper: resolveEffectiveChatWallpaper(
          globalChatWallpaper: globalWallpaper,
          conversationPrefs: snap.data ?? const <String, dynamic>{},
        ),
        child: child,
      );
    },
  );
}

class _AnchorReactionTarget {
  const _AnchorReactionTarget({required this.emoji, required this.messageId});

  final String emoji;
  final String messageId;
}

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({
    super.key,
    required this.conversationId,
    required this.parentMessageId,
    this.parentMessage,
    this.focusMessageId,
  });

  final String conversationId;
  final String parentMessageId;
  final ChatMessage? parentMessage;
  final String? focusMessageId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  /// Как в основном чате: новые ответы у нижнего края у композера.
  static const bool _threadMessageListReversed = true;

  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Map<String, GlobalKey> _messageItemKeys = <String, GlobalKey>{};
  final Set<String> _sessionReadIds = <String>{};
  final Map<String, DateTime> _pendingRetryAt = <String, DateTime>{};
  List<ChatMessage> _sortedAscCache = const <ChatMessage>[];
  List<ChatMessage> _hydratedThreadMsgsDescCache = const <ChatMessage>[];
  ChatMessage? _hydratedParentCache;
  DateTime _messageExpiryNow = DateTime.now();
  Timer? _messageExpiryTimer;
  String? _jumpScrollBoostMessageId;
  bool _threadAtBottom = true;
  int _anchorUnreadStep = 0;

  /// Паритет основного чата: разделитель не «едет» при прочитке в сессии.
  String? _sessionUnreadSeparatorAnchorMessageId;
  String _suppressThreadUnreadResetKey = '';

  /// Отложенное скрытие разделителя «Непрочитанные сообщения» — паритет с
  /// основным чатом и вебом: линия живёт ещё несколько секунд.
  Timer? _hideUnreadSeparatorTimer;
  static const Duration _kUnreadSeparatorLinger = Duration(seconds: 5);
  bool _sendBusy = false;
  bool _selectionBusy = false;
  bool _stickersPanelOpen = false;
  String _stickersSearchQuery = '';
  String _stickersSearchHint = '';
  String? _composerTextBeforeStickerSearch;
  bool _stickersSheetExpanded = false;
  bool _stickersPackManagerOpen = false;
  String? _pendingFocusMessageId;
  bool _inThreadSearch = false;
  bool _composerFormattingOpen = false;
  final List<XFile> _pendingAttachments = <XFile>[];
  final Set<String> _selectedMessageIds = <String>{};
  ReplyContext? _replyingTo;
  String? _flashHighlightMessageId;
  Timer? _flashHighlightTimer;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  void initState() {
    super.initState();
    _pendingFocusMessageId = widget.focusMessageId?.trim();
    if (_pendingFocusMessageId != null && _pendingFocusMessageId!.isEmpty) {
      _pendingFocusMessageId = null;
    }
    _composerFocus.addListener(_onComposerFocusChanged);
  }

  void _onComposerFocusChanged() {
    if (!mounted) return;
    _recomputeStickersExpanded();
  }

  void _recomputeStickersExpanded() {
    final shouldExpand =
        _stickersPanelOpen &&
        (_composerFocus.hasFocus || _stickersPackManagerOpen);
    if (_stickersSheetExpanded != shouldExpand) {
      setState(() => _stickersSheetExpanded = shouldExpand);
    }
  }

  @override
  void dispose() {
    _messageExpiryTimer?.cancel();
    _flashHighlightTimer?.cancel();
    _hideUnreadSeparatorTimer?.cancel();
    _scrollController.dispose();
    _composerController.dispose();
    _composerFocus.removeListener(_onComposerFocusChanged);
    _composerFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId ||
        oldWidget.parentMessageId != widget.parentMessageId) {
      _messageItemKeys.clear();
      _sortedAscCache = const <ChatMessage>[];
      _hydratedThreadMsgsDescCache = const <ChatMessage>[];
      _hydratedParentCache = null;
      _messageExpiryNow = DateTime.now();
      _messageExpiryTimer?.cancel();
      _jumpScrollBoostMessageId = null;
      _replyingTo = null;
      _flashHighlightTimer?.cancel();
      _flashHighlightMessageId = null;
      _threadAtBottom = true;
      _anchorUnreadStep = 0;
      _selectedMessageIds.clear();
      _selectionBusy = false;
      _sessionUnreadSeparatorAnchorMessageId = null;
      _hideUnreadSeparatorTimer?.cancel();
      _hideUnreadSeparatorTimer = null;
      _suppressThreadUnreadResetKey = '';
      _sessionReadIds.clear();
      _pendingFocusMessageId = widget.focusMessageId?.trim();
      if (_pendingFocusMessageId != null && _pendingFocusMessageId!.isEmpty) {
        _pendingFocusMessageId = null;
      }
      return;
    }
    if (oldWidget.focusMessageId != widget.focusMessageId) {
      _pendingFocusMessageId = widget.focusMessageId?.trim();
      if (_pendingFocusMessageId != null && _pendingFocusMessageId!.isEmpty) {
        _pendingFocusMessageId = null;
      }
    }
  }

  String _timeHm(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool _isIncomingUnreadForViewer(ChatMessage m, String viewerId) {
    // System timeline markers (E2EE state changes etc.) are informational and
    // must not appear as unread messages.
    if (m.senderId == '__system__' || m.systemEvent != null) return false;
    if (m.senderId == viewerId) return false;
    if (m.readAt != null) return false;
    final personal = m.readByUid?[viewerId];
    return personal == null;
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
      if (_sessionUnreadSeparatorAnchorMessageId != null &&
          _hideUnreadSeparatorTimer == null) {
        _hideUnreadSeparatorTimer = Timer(_kUnreadSeparatorLinger, () {
          if (!mounted) return;
          setState(() {
            _sessionUnreadSeparatorAnchorMessageId = null;
            _hideUnreadSeparatorTimer = null;
          });
        });
      }
      return;
    }
    _hideUnreadSeparatorTimer?.cancel();
    _hideUnreadSeparatorTimer = null;
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
        isThread: true,
        threadParentMessageId: widget.parentMessageId,
        skipReadReceipt: !allowReadReceipts,
      );
    } catch (_) {
      _sessionReadIds.remove(id);
    }
  }

  Future<void> _markManyUnreadAsRead({
    required String userId,
    required List<String> unreadIds,
    required bool allowReadReceipts,
  }) async {
    if (unreadIds.isEmpty) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final toMark = unreadIds
        .where((id) => !_sessionReadIds.contains(id))
        .toList(growable: false);
    if (toMark.isEmpty) return;
    _sessionReadIds.addAll(toMark);
    try {
      await repo.markManyMessagesAsRead(
        conversationId: widget.conversationId,
        userId: userId,
        messageIds: toMark,
        skipReadReceipt: !allowReadReceipts,
        isThread: true,
        threadParentMessageId: widget.parentMessageId,
      );
    } catch (_) {
      _sessionReadIds.removeAll(toMark);
    }
  }

  _AnchorReactionTarget? _latestAnchorReaction({
    required Conversation? conv,
    required String currentUserId,
  }) {
    if (conv == null) return null;
    final ts = (conv.lastReactionTimestamp ?? '').trim();
    final emoji = (conv.lastReactionEmoji ?? '').trim();
    final messageId = (conv.lastReactionMessageId ?? '').trim();
    if (ts.isEmpty || emoji.isEmpty || messageId.isEmpty) return null;
    if ((conv.lastReactionSenderId ?? '').trim() == currentUserId) return null;
    final seenAt = (conv.lastReactionSeenAt?[currentUserId] ?? '').trim();
    if (seenAt.isNotEmpty && ts.compareTo(seenAt) <= 0) return null;
    final parentId = (conv.lastReactionParentId ?? '').trim();
    if (parentId != widget.parentMessageId) return null;
    return _AnchorReactionTarget(emoji: emoji, messageId: messageId);
  }

  Future<void> _handleReactionAnchorTap({
    required _AnchorReactionTarget reaction,
    required String userId,
  }) async {
    _scrollToMessageId(reaction.messageId);
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 420));
    try {
      await repo.markReactionSeen(
        conversationId: widget.conversationId,
        userId: userId,
      );
    } catch (_) {}
  }

  void _consumePendingFocusIfReady(List<ChatMessage> sortedAsc) {
    final focusId = _pendingFocusMessageId;
    if (focusId == null || focusId.isEmpty) return;
    final exists = sortedAsc.any((m) => m.id == focusId);
    if (!exists) return;
    _pendingFocusMessageId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToMessageId(focusId);
    });
  }

  void _syncMessageItemKeys(List<ChatMessage> msgs) {
    final ids = msgs.map((m) => m.id).toSet();
    _messageItemKeys.removeWhere((id, _) => !ids.contains(id));
    for (final m in msgs) {
      _messageItemKeys.putIfAbsent(m.id, GlobalKey.new);
    }
  }

  Future<void> _animateToThreadBottom() async {
    if (!_scrollController.hasClients) return;
    final p = _scrollController.position;
    final target = _threadMessageListReversed
        ? p.minScrollExtent
        : p.maxScrollExtent;
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _scrollToMessageId(String messageId) {
    if (messageId.isEmpty) return;
    final idx = _sortedAscCache.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final sc = _scrollController;
    final n = _sortedAscCache.length;
    if (sc.hasClients && n > 1) {
      final max = sc.position.maxScrollExtent;
      if (max > 0) {
        final frac = idx / (n - 1);
        final raw = _threadMessageListReversed
            ? (max * (1 - frac))
            : (max * frac);
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
      tries += 1;
      final ctx = _messageItemKeys[messageId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.12,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
        setState(() => _jumpScrollBoostMessageId = null);
        return;
      }
      if (tries >= 24) {
        setState(() => _jumpScrollBoostMessageId = null);
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  void _onThreadAtBottomChanged(bool atBottom) {
    if (!mounted) return;
    if (_threadAtBottom == atBottom) return;
    setState(() {
      _threadAtBottom = atBottom;
      if (atBottom) {
        _anchorUnreadStep = 0;
      }
    });
  }

  void _openThreadSearch() {
    if (_inThreadSearch) return;
    setState(() => _inThreadSearch = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
    });
  }

  void _exitThreadSearch() {
    if (!_inThreadSearch) return;
    setState(() => _inThreadSearch = false);
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _closeThread(BuildContext context) {
    if (_selectedMessageIds.isNotEmpty) {
      setState(() => _selectedMessageIds.clear());
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats/${widget.conversationId}');
    }
  }

  void _insertThreadComposerTextAtCursor(String rawText) {
    final t = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (t.trim().isEmpty) return;
    final escaped = ComposerHtmlEditing.escapeHtmlText(t);
    final value = _composerController.value;
    final text = value.text;
    final sel = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    final next = text.replaceRange(start, end, escaped);
    _composerController.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: start + escaped.length),
      composing: TextRange.empty,
    );
  }

  void _handleDroppedFiles(List<XFile> files) {
    if (files.isEmpty || !mounted) return;
    setState(() => _pendingAttachments.addAll(files));
  }

  void _handleDroppedText(String text) {
    if (text.trim().isEmpty || !mounted) return;
    _insertThreadComposerTextAtCursor(text);
  }

  Future<void> _pasteContentFromClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final payload = await readComposerClipboardPayload();
      if (!mounted) return;
      if (payload.files.isNotEmpty) {
        setState(() => _pendingAttachments.addAll(payload.files));
      }
      final pastedText = payload.text ?? '';
      if (pastedText.trim().isNotEmpty) {
        _insertThreadComposerTextAtCursor(pastedText);
      }
      if (payload.files.isEmpty && pastedText.trim().isEmpty) {
        _toast(l10n.chat_clipboard_nothing_to_paste);
      }
    } catch (e) {
      final fallback = await Clipboard.getData(Clipboard.kTextPlain);
      final text = fallback?.text ?? '';
      if (!mounted) return;
      if (text.trim().isNotEmpty) {
        _insertThreadComposerTextAtCursor(text);
      } else {
        _toast(l10n.chat_clipboard_paste_failed(e));
      }
    }
  }

  Future<void> _sendThreadStickerOrGifAttachment(
    String uid,
    ChatRepository repo,
    ChatAttachment att,
  ) async {
    final policy = _resolveEffectiveE2eePolicyForThread(uid);
    final replySnap = _stripReplyPreviewByPolicy(_replyingTo, policy);
    setState(() => _sendBusy = true);
    try {
      final e2ee = _resolveMediaOnlyE2eeContextForThread(uid);
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
      await repo.sendThreadTextMessage(
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        senderId: uid,
        text: '',
        replyTo: replySnap,
        attachments: [att],
        e2eeEnvelope: outgoingEnvelope,
        messageIdOverride: msgIdOverride,
      );
      if (mounted) {
        setState(() => _replyingTo = null);
        unawaited(_animateToThreadBottom());
      }
    } catch (e) {
      if (mounted) {
        _toast(AppLocalizations.of(context)!.chat_send_failed(e));
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  void _openStickersGifPanel(String uid) {
    if (_sendBusy) return;
    final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    if (stickerRepo == null || chatRepo == null) {
      _toast(AppLocalizations.of(context)!.chat_service_unavailable);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) {
      setState(() {
        _composerTextBeforeStickerSearch = _composerController.text;
        _composerController.clear();
        _stickersSearchQuery = '';
        _stickersPanelOpen = true;
      });
    }
  }

  void _switchFromStickersToKeyboard() {
    if (!mounted) return;
    setState(() {
      _stickersPanelOpen = false;
      _composerController.text =
          _composerTextBeforeStickerSearch ?? _composerController.text;
      _composerController.selection = TextSelection.collapsed(
        offset: _composerController.text.length,
      );
      _composerTextBeforeStickerSearch = null;
      _stickersSearchQuery = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocus.requestFocus();
    });
  }

  Future<void> _deleteFileSilently(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _openVideoCircleCaptureThread(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast(AppLocalizations.of(context)!.chat_repository_unavailable);
      return;
    }
    await pushVideoCircleCapturePage(
      context,
      onSend: (raw) => _sendVideoCircleFileThread(uid, repo, raw),
    );
  }

  E2eeDataTypePolicy _resolveEffectiveE2eePolicyForThread(
    String uid, {
    Conversation? conv,
  }) {
    final userDoc =
        ref.read(userChatSettingsDocProvider(uid)).asData?.value ??
        const <String, dynamic>{};
    final rawPrivacy =
        userDoc['privacySettings'] as Map? ?? const <String, dynamic>{};
    final globalPolicy = E2eeDataTypePolicy.fromFirestore(
      rawPrivacy['e2eeEncryptedDataTypes'],
    );
    final effectiveConv =
        conv ??
        (() {
          final convAsync = ref.read(
            conversationsProvider((
              key: conversationIdsCacheKey([widget.conversationId]),
            )),
          );
          final convList = convAsync.asData?.value;
          return convList != null && convList.isNotEmpty
              ? convList.first.data
              : null;
        })();
    final overrideRaw = effectiveConv?.e2eeEncryptedDataTypesOverride;
    final overridePolicy = overrideRaw == null
        ? null
        : E2eeDataTypePolicy.fromFirestore(overrideRaw);
    final basePolicy = resolveE2eeEffectivePolicy(
      global: globalPolicy,
      override: overridePolicy,
    );
    if (isConversationE2eeActive(effectiveConv)) {
      return basePolicy.copyWith(text: true, media: true);
    }
    return basePolicy;
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
      text: null,
      mediaPreviewUrl: null,
    );
  }

  ({MobileE2eeRuntime runtime, int epoch, String messageId})?
  _resolveMediaOnlyE2eeContextForThread(String uid, {Conversation? conv}) {
    final effectiveConv =
        conv ??
        (() {
          final convAsync = ref.read(
            conversationsProvider((
              key: conversationIdsCacheKey([widget.conversationId]),
            )),
          );
          final convList = convAsync.asData?.value;
          return convList != null && convList.isNotEmpty
              ? convList.first.data
              : null;
        })();
    if (!isConversationE2eeActive(effectiveConv)) return null;
    final policy = _resolveEffectiveE2eePolicyForThread(
      uid,
      conv: effectiveConv,
    );
    if (!policy.media) return null;
    final runtime = ref.read(mobileE2eeRuntimeProvider);
    final epoch = effectiveConv?.e2eeKeyEpoch;
    if (runtime == null || epoch == null) return null;
    final reservedId = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(widget.parentMessageId)
        .collection('thread')
        .doc()
        .id;
    return (runtime: runtime, epoch: epoch, messageId: reservedId);
  }

  Future<void> _sendVideoCircleFileThread(
    String uid,
    ChatRepository repo,
    XFile raw,
  ) async {
    final lower = raw.path.toLowerCase();
    final ext = lower.endsWith('.mov') || lower.endsWith('.qt') ? 'mov' : 'mp4';
    final mime = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    final name = 'video-circle_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = XFile(raw.path, mimeType: mime);
    final replySnap = _replyingTo;
    setState(() => _sendBusy = true);
    try {
      final uploaded = await uploadChatAttachmentFromXFile(
        storage: FirebaseStorage.instance,
        conversationId: widget.conversationId,
        file: file,
        displayName: name,
      );
      await repo.sendThreadTextMessage(
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        senderId: uid,
        text: '',
        replyTo: replySnap,
        attachments: [uploaded],
      );
      if (mounted) {
        setState(() => _replyingTo = null);
        unawaited(_animateToThreadBottom());
      }
    } catch (e) {
      if (mounted) {
        _toast(AppLocalizations.of(context)!.chat_send_video_circle_failed(e));
      }
    } finally {
      unawaited(_deleteFileSilently(raw.path));
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _sendVoiceMessage(String uid, {Conversation? conv}) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _sendBusy) return;
    final rec = await showVoiceMessageRecordSheet(context);
    if (!mounted || rec == null) return;
    await _sendVoiceMessageFromRecord(uid, rec, conv: conv);
  }

  Future<void> _sendVoiceMessageFromRecord(
    String uid,
    VoiceMessageRecordResult rec, {
    Conversation? conv,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _sendBusy) return;
    setState(() => _sendBusy = true);
    try {
      final audioName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = XFile(rec.filePath, mimeType: 'audio/m4a');
      final policy = _resolveEffectiveE2eePolicyForThread(uid, conv: conv);
      final replySnap = _stripReplyPreviewByPolicy(_replyingTo, policy);
      final e2ee = _resolveMediaOnlyE2eeContextForThread(uid, conv: conv);
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
        await repo.sendThreadTextMessage(
          conversationId: widget.conversationId,
          parentMessageId: widget.parentMessageId,
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
          displayName: audioName,
        );
        await repo.sendThreadTextMessage(
          conversationId: widget.conversationId,
          parentMessageId: widget.parentMessageId,
          senderId: uid,
          text: '',
          replyTo: replySnap,
          attachments: [uploaded],
        );
      }
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _composerFormattingOpen = false;
        });
        _composerFocus.unfocus();
        unawaited(_animateToThreadBottom());
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

  Future<void> _sendLocationShareThread(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast(l10n.chat_repository_unavailable);
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
      _toast(l10n.chat_still_loading);
      return;
    }
    final participantIds = conv.data.participantIds;
    if (participantIds.isEmpty) {
      _toast(l10n.chat_no_participants);
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
          _toast(l10n.chat_location_ios_geolocator_missing);
        }
        return;
      }
      if (!serviceEnabled) {
        if (mounted) _toast(l10n.chat_location_services_disabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _toast(l10n.chat_location_permission_denied);
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

      await repo.sendThreadLocationShareMessage(
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        senderId: uid,
        participantIds: participantIds,
        locationShare: share,
        activateUserLiveShare: activate,
        userLiveExpiresAt: userLiveExp,
      );

      if (mounted) {
        _composerFocus.unfocus();
        unawaited(_animateToThreadBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chat_location_send_failed(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _sendChatPollThread(String uid) async {
    if (_sendBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _toast(l10n.chat_repository_unavailable);
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
      _toast(l10n.chat_still_loading);
      return;
    }
    final participantIds = conv.data.participantIds;
    if (participantIds.isEmpty) {
      _toast(l10n.chat_no_participants);
      return;
    }
    final payload = await showChatPollCreateSheet(context);
    if (!mounted || payload == null) return;
    setState(() => _sendBusy = true);
    try {
      await repo
          .sendThreadChatPollMessage(
            conversationId: widget.conversationId,
            parentMessageId: widget.parentMessageId,
            senderId: uid,
            participantIds: participantIds,
            pollPayload: payload,
          )
          .timeout(const Duration(seconds: 20));
      if (mounted) {
        _composerFocus.unfocus();
        unawaited(_animateToThreadBottom());
      }
    } catch (e) {
      if (!mounted) return;
      final raw = '$e';
      final String message;
      if (raw.contains('poll_send_timeout:')) {
        message = l10n.chat_poll_send_timeout;
      } else if (raw.contains('poll_send_firebase:')) {
        final details = raw.split('poll_send_firebase:').last;
        message = l10n.chat_poll_send_firebase(details);
      } else if (raw.contains('poll_send_error:')) {
        final details = raw.split('poll_send_error:').last;
        message = l10n.chat_poll_send_known_error(details);
      } else {
        message = l10n.chat_poll_send_failed(e);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _pickDeviceFiles() async {
    if (_sendBusy) return;
    final res = await FilePicker.pickFiles(allowMultiple: true);
    if (!mounted || res == null) return;
    final add = <XFile>[];
    for (final p in res.files) {
      final path = p.path;
      if (path == null || path.trim().isEmpty) continue;
      add.add(XFile(path, name: p.name));
    }
    if (add.isEmpty) return;
    setState(() => _pendingAttachments.addAll(add));
  }

  Future<void> _pickPhotoVideo() async {
    if (_sendBusy) return;
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (!mounted || files.isEmpty) return;
    setState(() => _pendingAttachments.addAll(files));
  }

  void _handleComposerAttachment(ComposerAttachmentAction action, String uid) {
    if (_sendBusy) return;
    switch (action) {
      case ComposerAttachmentAction.photoVideo:
        unawaited(_pickPhotoVideo());
        break;
      case ComposerAttachmentAction.deviceFiles:
        unawaited(_pickDeviceFiles());
        break;
      case ComposerAttachmentAction.stickersGif:
        _openStickersGifPanel(uid);
        break;
      case ComposerAttachmentAction.format:
        setState(() => _composerFormattingOpen = true);
        break;
      case ComposerAttachmentAction.clipboard:
        unawaited(_pasteContentFromClipboard());
        break;
      case ComposerAttachmentAction.videoCircle:
        unawaited(_openVideoCircleCaptureThread(uid));
        break;
      case ComposerAttachmentAction.location:
        unawaited(_sendLocationShareThread(uid));
        break;
      case ComposerAttachmentAction.poll:
        unawaited(_sendChatPollThread(uid));
        break;
    }
  }

  String _threadSenderLabel(
    String senderId,
    User user,
    Conversation? conv,
    AppLocalizations l10n,
  ) {
    if (senderId == user.uid) return l10n.chat_sender_you;
    final n = conv?.participantInfo?[senderId]?.name;
    if ((n ?? '').trim().isNotEmpty) return n!.trim();
    return l10n.forward_sender_fallback;
  }

  Future<bool> _confirmDeleteMessageInThread(ChatMessage m) async {
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
        threadParentMessageId: m.id == widget.parentMessageId
            ? null
            : widget.parentMessageId,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chat_delete_action_failed(e))),
        );
      }
      return false;
    }
  }

  Future<bool> _confirmDeleteMediaGalleryItemInThread(
    ChatMediaGalleryItem item,
  ) async {
    final m = item.message;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return false;
    final threadParent = m.id == widget.parentMessageId
        ? null
        : widget.parentMessageId;
    if (m.attachments.length <= 1) {
      return _confirmDeleteMessageInThread(m);
    }
    final l10n = AppLocalizations.of(context)!;
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
        threadParentMessageId: threadParent,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chat_delete_action_failed(e))),
        );
      }
      return false;
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

  Future<void> _toggleThreadMessageStar({
    required ChatMessage message,
    required String currentUserId,
    required bool isStarredNow,
  }) async {
    if (message.id.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final starRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('starredChatMessages')
        .doc(_starredDocId(widget.conversationId, message.id));
    try {
      if (isStarredNow) {
        await starRef.delete();
        if (mounted) _toast(l10n.chat_starred_removed);
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await starRef.set(<String, Object?>{
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

  Future<void> _pinThreadMessage({
    required ChatMessage message,
    required User user,
    required Conversation conversation,
    required Map<String, UserProfile> profileMap,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final l10n = AppLocalizations.of(context)!;
    final existing = conversationPinnedList(conversation);
    if (existing.any((p) => p.messageId == message.id)) {
      _toast(l10n.chat_pin_already_pinned);
      return;
    }
    if (existing.length >= maxPinnedMessages) {
      _toast(l10n.chat_pin_limit_reached(maxPinnedMessages));
      return;
    }
    String? otherUserId;
    String? otherUserName;
    if (!conversation.isGroup) {
      final others = conversation.participantIds
          .where((id) => id != user.uid)
          .toList(growable: false);
      if (others.isNotEmpty) {
        otherUserId = others.first;
        otherUserName = profileMap[otherUserId]?.name;
      }
    }
    final entry = buildPinnedMessageFromChatMessage(
      l10n: l10n,
      message: message,
      currentUserId: user.uid,
      isGroup: conversation.isGroup,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
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

  bool _isThreadMessageStalePending(ChatMessage m) {
    if (m.id.startsWith(kLocalOutboxMessageIdPrefix)) return false;
    if ((m.deliveryStatus ?? '') != 'sending') return false;
    final origin = _pendingRetryAt[m.id] ?? m.createdAt;
    return DateTime.now().difference(origin) >= const Duration(seconds: 30);
  }

  Future<void> _cancelStalePendingThreadMessage(ChatMessage m) async {
    _pendingRetryAt.remove(m.id);
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(widget.parentMessageId)
          .collection('thread')
          .doc(m.id)
          .delete();
    } catch (_) {}
  }

  List<ChatMessage> _selectedThreadMessages(List<ChatMessage> sortedAsc) {
    final byId = {for (final m in sortedAsc) m.id: m};
    return _selectedMessageIds
        .map((id) => byId[id])
        .whereType<ChatMessage>()
        .toList(growable: false);
  }

  bool _canDeleteSelectedThreadMessages(
    List<ChatMessage> sortedAsc,
    String uid,
  ) {
    if (_selectedMessageIds.isEmpty) return false;
    final byId = {for (final m in sortedAsc) m.id: m};
    for (final id in _selectedMessageIds) {
      final m = byId[id];
      if (m == null || m.senderId != uid || m.isDeleted) return false;
    }
    return true;
  }

  Future<void> _forwardSelectedThreadMessages() async {
    final selected = _selectedThreadMessages(
      _sortedAscCache,
    ).where((m) => !m.isDeleted).toList(growable: false);
    if (selected.isEmpty || !mounted) return;
    await context.push('/chats/forward', extra: selected);
    if (!mounted) return;
    setState(() => _selectedMessageIds.clear());
  }

  Future<void> _deleteSelectedThreadMessages({
    required String currentUserId,
  }) async {
    final targets = _selectedThreadMessages(
      _sortedAscCache,
    ).where((m) => m.senderId == currentUserId && !m.isDeleted).toList();
    if (targets.isEmpty) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
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
    setState(() => _selectionBusy = true);
    try {
      for (final m in targets) {
        await repo.softDeleteMessage(
          conversationId: widget.conversationId,
          messageId: m.id,
          threadParentMessageId: widget.parentMessageId,
        );
      }
      if (mounted) setState(() => _selectedMessageIds.clear());
    } catch (e) {
      if (mounted) _toast(l10n.chat_delete_action_failed(e));
    } finally {
      if (mounted) setState(() => _selectionBusy = false);
    }
  }

  Future<void> _onThreadMessageLongPress({
    required ChatMessage message,
    required User user,
    required Conversation? conversation,
    required Map<String, UserProfile> profileMap,
    required Set<String> starredMessageIds,
    required String fontSize,
    required Color? outgoingBubbleColor,
    required Color? incomingBubbleColor,
    String? e2eeDecryptedText,
    bool e2eeDecryptionFailed = false,
  }) async {
    final isOutboxFailed =
        message.id.startsWith(kLocalOutboxMessageIdPrefix) &&
        (message.deliveryStatus ?? '') == 'failed';
    final isStale = _isThreadMessageStalePending(message);
    if (isOutboxFailed || isStale) {
      final result = await showOutboxFailedContextMenu(
        context,
        message: message,
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
          if (isOutboxFailed) {
            handleOutboxRetry(ref, message.id);
          } else {
            setState(() => _pendingRetryAt[message.id] = DateTime.now());
          }
        case MessageMenuActionType.outboxCancel:
          if (isOutboxFailed) {
            unawaited(handleOutboxDismiss(ref, message.id));
          } else {
            unawaited(_cancelStalePendingThreadMessage(message));
          }
        default:
          break;
      }
      return;
    }

    final isMine = message.senderId == user.uid;
    final canDelete = isMine && !message.isDeleted;
    final menuTextSource =
        (e2eeDecryptedText ?? message.text ?? '').trim();
    final hasMenuText =
        menuTextSource.isNotEmpty &&
        (menuTextSource.contains('<')
            ? messageHtmlToPlainText(menuTextSource).trim().isNotEmpty
            : true);
    final secretRestrictions = conversation?.secretChat?.restrictions;
    final allowCopy = !(secretRestrictions?.noCopy == true);
    final allowForward = !(secretRestrictions?.noForward == true);

    final result = await showMessageContextMenu(
      context,
      message: message,
      isCurrentUser: isMine,
      hasText: hasMenuText,
      canEdit: false,
      canDelete: canDelete,
      allowCopy: allowCopy,
      allowForward: allowForward,
      showStarAction: !message.isDeleted,
      isStarred: starredMessageIds.contains(message.id),
      // Внутри ветки нельзя создавать вложенные ветки — скрываем «Обсуждение».
      showThreadAction: false,
      e2eeDecryptedText: e2eeDecryptedText,
      e2eeDecryptionFailed: e2eeDecryptionFailed,
      chatFontSize: fontSize,
      outgoingBubbleColor: outgoingBubbleColor,
      incomingBubbleColor: incomingBubbleColor,
    );
    if (!mounted ||
        result == null ||
        result.type == MessageMenuActionType.dismissed) {
      return;
    }

    String? dmOtherId;
    if (conversation != null && !conversation.isGroup) {
      final others = conversation.participantIds
          .where((id) => id != user.uid)
          .toList(growable: false);
      dmOtherId = others.isEmpty ? null : others.first;
    }
    final dmOtherProfile = dmOtherId == null ? null : profileMap[dmOtherId];

    switch (result.type) {
      case MessageMenuActionType.dismissed:
        return;
      case MessageMenuActionType.reply:
        setState(() {
          _replyingTo = buildReplyPreview(
            l10n: AppLocalizations.of(context)!,
            message: message,
            currentUserId: user.uid,
            isGroup: conversation?.isGroup ?? false,
            otherUserId: dmOtherId,
            otherUserName: dmOtherProfile?.name,
          );
        });
        _composerFocus.requestFocus();
      case MessageMenuActionType.thread:
        context.push(
          '/chats/${widget.conversationId}/thread/${message.id}',
          extra: message,
        );
      case MessageMenuActionType.copy:
        if (!allowCopy) {
          _toast(AppLocalizations.of(context)!.secret_chat_action_not_allowed);
          return;
        }
        await copyMessageTextToClipboard(message);
        if (mounted) _toast(AppLocalizations.of(context)!.chat_text_copied);
      case MessageMenuActionType.edit:
        _toast(AppLocalizations.of(context)!.common_soon);
      case MessageMenuActionType.pin:
        if (conversation != null) {
          await _pinThreadMessage(
            message: message,
            user: user,
            conversation: conversation,
            profileMap: profileMap,
          );
        }
      case MessageMenuActionType.star:
        await _toggleThreadMessageStar(
          message: message,
          currentUserId: user.uid,
          isStarredNow: starredMessageIds.contains(message.id),
        );
      case MessageMenuActionType.forward:
        if (!allowForward) {
          _toast(AppLocalizations.of(context)!.secret_chat_action_not_allowed);
          return;
        }
        if (!message.isDeleted) {
          context.push('/chats/forward', extra: <ChatMessage>[message]);
        }
      case MessageMenuActionType.select:
        setState(() => _selectedMessageIds.add(message.id));
      case MessageMenuActionType.delete:
        await _confirmDeleteMessageInThread(message);
      case MessageMenuActionType.react:
        final emoji = result.emoji;
        if (emoji == null || emoji.trim().isEmpty || message.isDeleted) return;
        final repo = ref.read(chatRepositoryProvider);
        if (repo == null) return;
        try {
          await repo.toggleThreadMessageReaction(
            conversationId: widget.conversationId,
            parentMessageId: widget.parentMessageId,
            messageId: message.id,
            userId: user.uid,
            emoji: emoji.trim(),
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
      case MessageMenuActionType.report:
        if (!mounted) return;
        // ignore: use_build_context_synchronously — mounted checked above
        await showReportSheet(
          context,
          reportedUserId: message.senderId,
          messageId: message.id,
          conversationId: widget.conversationId,
        );
    }
  }

  void _openThreadMediaGallery(
    ChatAttachment att,
    ChatMessage msg, {
    required ChatMessage parent,
    required List<ChatMessage> threadMsgsDesc,
    required User user,
    required Conversation? conv,
  }) {
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
          await Navigator.of(context).push<void>(
            chatMediaViewerPageRoute<void>(
              ChatMediaViewerScreen(
                items: [
                  ChatMediaGalleryItem(attachment: resolved, message: msg),
                ],
                initialIndex: 0,
                conversationId: widget.conversationId,
                currentUserId: user.uid,
                senderLabel: (sid) => _threadSenderLabel(sid, user, conv, l10n),
                onReply: null,
                onForward: (_) {},
                allowForward: false,
                allowSave: false,
                allowExternalShare: false,
                onDeleteItem: _confirmDeleteMediaGalleryItemInThread,
                onShowInChat: (galleryItem) {
                  _scrollToMessageId(galleryItem.message.id);
                },
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.secret_chat_unlock_failed)),
          );
        }
      }());
      return;
    }
    final ascReplies = List<ChatMessage>.from(threadMsgsDesc)
      ..sort((a, b) {
        final t = a.createdAt.compareTo(b.createdAt);
        if (t != 0) return t;
        return a.id.compareTo(b.id);
      });
    final messages = <ChatMessage>[parent, ...ascReplies];
    final items = collectChatMediaGalleryItems(messages);
    if (items.isEmpty) return;
    final ix = indexInChatMediaGallery(items, att.url);
    Navigator.of(context).push<void>(
      chatMediaViewerPageRoute<void>(
        ChatMediaViewerScreen(
          items: items,
          initialIndex: ix,
          conversationId: widget.conversationId,
          currentUserId: user.uid,
          senderLabel: (sid) => _threadSenderLabel(
            sid,
            user,
            conv,
            AppLocalizations.of(context)!,
          ),
          onReply: null,
          onForward: (galleryItem) {
            if (galleryItem.message.isDeleted) return;
            final m = chatMessageForSingleAttachmentForward(
              galleryItem.message,
              galleryItem.attachment,
            );
            context.push('/chats/forward', extra: <ChatMessage>[m]);
          },
          onDeleteItem: _confirmDeleteMediaGalleryItemInThread,
          onShowInChat: (galleryItem) {
            _scrollToMessageId(galleryItem.message.id);
          },
        ),
      ),
    );
  }

  Future<void> _openThreadFileAttachment(
    ChatAttachment att,
    ChatMessage msg, {
    required Conversation? conv,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var target = att;
    final isSecret = conv?.secretChat?.enabled == true;
    if (isSecret && SecretChatMediaOpenService.isLockedSecretAttachment(att)) {
      final rt = ref.read(mobileE2eeRuntimeProvider);
      if (rt == null) return;
      try {
        target = await const SecretChatMediaOpenService().openForView(
          runtime: rt,
          conversationId: widget.conversationId,
          message: msg,
          lockedAttachment: att,
        );
      } catch (_) {
        if (!mounted) return;
        _toast(l10n.secret_chat_unlock_failed);
        return;
      }
    }
    if (!mounted) return;
    final opened = await openChatDocumentAttachment(context, target);
    if (opened) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.secret_chat_unlock_failed)),
    );
  }

  Future<void> _submitWithAttachments(String uid, [Conversation? conv]) async {
    if (_sendBusy) return;
    final rawComposer = _composerController.text;

    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      rawComposer,
    );
    final plain = prepared.isEmpty
        ? ''
        : messageHtmlToPlainText(prepared).trim();

    final pending = List<XFile>.from(_pendingAttachments);
    if (plain.isEmpty && pending.isEmpty) return;

    final e2eePolicy = _resolveEffectiveE2eePolicyForThread(uid, conv: conv);
    final replySnap = _stripReplyPreviewByPolicy(_replyingTo, e2eePolicy);
    if (pending.isNotEmpty) {
      final restoreReply = _replyingTo;
      final restoreFormatting = _composerFormattingOpen;
      setState(() {
        _composerController.clear();
        _pendingAttachments.clear();
        _replyingTo = null;
        _composerFormattingOpen = false;
      });
      try {
        await ref
            .read(chatOutboxAttachmentNotifierProvider.notifier)
            .enqueueFromComposer(
              conversationId: widget.conversationId,
              senderId: uid,
              files: pending,
              rawCaptionHtml: prepared,
              replyTo: replySnap,
              convIsE2ee: isConversationE2eeActive(conv),
              e2eeEncryptText: e2eePolicy.text,
              e2eeEncryptMedia: e2eePolicy.media,
              e2eeEpoch: conv?.e2eeKeyEpoch,
              threadParentMessageId: widget.parentMessageId,
            );
      } catch (e) {
        if (mounted) {
          setState(() {
            _composerController.text = rawComposer;
            _pendingAttachments
              ..clear()
              ..addAll(pending);
            _replyingTo = restoreReply;
            _composerFormattingOpen = restoreFormatting;
          });
          _toast(AppLocalizations.of(context)!.chat_send_failed(e));
        }
        return;
      }
      if (mounted) {
        _composerFocus.unfocus();
        unawaited(_animateToThreadBottom());
      }
      return;
    }

    setState(() => _sendBusy = true);
    try {
      await ref
          .read(chatOutboxAttachmentNotifierProvider.notifier)
          .enqueueFromComposer(
            conversationId: widget.conversationId,
            senderId: uid,
            files: pending,
            rawCaptionHtml: prepared,
            replyTo: replySnap,
            convIsE2ee: isConversationE2eeActive(conv),
            e2eeEncryptText: e2eePolicy.text,
            e2eeEncryptMedia: e2eePolicy.media,
            e2eeEpoch: conv?.e2eeKeyEpoch,
            threadParentMessageId: widget.parentMessageId,
          );
      if (mounted) {
        setState(() {
          _composerController.clear();
          _pendingAttachments.clear();
          _replyingTo = null;
          _composerFormattingOpen = false;
        });
        _composerFocus.unfocus();
        unawaited(_animateToThreadBottom());
      }
    } finally {
      if (mounted) setState(() => _sendBusy = false);
    }
  }

  Future<void> _retryMediaNormForThread(
    ChatMessage message, {
    required String parentMessageId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(chatRepositoryProvider);
      if (repo == null) return;
      await repo.retryChatMediaTranscode(
        conversationId: widget.conversationId,
        messageId: message.id,
        isThread: true,
        parentMessageId: parentMessageId,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.forward_error_not_authorized)),
      );
    }

    ChatMessage? initial = widget.parentMessage;
    if (initial != null && initial.id != widget.parentMessageId) {
      initial = null;
    }

    final parentAsync = initial != null
        ? AsyncValue<ChatMessage?>.data(initial)
        : ref.watch(
            chatMessageByIdProvider((
              conversationId: widget.conversationId,
              messageId: widget.parentMessageId,
            )),
          );

    final convAsync = ref.watch(
      conversationsProvider((
        key: conversationIdsCacheKey([widget.conversationId]),
      )),
    );
    final conv = convAsync.asData?.value.isNotEmpty == true
        ? convAsync.asData!.value.first.data
        : null;
    final contactsAsync = ref.watch(userContactsIndexProvider(user.uid));
    final starredIdsAsync = ref.watch(
      starredMessageIdsInConversationProvider((
        userId: user.uid,
        conversationId: widget.conversationId,
      )),
    );

    final userDocAsync = ref.watch(userChatSettingsDocProvider(user.uid));
    final userDoc = userDocAsync.asData?.value ?? const <String, dynamic>{};
    final rawChatSettings = Map<String, dynamic>.from(
      userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
    );
    final rawPrivacySettings = Map<String, dynamic>.from(
      userDoc['privacySettings'] as Map? ?? const <String, dynamic>{},
    );
    final allowReadReceipts = rawPrivacySettings['showReadReceipts'] != false;
    final wallpaper = rawChatSettings['chatWallpaper'] as String?;

    final threadAsync = ref.watch(
      threadMessagesProvider((
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        limit: 200,
      )),
    );

    final topUnderAppBar = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return ChatDragDropTarget(
      onFilesDropped: _handleDroppedFiles,
      onTextDropped: _handleDroppedText,
      child: parentAsync.when(
        loading: () => Scaffold(
          extendBodyBehindAppBar: true,
          body: threadWallpaperBackdrop(
            ref: ref,
            userId: user.uid,
            conversationId: widget.conversationId,
            globalWallpaper: wallpaper,
            child: Column(
              children: [
                SizedBox(height: topUnderAppBar),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
        error: (e, _) => Scaffold(
          extendBodyBehindAppBar: true,
          body: threadWallpaperBackdrop(
            ref: ref,
            userId: user.uid,
            conversationId: widget.conversationId,
            globalWallpaper: wallpaper,
            child: Column(
              children: [
                SizedBox(height: topUnderAppBar),
                Expanded(
                  child: Center(child: Text(l10n.chat_parent_load_error(e))),
                ),
              ],
            ),
          ),
        ),
        data: (parent) {
          if (parent == null || parent.isDeleted) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              body: threadWallpaperBackdrop(
                ref: ref,
                userId: user.uid,
                conversationId: widget.conversationId,
                globalWallpaper: wallpaper,
                child: Column(
                  children: [
                    SizedBox(height: topUnderAppBar),
                    Expanded(
                      child: Center(child: Text(l10n.thread_message_not_found)),
                    ),
                  ],
                ),
              ),
            );
          }

          final outboxJobs = ref.watch(chatOutboxAttachmentNotifierProvider);
          final replyCount = parent.threadCount ?? 0;
          final convTitle = (conv?.name ?? '').trim();
          final headerTitle = convTitle.isNotEmpty
              ? convTitle
              : l10n.thread_screen_title_fallback;
          final headerSubtitle =
              '${l10n.thread_reply_count(replyCount).toUpperCase()} · ${_timeHm(parent.createdAt)}';
          final selectionMode = _selectedMessageIds.isNotEmpty;
          final canDeleteSelected = _canDeleteSelectedThreadMessages(
            _sortedAscCache,
            user.uid,
          );

          return Scaffold(
            extendBodyBehindAppBar: true,
            body: threadWallpaperBackdrop(
              ref: ref,
              userId: user.uid,
              conversationId: widget.conversationId,
              globalWallpaper: wallpaper,
              child: Column(
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: SafeArea(
                      bottom: false,
                      child: selectionMode
                          ? ChatSelectionAppBar(
                              count: _selectedMessageIds.length,
                              onClose: () =>
                                  setState(() => _selectedMessageIds.clear()),
                              onForward: () =>
                                  unawaited(_forwardSelectedThreadMessages()),
                              onDelete: () => unawaited(
                                _deleteSelectedThreadMessages(
                                  currentUserId: user.uid,
                                ),
                              ),
                              canDelete: canDeleteSelected,
                              isBusy: _selectionBusy,
                            )
                          : ThreadHeader(
                              title: headerTitle,
                              subtitle: headerSubtitle,
                              onClose: () => _closeThread(context),
                              searchActive: _inThreadSearch,
                              onSearchTap: _openThreadSearch,
                              searchController: _searchController,
                              searchFocusNode: _searchFocus,
                              onSearchClose: _exitThreadSearch,
                            ),
                    ),
                  ),
                  Expanded(
                    child: threadAsync.when(
                      data: (threadMsgs) {
                        _scheduleMessageExpiryRefresh(threadMsgs);
                        final visibleThreadMsgs = _filterExpiredMessages(
                          threadMsgs,
                        );
                        final sortedAsc =
                            List<ChatMessage>.from(visibleThreadMsgs)
                              ..sort((a, b) {
                                final t = a.createdAt.compareTo(b.createdAt);
                                if (t != 0) return t;
                                return a.id.compareTo(b.id);
                              });
                        _sortedAscCache = sortedAsc;
                        _hydratedThreadMsgsDescCache = const <ChatMessage>[];
                        _syncMessageItemKeys(sortedAsc);
                        _consumePendingFocusIfReady(sortedAsc);
                        final loadedIncomingUnreadCount =
                            _loadedIncomingUnreadCount(sortedAsc, user.uid);
                        final loadedIncomingUnreadIds = _incomingUnreadIds(
                          sortedAsc,
                          user.uid,
                        );
                        if (!allowReadReceipts) {
                          final suppressKey =
                              '${widget.parentMessageId}:$loadedIncomingUnreadCount';
                          if (loadedIncomingUnreadCount > 0 &&
                              _suppressThreadUnreadResetKey != suppressKey) {
                            _suppressThreadUnreadResetKey = suppressKey;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              unawaited(
                                _markManyUnreadAsRead(
                                  userId: user.uid,
                                  unreadIds: loadedIncomingUnreadIds,
                                  allowReadReceipts: false,
                                ),
                              );
                            });
                          } else if (loadedIncomingUnreadCount == 0 &&
                              _suppressThreadUnreadResetKey.isNotEmpty) {
                            _suppressThreadUnreadResetKey = '';
                          }
                        } else if (_suppressThreadUnreadResetKey.isNotEmpty) {
                          _suppressThreadUnreadResetKey = '';
                        }
                        _syncSessionUnreadSeparatorAnchor(
                          sortedAsc: sortedAsc,
                          viewerId: user.uid,
                        );
                        final unreadSeparatorMessageId =
                            _sessionUnreadSeparatorAnchorMessageId;
                        final serverUnreadCount =
                            parent.unreadThreadCounts?[user.uid] ?? 0;
                        final unreadBadgeCount = loadedIncomingUnreadCount > 0
                            ? loadedIncomingUnreadCount
                            : serverUnreadCount;
                        final latestReaction = _latestAnchorReaction(
                          conv: conv,
                          currentUserId: user.uid,
                        );
                        final showScrollAnchor =
                            latestReaction != null ||
                            !_threadAtBottom ||
                            unreadBadgeCount > 0;
                        if (loadedIncomingUnreadCount == 0 &&
                            _anchorUnreadStep != 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted || _anchorUnreadStep == 0) return;
                            setState(() => _anchorUnreadStep = 0);
                          });
                        }

                        void onAnchorTap() {
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
                              unreadBadgeCount > 0 &&
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
                          unawaited(_animateToThreadBottom());
                          unawaited(
                            _markManyUnreadAsRead(
                              userId: user.uid,
                              unreadIds: loadedIncomingUnreadIds,
                              allowReadReceipts: allowReadReceipts,
                            ),
                          );
                        }

                        final profileMap = <String, UserProfile>{};
                        final pi = conv?.participantInfo;
                        if (pi != null) {
                          for (final e in pi.entries) {
                            final id = e.key.trim();
                            final info = e.value;
                            if (id.isEmpty) continue;
                            profileMap[id] = UserProfile(
                              id: id,
                              name: info.name,
                              avatar: info.avatar,
                              avatarThumb: info.avatarThumb,
                            );
                          }
                        }
                        final contactProfiles =
                            contactsAsync.value?.contactProfiles ??
                            const <String, ContactLocalProfile>{};

                        // Расшифрованный текст E2EE-сообщений из persistent
                        // кэша. Без него `m.text` пуст и поиск всегда возвращал
                        // 0 результатов в зашифрованном треде.
                        final threadSearchDecryptedMap = <String, String>{};
                        if (_inThreadSearch) {
                          for (final m in sortedAsc) {
                            if (m.e2eePayload == null) continue;
                            final cached = E2eePlaintextCache.instance
                                .getTextSync(
                                  conversationId: widget.conversationId,
                                  messageId: m.id,
                                );
                            if (cached != null && cached.isNotEmpty) {
                              threadSearchDecryptedMap[m.id] = cached;
                            }
                          }
                        }
                        final searchResults = _inThreadSearch
                            ? filterMessagesForInChatSearch(
                                sortedAsc,
                                _searchController.text,
                                decryptedTextByMessageId:
                                    threadSearchDecryptedMap,
                              )
                            : const <ChatMessage>[];
                        final starredMessageIds =
                            starredIdsAsync.asData?.value ?? const <String>{};
                        final selectionMode = _selectedMessageIds.isNotEmpty;

                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              E2eeMessagesResolver(
                                conversationId: widget.conversationId,
                                secretChat: conv?.secretChat,
                                messages: <ChatMessage>[parent],
                                builder:
                                    (
                                      context,
                                      hydratedParentList,
                                      parentDecryptedMap,
                                      parentFailedIds,
                                    ) {
                                      final hydratedParent =
                                          hydratedParentList.isNotEmpty
                                          ? hydratedParentList.first
                                          : parent;
                                      _hydratedParentCache = hydratedParent;
                                      final sourceReplies =
                                          _hydratedThreadMsgsDescCache
                                              .isNotEmpty
                                          ? _hydratedThreadMsgsDescCache
                                          : visibleThreadMsgs;
                                      return _ThreadRootPanel(
                                        message: hydratedParent,
                                        currentUserId: user.uid,
                                        conversationId: widget.conversationId,
                                        conversation: conv,
                                        replyCount: replyCount,
                                        timeHmText: _timeHm(parent.createdAt),
                                        outgoingBubbleColor: scheme.primary,
                                        incomingBubbleColor: Colors.white
                                            .withValues(
                                              alpha:
                                                  scheme.brightness ==
                                                      Brightness.dark
                                                  ? 0.08
                                                  : 0.22,
                                            ),
                                        e2eeDecryptedText:
                                            parentDecryptedMap[hydratedParent
                                                .id],
                                        e2eeDecryptionFailed: parentFailedIds
                                            .contains(hydratedParent.id),
                                        onOpenMediaGallery: (att) {
                                          _openThreadMediaGallery(
                                            att,
                                            hydratedParent,
                                            parent: hydratedParent,
                                            threadMsgsDesc: sourceReplies,
                                            user: user,
                                            conv: conv,
                                          );
                                        },
                                      );
                                    },
                              ),
                              Expanded(
                                flex: _stickersSheetExpanded ? 0 : 1,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: E2eeMessagesResolver(
                                        conversationId: widget.conversationId,
                                        secretChat: conv?.secretChat,
                                        messages: visibleThreadMsgs,
                                        builder:
                                            (
                                              context,
                                              hydratedThreadMsgs,
                                              e2eeDecryptedMap,
                                              e2eeFailedIds,
                                            ) {
                                              _hydratedThreadMsgsDescCache =
                                                  hydratedThreadMsgs;
                                              final hydratedParentForGallery =
                                                  _hydratedParentCache ??
                                                  parent;
                                              return ChatMessageList(
                                                messagesDesc:
                                                    buildDescWithOutboxMessages(
                                                      hydratedDesc:
                                                          hydratedThreadMsgs,
                                                      jobs: outboxJobs,
                                                      conversationId:
                                                          widget.conversationId,
                                                      senderId: user.uid,
                                                      threadParentMessageId:
                                                          widget
                                                              .parentMessageId,
                                                    ),
                                                currentUserId: user.uid,
                                                conversationId:
                                                    widget.conversationId,
                                                e2eeDecryptedTextByMessageId:
                                                    e2eeDecryptedMap,
                                                e2eeDecryptionFailedMessageIds:
                                                    e2eeFailedIds,
                                                reversed:
                                                    _threadMessageListReversed,
                                                conversation: conv,
                                                scrollController:
                                                    _scrollController,
                                                unreadSeparatorMessageId:
                                                    unreadSeparatorMessageId,
                                                onAtBottomChanged:
                                                    _onThreadAtBottomChanged,
                                                onMessageVisible: (message, _) {
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
                                                selectionMode: selectionMode,
                                                selectedMessageIds:
                                                    _selectedMessageIds,
                                                onMessageTap: (msg) {
                                                  if (!selectionMode) return;
                                                  setState(() {
                                                    if (_selectedMessageIds
                                                        .contains(msg.id)) {
                                                      _selectedMessageIds
                                                          .remove(msg.id);
                                                    } else {
                                                      _selectedMessageIds.add(
                                                        msg.id,
                                                      );
                                                    }
                                                  });
                                                },
                                                showTimestamps: true,
                                                fontSize: 'medium',
                                                bubbleRadius: 'rounded',
                                                outgoingBubbleColor:
                                                    scheme.primary,
                                                incomingBubbleColor: Colors
                                                    .white
                                                    .withValues(
                                                      alpha:
                                                          scheme.brightness ==
                                                              Brightness.dark
                                                          ? 0.08
                                                          : 0.22,
                                                    ),
                                                onOpenMediaGallery: (att, m) {
                                                  _openThreadMediaGallery(
                                                    att,
                                                    m,
                                                    parent:
                                                        hydratedParentForGallery,
                                                    threadMsgsDesc:
                                                        hydratedThreadMsgs,
                                                    user: user,
                                                    conv: conv,
                                                  );
                                                },
                                                onOpenFileAttachment: (att, m) {
                                                  unawaited(
                                                    _openThreadFileAttachment(
                                                      att,
                                                      m,
                                                      conv: conv,
                                                    ),
                                                  );
                                                },
                                                onRetryMediaNorm: (message) =>
                                                    _retryMediaNormForThread(
                                                      message,
                                                      parentMessageId:
                                                          parent.id,
                                                    ),
                                                onToggleReaction: (m, emoji) async {
                                                  final repo = ref.read(
                                                    chatRepositoryProvider,
                                                  );
                                                  if (repo == null ||
                                                      emoji.trim().isEmpty ||
                                                      m.isDeleted) {
                                                    return;
                                                  }
                                                  try {
                                                    await repo
                                                        .toggleThreadMessageReaction(
                                                          conversationId: widget
                                                              .conversationId,
                                                          parentMessageId: widget
                                                              .parentMessageId,
                                                          messageId: m.id,
                                                          userId: user.uid,
                                                          emoji: emoji.trim(),
                                                        );
                                                  } catch (e) {
                                                    if (!context.mounted) {
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
                                                profileMap: profileMap,
                                                contactProfiles:
                                                    contactProfiles,
                                                flashHighlightMessageId:
                                                    _flashHighlightMessageId,
                                                onSwipeReply: (m) {
                                                  if (_sendBusy) return;
                                                  final c = conv;
                                                  String? dmOtherId;
                                                  if (c != null && !c.isGroup) {
                                                    final others = c
                                                        .participantIds
                                                        .where(
                                                          (id) =>
                                                              id != user.uid,
                                                        )
                                                        .toList();
                                                    dmOtherId = others.isEmpty
                                                        ? null
                                                        : others.first;
                                                  }
                                                  final p = dmOtherId != null
                                                      ? profileMap[dmOtherId]
                                                      : null;
                                                  setState(() {
                                                    _replyingTo =
                                                        buildReplyPreview(
                                                          l10n:
                                                              AppLocalizations.of(
                                                                context,
                                                              )!,
                                                          message: m,
                                                          currentUserId:
                                                              user.uid,
                                                          isGroup:
                                                              c?.isGroup ??
                                                              false,
                                                          otherUserId:
                                                              dmOtherId,
                                                          otherUserName:
                                                              p?.name,
                                                        );
                                                  });
                                                  _composerFocus.requestFocus();
                                                },
                                                onSwipeBack: () {
                                                  if (context.canPop()) {
                                                    context.pop();
                                                  }
                                                },
                                                onMessageLongPress: (m) async {
                                                  await _onThreadMessageLongPress(
                                                    message: m,
                                                    user: user,
                                                    conversation: conv,
                                                    profileMap: profileMap,
                                                    starredMessageIds:
                                                        starredMessageIds,
                                                    fontSize: 'medium',
                                                    outgoingBubbleColor:
                                                        scheme.primary,
                                                    incomingBubbleColor: Colors
                                                        .white
                                                        .withValues(
                                                          alpha:
                                                              scheme.brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? 0.08
                                                              : 0.22,
                                                        ),
                                                    e2eeDecryptedText:
                                                        e2eeDecryptedMap[m.id],
                                                    e2eeDecryptionFailed:
                                                        e2eeFailedIds.contains(
                                                          m.id,
                                                        ),
                                                  );
                                                },
                                                onOutboxRetry: (mid) {
                                                  handleOutboxRetry(ref, mid);
                                                },
                                                onOutboxDismiss: (mid) {
                                                  unawaited(
                                                    handleOutboxDismiss(
                                                      ref,
                                                      mid,
                                                    ),
                                                  );
                                                },
                                                pendingRetryAt: _pendingRetryAt,
                                              );
                                            },
                                      ),
                                    ),
                                    if (_inThreadSearch)
                                      Positioned.fill(
                                        child: ChatMessageSearchOverlay(
                                          results: searchResults,
                                          conversation: conv,
                                          profileMap: profileMap,
                                          decryptedTextByMessageId:
                                              threadSearchDecryptedMap,
                                          onSelectMessageId: (id) {
                                            _exitThreadSearch();
                                            _scrollToMessageId(id);
                                          },
                                          onTapScrim: _exitThreadSearch,
                                        ),
                                      ),
                                    Positioned(
                                      right: 12,
                                      bottom: 12,
                                      child: ChatScrollAnchorButton(
                                        isVisible: showScrollAnchor,
                                        unreadCount: unreadBadgeCount,
                                        reactionEmoji: latestReaction?.emoji,
                                        onReactionTap: latestReaction == null
                                            ? null
                                            : () {
                                                unawaited(
                                                  _handleReactionAnchorTap(
                                                    reaction: latestReaction,
                                                    userId: user.uid,
                                                  ),
                                                );
                                              },
                                        onTap: onAnchorTap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedMessageIds.isEmpty)
                                ChatComposer(
                                  controller: _composerController,
                                  focusNode: _composerFocus,
                                  stickersPanelOpen: _stickersPanelOpen,
                                  onKeyboardTap: _switchFromStickersToKeyboard,
                                  stickersSearchHint: _stickersSearchHint,
                                  onStickersSearchChanged: (q) {
                                    if (!mounted) return;
                                    setState(() => _stickersSearchQuery = q);
                                  },
                                  e2eeDisabledBanner: dmComposerBlockBanner(
                                    context: context,
                                    ref: ref,
                                    currentUserId: user.uid,
                                    conv: conv,
                                  ),
                                  // Phase 4: текст в E2EE-threads уходит
                                  // зашифрованным; attachments по-прежнему
                                  // блокируются Phase 0 guard'ом репозитория
                                  // (Phase 7 уберёт этот барьер).
                                  onSend: () =>
                                      _submitWithAttachments(user.uid, conv),
                                  groupMentionCandidates:
                                      conv != null && conv.isGroup
                                      ? buildGroupMentionCandidates(
                                          conversation: conv,
                                          currentUserId: user.uid,
                                          profileMap: profileMap,
                                          contactProfiles: contactProfiles,
                                          l10n: AppLocalizations.of(context),
                                        )
                                      : null,
                                  onAttachmentSelected: (a) =>
                                      _handleComposerAttachment(a, user.uid),
                                  pendingAttachments: _pendingAttachments,
                                  onRemovePending: (i) {
                                    setState(
                                      () => _pendingAttachments.removeAt(i),
                                    );
                                  },
                                  onEditPending: (_) async {},
                                  attachmentsEnabled: !_sendBusy,
                                  sendBusy: _sendBusy,
                                  onMicTap: () => unawaited(
                                    _sendVoiceMessage(user.uid, conv: conv),
                                  ),
                                  onVoiceHoldRecorded: (rec) async {
                                    await _sendVoiceMessageFromRecord(
                                      user.uid,
                                      rec,
                                      conv: conv,
                                    );
                                  },
                                  onStickersTap: () =>
                                      _openStickersGifPanel(user.uid),
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
                                        _sendThreadStickerOrGifAttachment(
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
                                  replyingTo: _replyingTo,
                                  onCancelReply: () =>
                                      setState(() => _replyingTo = null),
                                ),
                              if (_selectedMessageIds.isEmpty &&
                                  _stickersPanelOpen)
                                Builder(
                                  builder: (context) {
                                    final repo = ref.read(
                                      userStickerPacksRepositoryProvider,
                                    );
                                    final chatRepo = ref.read(
                                      chatRepositoryProvider,
                                    );
                                    if (repo == null || chatRepo == null) {
                                      return const SizedBox.shrink();
                                    }
                                    // В expanded-режиме шторка занимает всё
                                    // свободное место (Expanded); иначе —
                                    // фикс. 42% экрана + bottom safe-area.
                                    final mq = MediaQuery.of(context);
                                    final defaultH =
                                        mq.size.height * 0.42 +
                                        mq.padding.bottom;
                                    final panel = ComposerStickerGifPanel(
                                      userId: user.uid,
                                      repo: repo,
                                      directUploadConversationId:
                                          widget.conversationId,
                                      sharedSearchQuery: _stickersSearchQuery,
                                      onPackManagerChanged: (v) {
                                        if (!mounted) return;
                                        _stickersPackManagerOpen = v;
                                        _recomputeStickersExpanded();
                                      },
                                      onSearchHintChanged: (hint) {
                                        if (!mounted) return;
                                        setState(
                                          () => _stickersSearchHint = hint,
                                        );
                                      },
                                      onPickAttachment: (att) {
                                        unawaited(
                                          _sendThreadStickerOrGifAttachment(
                                            user.uid,
                                            chatRepo,
                                            att,
                                          ),
                                        );
                                      },
                                      onEmojiTapped: (emoji) {
                                        final ctrl = _composerController;
                                        final sel = ctrl.selection;
                                        final text = ctrl.text;
                                        final start = sel.isValid
                                            ? sel.start
                                            : text.length;
                                        final end = sel.isValid
                                            ? sel.end
                                            : text.length;
                                        final newText = text.replaceRange(
                                          start,
                                          end,
                                          emoji,
                                        );
                                        ctrl.value = TextEditingValue(
                                          text: newText,
                                          selection: TextSelection.collapsed(
                                            offset: start + emoji.length,
                                          ),
                                        );
                                      },
                                      onClose: () {
                                        if (!mounted) return;
                                        setState(() {
                                          _stickersPanelOpen = false;
                                          _composerController.text =
                                              _composerTextBeforeStickerSearch ??
                                              _composerController.text;
                                          _composerController.selection =
                                              TextSelection.collapsed(
                                                offset: _composerController
                                                    .text
                                                    .length,
                                              );
                                          _composerTextBeforeStickerSearch =
                                              null;
                                          _stickersSearchQuery = '';
                                          _stickersSheetExpanded = false;
                                          _stickersPackManagerOpen = false;
                                        });
                                      },
                                    );
                                    return _stickersSheetExpanded
                                        ? Expanded(child: panel)
                                        : SizedBox(
                                            height: defaultH,
                                            child: panel,
                                          );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                      loading: () => Column(
                        children: [
                          PreferredSize(
                            preferredSize: const Size.fromHeight(56),
                            child: SafeArea(
                              bottom: false,
                              child: ThreadHeader(
                                title: headerTitle,
                                subtitle: headerSubtitle,
                                onClose: () => _closeThread(context),
                                searchActive: false,
                                onSearchTap: () {},
                              ),
                            ),
                          ),
                          _ThreadRootPanel(
                            message: parent,
                            currentUserId: user.uid,
                            conversationId: widget.conversationId,
                            conversation: conv,
                            replyCount: replyCount,
                            timeHmText: _timeHm(parent.createdAt),
                            outgoingBubbleColor: scheme.primary,
                            incomingBubbleColor: Colors.white.withValues(
                              alpha: scheme.brightness == Brightness.dark
                                  ? 0.08
                                  : 0.22,
                            ),
                            onOpenMediaGallery: null,
                          ),
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                      error: (e, _) => Center(
                        child: Text(l10n.thread_load_replies_error(e)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThreadRootPanel extends StatelessWidget {
  const _ThreadRootPanel({
    required this.message,
    required this.currentUserId,
    required this.conversationId,
    this.conversation,
    required this.replyCount,
    required this.timeHmText,
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
    this.e2eeDecryptedText,
    this.e2eeDecryptionFailed = false,
    this.onOpenMediaGallery,
  });

  final ChatMessage message;
  final String currentUserId;
  final String conversationId;
  final Conversation? conversation;
  final int replyCount;
  final String timeHmText;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;
  final String? e2eeDecryptedText;
  final bool e2eeDecryptionFailed;
  final void Function(ChatAttachment attachment)? onOpenMediaGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMine = message.senderId == currentUserId;
    if (message.isDeleted) {
      return Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.28),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: MessageDeletedStub(alignRight: isMine),
      );
    }

    // Если сообщение пришло E2EE-зашифрованным, показываем расшифрованный текст
    // (когда уже есть в кеше) или фиксированный плейсхолдер «Зашифрованное
    // сообщение» — паритет с основной лентой (chat_message_list).
    final rawSource = e2eeDecryptedText ?? (message.text ?? '');
    final html = rawSource;
    final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;
    final hasRawText = plain.trim().isNotEmpty;
    final hasMedia = message.attachments.isNotEmpty;
    final pollId = (message.chatPollId ?? '').trim();
    final hasPoll = pollId.isNotEmpty;
    final hasLocation = message.locationShare != null;
    final hasE2eeOnlyCiphertext =
        message.hasE2eeCiphertext &&
        e2eeDecryptedText == null &&
        !hasRawText &&
        !hasMedia &&
        !hasPoll &&
        !hasLocation;
    final String e2eeFallback = e2eeDecryptionFailed
        ? l10n.chat_e2ee_decrypt_failed_open_devices
        : l10n.chat_e2ee_encrypted_message_placeholder;
    final displayPlain = hasE2eeOnlyCiphertext ? e2eeFallback : plain;
    final hasText = displayPlain.trim().isNotEmpty;
    final pollStubCaption =
        hasPoll && hasText && isChatPollStubCaptionPlain(displayPlain);
    final hasVisibleText = hasText && !pollStubCaption;
    final isPureEmoji =
        hasText &&
        !hasE2eeOnlyCiphertext &&
        isOnlyEmojisMessage(html) &&
        !hasMedia &&
        !hasPoll &&
        message.replyTo == null &&
        !hasLocation;
    final radius = 18.0;
    final textSize = 15.0;
    final metaColor = (isMine ? scheme.onPrimary : scheme.onSurface).withValues(
      alpha: 0.72,
    );
    final baseStyle = TextStyle(
      fontSize: textSize,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: isMine ? scheme.onPrimary : scheme.onSurface,
    );

    Widget bubbleChild() {
      final children = <Widget>[];
      if (hasPoll) {
        children.add(
          MessageChatPoll(
            conversationId: conversationId,
            pollId: pollId,
            conversation: conversation,
            embedMessageStatus: !hasVisibleText,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            metaFontSize: 11,
          ),
        );
      }
      if (hasVisibleText) {
        if (isPureEmoji) {
          children.add(
            Text(
              displayPlain,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(fontSize: 44, height: 1.05),
            ),
          );
        } else if (!hasE2eeOnlyCiphertext && html.contains('<')) {
          children.add(
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: baseStyle,
                children: messageHtmlToStyledSpans(
                  html,
                  base: baseStyle,
                  linkColor: isMine
                      ? Colors.white.withValues(alpha: 0.95)
                      : scheme.primary,
                  quoteAccent: scheme.primary,
                  mentionFallbackLabel: AppLocalizations.of(
                    context,
                  )!.mention_fallback_label,
                ),
              ),
            ),
          );
        } else {
          children.add(Text(displayPlain, style: baseStyle));
        }
      }
      if (hasMedia) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 6));
        }
        children.add(
          MessageAttachments(
            attachments: message.attachments,
            alignRight: isMine,
            conversationId: conversationId,
            messageId: message.id,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            showTimestamps: false,
            voiceTranscript: message.voiceTranscript,
            onOpenGridGallery: onOpenMediaGallery,
            mediaNorm: message.mediaNorm,
          ),
        );
      }
      if (hasLocation) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 6));
        }
        children.add(
          MessageLocationCard(
            share: message.locationShare!,
            senderId: message.senderId,
            isMine: isMine,
            createdAt: message.createdAt,
            showTimestamps: false,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
          ),
        );
      }
      if (children.isEmpty) {
        children.add(
          Text(l10n.chat_message_empty_placeholder, style: baseStyle),
        );
      }

      final metaRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeHmText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: metaColor,
            ),
          ),
          const SizedBox(width: 4),
          MessageBubbleDeliveryIcons(
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            iconColor: metaColor,
            size: 11,
          ),
        ],
      );

      if (isMine && hasVisibleText && !isPureEmoji) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [...children, const SizedBox(height: 4), metaRow],
        );
      }

      return Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...children,
          if (!isMine || isPureEmoji || !hasVisibleText) ...[
            const SizedBox(height: 4),
            metaRow,
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ChatMediaLayoutTokens.messageBubbleMaxWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: isMine
                      ? (outgoingBubbleColor ?? scheme.primary)
                      : (incomingBubbleColor ??
                            Colors.white.withValues(
                              alpha: scheme.brightness == Brightness.dark
                                  ? 0.08
                                  : 0.22,
                            )),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: bubbleChild(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ThreadRepliesSeparator(label: l10n.thread_reply_count(replyCount)),
        ],
      ),
    );
  }
}

class _ThreadRepliesSeparator extends StatelessWidget {
  const _ThreadRepliesSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final lineColor = Colors.white.withValues(alpha: dark ? 0.12 : 0.12);
    final tagBg = Colors.white.withValues(alpha: dark ? 0.06 : 0.80);
    final tagBorder = Colors.white.withValues(alpha: dark ? 0.12 : 0.18);
    final textColor = (dark ? Colors.white : scheme.onSurface).withValues(
      alpha: dark ? 0.72 : 0.70,
    );

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: lineColor)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tagBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: lineColor)),
      ],
    );
  }
}
