import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_bar_facade.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../data/composer_clipboard_paste.dart';
import '../data/share_intent_payload.dart';
import '../data/sticker_downscale.dart';
import '../data/sticker_drop_heuristic.dart';
import '../data/e2ee_decryption_orchestrator.dart';
import '../data/e2ee_data_type_policy.dart';
import '../data/e2ee_plaintext_cache.dart';
import '../data/e2ee_runtime.dart';
import '../data/composer_attachment_limits.dart';
import '../data/e2ee_attachment_send_helper.dart';
import '../data/composer_html_editing.dart';
import '../data/chat_attachment_upload.dart';
import '../data/chat_location_share_factory.dart';
import '../data/partner_presence_line.dart';
import '../data/chat_message_search.dart';
import '../data/pinned_messages_helper.dart';
import '../data/chat_media_gallery.dart';
import '../data/link_preview_diagnostics.dart';
import '../data/reply_preview_builder.dart';
import '../data/video_attachment_diagnostics.dart';
import '../data/saved_messages_chat.dart';
import '../data/group_mention_candidates.dart';
import '../data/contact_display_name.dart';
import '../data/emoji_burst_animation_profile.dart';
import '../data/user_profile.dart';
import '../data/user_contacts_repository.dart';
import '../data/chat_message_draft_storage.dart';
import '../data/recent_stickers_store.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_drag_drop_target.dart';
import 'chat_html_composer_controller.dart';
import 'chat_audio_call_screen.dart';
import 'chat_video_call_screen.dart';
import 'chat_header.dart';
import 'schedule_message_sheet.dart';
import 'scheduled_messages_screen.dart';
import 'chat_message_search_overlay.dart';
import 'destructive_confirm_dialog.dart';
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
import 'chat_document_open.dart';
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
import 'report_sheet.dart';
import 'chat_composer.dart';
import 'smart_compose_strip.dart';
import 'smart_reply_chips.dart';
import '../data/apple_intelligence.dart';
import '../data/chat_haptics.dart';
import '../data/document_scanner.dart';
import 'document_scanner_preview_screen.dart';
import 'ai_text_action_sheet.dart';
import 'thread_route_payload.dart';
import 'secret_chat_secure_scope.dart';
import 'secret_chat_unlock_sheet.dart';
import 'sticker_pack_menu_actions.dart';
import '../data/secret_chat_media_open_service.dart';
import '../data/local_message_translator.dart';
import '../data/local_text_language_detector.dart';
import '../data/local_text_to_speech.dart';
import 'message_translation_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.initialSharePayload,
  });

  final String conversationId;

  /// Phase B: payload системного «Поделиться → LighChat», прокидываемый из
  /// `/share` через `state.extra`. Если задан, файлы попадают в
  /// `_pendingAttachments`, а текст вставляется в композер при первом
  /// `initState` (один раз — не реагирует на дальнейшие push'ы того же
  /// route, т.к. это разные экземпляры `ChatScreen`).
  final ShareIntentPayload? initialSharePayload;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
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

  /// Отложенное скрытие разделителя «Непрочитанные сообщения» — линия живёт ещё
  /// несколько секунд после того, как все сообщения над ней стали прочитанными,
  /// чтобы пользователь успел заметить позицию.
  Timer? _hideUnreadSeparatorTimer;
  static const Duration _kUnreadSeparatorLinger = Duration(seconds: 5);

  /// После подгрузки истории не дергать сразу повторный запрос у верхнего края.
  DateTime? _nearOldestCooldownUntil;
  ReplyContext? _replyingTo;

  /// Режим правки: id сообщения + превью для полосы над вводом (plain).
  String? _editingMessageId;
  String? _editingPreviewPlain;

  /// `createdAt` редактируемого сообщения. Нужен только для одного места:
  /// после сохранения отредактированного E2EE-текста положить новый plaintext
  /// в локальный preview-кэш с тем же `ts`, что у сообщения, чтобы сайдбар
  /// подхватил обновление вместо плейсхолдера «Зашифрованное сообщение».
  String? _editingCreatedAt;
  final Set<String> _selectedMessageIds = <String>{};
  bool _actionBusy = false;
  final List<XFile> _pendingAttachments = <XFile>[];

  /// Снимок предсэндовых лимитов вложений (см. `composer_attachment_limits.dart`).
  /// Пересчитывается при каждом изменении `_pendingAttachments` и при смене
  /// `convIsE2ee` (e2ee переключился — лимит уменьшился с 20 до 5/96 МБ).
  ComposerLimitsState? _composerLimitsState;
  bool _lastConvIsE2ee = false;
  int _composerLimitsSerial = 0;

  bool _sendBusy = false;
  bool _voiceSendBusy = false;
  bool _videoCircleSendBusy = false;

  /// Панель «Форматирование» над композером (паритет `FormattingToolbar.tsx`).
  bool _composerFormattingOpen = false;

  /// Доступен ли Apple Intelligence на этом устройстве (iOS 18.1+/26+
  /// + загруженная модель + opt-in пользователя). Проверяем один раз при
  /// первом тапе по AI-фиче — состояние не меняется.
  bool _aiAvailable = false;
  bool _stickersPanelOpen = false;
  bool _stickersPanelFullscreen = false;
  String _stickersSearchQuery = '';
  String _stickersSearchHint = '';
  String? _composerTextBeforeStickerSearch;
  // Последняя известная высота системной клавиатуры. Используем для
  // клавиатуро-эквивалентной высоты шторки стикеров без скачков.
  double _lastKeyboardHeight = 0;

  /// Высота шторки, **зафиксированная в момент открытия**. Пока шторка
  /// открыта — больше не пересматриваем, чтобы panel не схлопывался
  /// вместе с уезжающей клавиатурой (см. didChangeMetrics → captureKb
  /// обновляет `_lastKeyboardHeight` на каждый кадр анимации kb).
  double _stickerPanelLockedHeight = 0;

  /// Минимальная резервируемая высота под composer'ом на время
  /// переключений keyboard ↔ sticker panel. Пока выставлена, footer
  /// держит эту высоту, чтобы поле ввода не «прыгало» вниз пока
  /// клавиатура убирается / шторка появляется. Сбрасывается таймером
  /// после короткой задержки (когда iOS успевает закончить анимацию).
  double _stickersTransitionFooterFloor = 0;
  Timer? _stickersTransitionFooterTimer;

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
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onPinnedBarScrollSync);
    _controller.addListener(_scheduleChatDraftSave);
    _captureKeyboardHeight();
    unawaited(AppleIntelligence.instance.isAvailable().then((v) {
      if (mounted) setState(() => _aiAvailable = v);
    }));
    // Chat-only gradient blur в status bar zone (см. NavBarOverlayHost).
    // Включаем при входе, выключаем в dispose. Других экранов не
    // касается — secondary-страницы остаются без blur'а.
    unawaited(NativeNavBarFacade.instance.setTopBlur(enabled: true));
    // Phase B: системный «Поделиться → LighChat». Применяем payload до
    // первого build, чтобы пользователь сразу увидел готовые pending‑файлы
    // и pre‑filled текст. Применяем один раз — повторных push'ов не
    // ожидаем (новый share создаёт новый ChatScreen через CupertinoPage).
    final share = widget.initialSharePayload;
    if (share != null && share.isNotEmpty) {
      if (share.files.isNotEmpty) {
        _pendingAttachments.addAll(share.files);
      }
      final t = (share.text ?? '').trim();
      if (t.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _insertComposerTextAtCursor(t);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleChatDraftSave();
      });
    }
  }

  @override
  void didChangeMetrics() {
    _captureKeyboardHeight();
  }

  void _captureKeyboardHeight() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final height = view.viewInsets.bottom / view.devicePixelRatio;
    if (_stickersTransitionFooterFloor > 0 &&
        height >= _stickersTransitionFooterFloor - 1) {
      _stickersTransitionFooterTimer?.cancel();
      if (mounted) {
        setState(() => _stickersTransitionFooterFloor = 0);
      } else {
        _stickersTransitionFooterFloor = 0;
      }
    }
    // Только РАСТЁМ. didChangeMetrics срабатывает на каждый кадр
    // iOS-анимации скрытия клавиатуры (345 → 317 → … → 0.28), и
    // если бы мы записывали каждое значение, _lastKeyboardHeight
    // оседал бы у нуля. После этого `hold` в
    // `_switchFromStickersToKeyboard` брал ≈0 и composer падал
    // в самый низ перед поднятием клавиатуры.
    if (height <= 0 || height <= _lastKeyboardHeight + 0.5) return;
    if (!mounted) {
      _lastKeyboardHeight = height;
      return;
    }
    setState(() => _lastKeyboardHeight = height);
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
      _composerLimitsState = null;
      _composerLimitsSerial += 1;
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
      _hideUnreadSeparatorTimer?.cancel();
      _hideUnreadSeparatorTimer = null;
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
    if (m.readAt != null) return false;
    // Личная отметка прочтения (режим скрытых read-receipts):
    // см. ChatRepository.markMessagesAsRead(skipReadReceipt: true).
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
      // Не сбрасываем якорь сразу — даём пользователю время заметить разделитель.
      // Если новые непрочитанные не пришли в течение _kUnreadSeparatorLinger,
      // плашка скрывается; иначе таймер отменяется ниже по else-ветке.
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
      // skipReadReceipt: режим приватности — пишем только личный readByUid.{me},
      // публичный readAt не трогаем, чтобы собеседник не видел галочки.
      await repo.markMessagesAsRead(
        conversationId: widget.conversationId,
        userId: userId,
        messageIds: <String>[id],
        skipReadReceipt: !allowReadReceipts,
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
          skipReadReceipt: !allowReadReceipts,
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
    // Выключаем gradient blur — на следующем экране (chat list, etc.)
    // он не нужен. Дедуп в facade'е защищает от двойного off'а.
    unawaited(NativeNavBarFacade.instance.setTopBlur(enabled: false));
    _chatDraftDebounce?.cancel();
    _messageExpiryTimer?.cancel();
    _scheduledCountSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(_persistChatDraftSnapshotForConv(uid, widget.conversationId));
    }
    _flashHighlightTimer?.cancel();
    _hideUnreadSeparatorTimer?.cancel();
    _stickersTransitionFooterTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onPinnedBarScrollSync);
    _controller.removeListener(_scheduleChatDraftSave);
    _composerFocusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _chatSearchController.dispose();
    _chatSearchFocus.dispose();
    // Сводки по обоим источникам скролл-дёрганья: если в обоих 0 регрессий —
    // фиксы живы, если >0 — баг каким-то путём вернулся.
    LinkPreviewFlickerDetector.printSummary();
    VideoAttachmentAspectMonitor.printSummary();
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

  void _openScheduledMessagesScreen(String uid, {required bool e2eeActive}) {
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

    return ChatDragDropTarget(
      onFilesDropped: _handleDroppedFiles,
      onTextDropped: _handleDroppedText,
      child: userAsync.when(
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
          final userDoc =
              userDocAsync.asData?.value ?? const <String, dynamic>{};
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
          final autoTranslateIncoming =
              (rawChatSettings['autoTranslateIncoming'] as bool?) ?? false;
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
                messagesProvider((
                  conversationId: conversationId,
                  limit: _limit,
                )),
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
                      ? AppLocalizations.of(
                            context,
                          )!.partner_profile_title_fallback_saved
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
                      : partnerPresenceLine(
                          profile,
                          AppLocalizations.of(context)!,
                        );
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
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    // На desktop wide-layout открываем как правую шторку
                    // (как в web-версии LighChat). На узких — fullscreen push.
                    const desktopBreakpoint = 1024.0;
                    if (screenWidth >= desktopBreakpoint) {
                      showGeneralDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Закрыть профиль',
                        barrierColor: Colors.black.withValues(alpha: 0.16),
                        transitionDuration: const Duration(milliseconds: 220),
                        transitionBuilder: (ctx, anim, _, child) {
                          final offset = Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ));
                          return SlideTransition(position: offset, child: child);
                        },
                        pageBuilder: (ctx, _, _) => Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            elevation: 16,
                            color: Theme.of(ctx).colorScheme.surface,
                            child: SizedBox(
                              width: 420,
                              height: double.infinity,
                              child: ChatPartnerProfileSheet(
                                conversationId: conversationId,
                                conversation: conv.data,
                                currentUserId: user.uid,
                                selfProfile: selfProfile,
                                partnerProfile: profileForSheet,
                                onJumpToMessageId: _scrollToMessageId,
                                fullScreen: false,
                              ),
                            ),
                          ),
                        ),
                      );
                      return;
                    }
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
                    // belowHeaderGap двигает контент ниже шапки. На iOS
                    // с native nav bar overlay'ом мы НЕ хотим этот gap —
                    // тогда сообщения будут скроллиться ПОД bar'ом с
                    // translucent blur (iOS-26 native pattern).
                    // На Android — Flutter ChatHeader занимает место,
                    // gap нужен.
                    final usesNativeBar =
                        NativeNavBarFacade.instance.isSupported;
                    final belowHeaderGap = usesNativeBar
                        ? 0.0
                        : topInset + headerBar;
                    // Для Positioned-banner'ов нужна фактическая позиция
                    // bottom-edge native bar'а независимо от
                    // belowHeaderGap. На iOS — статус-bar + ~48pt bar.
                    final nativeBarBottom = usesNativeBar
                        ? topInset + 48.0
                        : belowHeaderGap;
                    final sortedAscForAnchor = List<ChatMessage>.from(msgs)
                      ..sort((a, b) {
                        final t = a.createdAt.compareTo(b.createdAt);
                        if (t != 0) return t;
                        return a.id.compareTo(b.id);
                      });
                    final loadedIncomingUnreadCount =
                        _loadedIncomingUnreadCount(
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
                      resizeToAvoidBottomInset: false,
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
                                  // Скрываем native header целиком, когда
                                  // открыта стикер-шторка — иначе она
                                  // перекрывает search-input стикеров.
                                  stickersPanelOpen: _stickersPanelOpen,
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
                                  disappearingMessagesEnabled:
                                      (conv?.data.disappearingMessageTtlSec ??
                                          0) >
                                      0,
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
                              bottom: false,
                              child: Column(
                                children: [
                                  SizedBox(height: belowHeaderGap),
                                  // На iOS native bar — overlay поверх
                                  // Column'а, и DmGameLobbyBanner
                                  // уезжал к status bar'у. Telegram-style:
                                  // на iOS рендерим banner как Positioned
                                  // ниже native bar pill'а (см. блок
                                  // Positioned ниже в Stack'е). На
                                  // Android/Win/Linux оставляем inline.
                                  if (conv != null && !usesNativeBar)
                                    DmGameLobbyBanner(
                                      conversationId: conversationId,
                                      isGroup: conv.data.isGroup,
                                    ),
                                  // На iOS native bar — overlay поверх
                                  // Column'а с belowHeaderGap=0, поэтому
                                  // pinned strip уезжает к самому верху и
                                  // перекрывается status-bar'ом. Telegram-
                                  // style: рендерим pill как Positioned ниже
                                  // (см. nativeBarBottom).
                                  // Pinned strip скрываем в режиме поиска
                                  // на всех платформах + при открытой
                                  // шторке стикеров: оба сценария — это
                                  // модальная UX-зона, pinned под ней
                                  // только засоряет экран.
                                  if (topPin != null &&
                                      conv != null &&
                                      !usesNativeBar &&
                                      !_inChatSearch &&
                                      !_stickersPanelOpen)
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
                                    flex: 1,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        if (_stickersPanelOpen) {
                                          _closeStickersPanel();
                                        }
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                      child: showSpinner
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
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
                                                    lastMessageTimestamp: conv
                                                        ?.data
                                                        .lastMessageTimestamp,
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
                                                                userId:
                                                                    user.uid,
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
                                                          // Date capsule
                                                          // прячется под
                                                          // native nav
                                                          // bar'ом и под
                                                          // pinned pill'ём.
                                                          // На iOS пушим
                                                          // её ниже
                                                          // pinned pill'a
                                                          // (примерно
                                                          // высота
                                                          // pill ~46pt) +
                                                          // 8pt gap.
                                                          final dateOffset =
                                                              usesNativeBar
                                                                  ? nativeBarBottom +
                                                                      (topPin != null
                                                                          ? 52
                                                                          : 6)
                                                                  : 4.0;
                                                          return ChatMessageList(
                                                            topOverlayOffset:
                                                                dateOffset,
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
                                                                  l10n:
                                                                      AppLocalizations.of(
                                                                        context,
                                                                      )!,
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
                                                            // Быстрое
                                                            // приветствие из
                                                            // empty-state.
                                                            onEmptyQuickGreet: () {
                                                              _controller.text =
                                                                  '👋';
                                                              final globalPolicy =
                                                                  E2eeDataTypePolicy.fromFirestore(
                                                                    rawPrivacySettings['e2eeEncryptedDataTypes'],
                                                                  );
                                                              final convData =
                                                                  conv?.data;
                                                              final overrideRaw =
                                                                  convData
                                                                      ?.e2eeEncryptedDataTypesOverride;
                                                              final overridePolicy =
                                                                  overrideRaw ==
                                                                      null
                                                                  ? null
                                                                  : E2eeDataTypePolicy.fromFirestore(
                                                                      overrideRaw,
                                                                    );
                                                              final effectivePolicy =
                                                                  resolveE2eeEffectivePolicy(
                                                                    global:
                                                                        globalPolicy,
                                                                    override:
                                                                        overridePolicy,
                                                                  );
                                                              unawaited(
                                                                _submitComposer(
                                                                  user.uid,
                                                                  conv: convData,
                                                                  e2eePolicy:
                                                                      effectivePolicy,
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
                                                            autoTranslateIncoming:
                                                                autoTranslateIncoming,
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
                                                                            Alignment.centerRight,
                                                                        child: OutgoingPendingMediaAlbum(
                                                                          key: ValueKey(
                                                                            Object.hash(
                                                                              album.files.length,
                                                                              album.text,
                                                                              album.replyTo?.messageId,
                                                                            ),
                                                                          ),
                                                                          files:
                                                                              album.files,
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
                                                                              final pendingMessageId = album.e2eeContext?.messageId.trim();
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
                                                                              WidgetsBinding.instance.addPostFrameCallback(
                                                                                (
                                                                                  _,
                                                                                ) {
                                                                                  _scheduleAutoScrollToBottomIfNeeded();
                                                                                },
                                                                              );
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
                                                                              setState(
                                                                                () {
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
                                                                                },
                                                                              );
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
                                                            onMessageLongPress: (m) => _onMessageLongPress(
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
                                                              e2eeDecryptedText:
                                                                  e2eeDecryptedMap[m
                                                                      .id],
                                                              e2eeDecryptionFailed:
                                                                  e2eeFailedIds
                                                                      .contains(
                                                                        m.id,
                                                                      ),
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
                                                            onOpenFileAttachment:
                                                                (att, m) {
                                                                  unawaited(
                                                                    _openFileAttachment(
                                                                      att,
                                                                      m,
                                                                      conv: conv
                                                                          ?.data,
                                                                    ),
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
                                                                  messageId:
                                                                      m.id,
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
                                                      // Подмешиваем расшифрованный
                                                      // plaintext из persistent
                                                      // E2EE-кэша (warm-up или
                                                      // putText из orchestrator):
                                                      // у E2EE-сообщений `m.text`
                                                      // пуст, и без этого фильтр
                                                      // всегда возвращал бы 0
                                                      // совпадений.
                                                      final decryptedMap =
                                                          <String, String>{};
                                                      for (final m in msgs) {
                                                        if (m.e2eePayload ==
                                                            null) {
                                                          continue;
                                                        }
                                                        final cached =
                                                            E2eePlaintextCache
                                                                .instance
                                                                .getTextSync(
                                                                  conversationId:
                                                                      widget
                                                                          .conversationId,
                                                                  messageId:
                                                                      m.id,
                                                                );
                                                        if (cached != null &&
                                                            cached.isNotEmpty) {
                                                          decryptedMap[m.id] =
                                                              cached;
                                                        }
                                                      }
                                                      final results =
                                                          filterMessagesForInChatSearch(
                                                            msgs,
                                                            _chatSearchController
                                                                .text,
                                                            decryptedTextByMessageId:
                                                                decryptedMap,
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
                                                          decryptedTextByMessageId:
                                                              decryptedMap,
                                                          // На iOS body
                                                          // рисуется под
                                                          // native nav
                                                          // bar'ом — без
                                                          // topInset
                                                          // карточка
                                                          // результатов
                                                          // уезжала в
                                                          // status bar.
                                                          topInset:
                                                              nativeBarBottom,
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
                                                                userId:
                                                                    user.uid,
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
                                  // Композер скрываем когда активен поиск
                                  // по сообщениям — клавиатуре нужна вся
                                  // высота под список + native search bar.
                                  if (_selectedMessageIds.isEmpty &&
                                      !_inChatSearch) ...[
                                    const LiveLocationStopBanner(),
                                    Builder(builder: (innerCtx) {
                                      // Синхронизируем `_lastConvIsE2ee` с актуальным состоянием
                                      // чата и пересчитываем лимиты, если переключилось (например,
                                      // E2EE стало активным после установки epoch).
                                      final convIsE2eeNow =
                                          isConversationE2eeActive(conv?.data);
                                      if (convIsE2eeNow != _lastConvIsE2ee) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          _lastConvIsE2ee = convIsE2eeNow;
                                          _recomputeComposerLimits();
                                        });
                                      }
                                      final smartReplyMessages =
                                          _sortedHydratedAscCache.isNotEmpty
                                              ? _sortedHydratedAscCache
                                              : _sortedAscCache;
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SmartReplyChips(
                                            messages: smartReplyMessages,
                                            currentUserId: user.uid,
                                            composerIsEmpty:
                                                _controller.text.trim().isEmpty,
                                            onPick: (text) {
                                              _controller.text = text;
                                              _controller.selection =
                                                  TextSelection.collapsed(
                                                      offset: text.length);
                                              _composerFocusNode.requestFocus();
                                              setState(() {});
                                            },
                                          ),
                                          SmartComposeStrip(
                                            controller: _controller,
                                            focusNode: _composerFocusNode,
                                            aiAvailable: _aiAvailable,
                                          ),
                                          ChatComposer(
                                      controller: _controller,
                                      focusNode: _composerFocusNode,
                                      stickersPanelOpen: _stickersPanelOpen,
                                      stickersPanelHideSideButtons:
                                          _stickersPanelOpen &&
                                          _stickersPanelFullscreen,
                                      hasFooterBelow:
                                          _stickersPanelOpen ||
                                          _stickersTransitionFooterFloor > 0 ||
                                          MediaQuery.viewInsetsOf(
                                                context,
                                              ).bottom >
                                              0,
                                      onKeyboardTap:
                                          _switchFromStickersToKeyboard,
                                      stickersSearchHint: _stickersSearchHint,
                                      onStickersSearchChanged: (q) {
                                        if (!mounted) return;
                                        setState(
                                          () => _stickersSearchQuery = q,
                                        );
                                      },
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
                                        final overridePolicy =
                                            overrideRaw == null
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
                                              l10n: AppLocalizations.of(
                                                context,
                                              ),
                                            )
                                          : null,
                                      pendingAttachments: _pendingAttachments,
                                      onRemovePending: (i) {
                                        setState(
                                          () => _pendingAttachments.removeAt(i),
                                        );
                                        _scheduleChatDraftSave();
                                        _recomputeComposerLimits();
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
                                          if (!context.mounted) return;

                                          final edited =
                                              await ChatImageEditorScreen.open(
                                                context,
                                                files: imageFiles,
                                                initialIndex: initialImageIndex,
                                                initialCaption:
                                                    _controller.text,
                                              );
                                          if (edited == null ||
                                              !context.mounted) {
                                            return;
                                          }

                                          setState(() {
                                            final merged = <XFile>[];
                                            var editedImageCursor = 0;
                                            for (final f
                                                in _pendingAttachments) {
                                              if (isOutgoingAlbumLocalImage(
                                                f,
                                              )) {
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
                                          _recomputeComposerLimits();
                                          return;
                                        }

                                        if (_looksLikeVideoAttachment(target)) {
                                          final edited =
                                              await ChatVideoEditorScreen.open(
                                                context,
                                                file: target,
                                                initialCaption:
                                                    _controller.text,
                                              );
                                          if (edited == null || !mounted) {
                                            return;
                                          }
                                          setState(() {
                                            if (i < 0 ||
                                                i >=
                                                    _pendingAttachments
                                                        .length) {
                                              return;
                                            }
                                            _pendingAttachments[i] =
                                                edited.file;
                                          });
                                          _controller.text = edited.caption;
                                          _scheduleChatDraftSave();
                                          _recomputeComposerLimits();
                                        }
                                      },
                                      attachmentsEnabled:
                                          _editingMessageId == null,
                                      sendBusy: _sendBusy,
                                      onAttachmentSelected: (a) => unawaited(
                                        _handleComposerAttachment(a),
                                      ),
                                      onMicTap: () => unawaited(
                                        _sendVoiceMessage(user.uid),
                                      ),
                                      onVoiceHoldRecorded: (rec) async {
                                        await _sendVoiceMessageFromRecord(
                                          user.uid,
                                          rec,
                                        );
                                      },
                                      onStickersTap: _openStickersGifPanel,
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
                                      aiAvailable: _aiAvailable,
                                      onRewriteWithAi: _aiAvailable
                                          ? () => _openRewriteWithAi()
                                          : null,
                                      limitsState: _composerLimitsState,
                                      sendBlockedByLimits:
                                          _composerLimitsState?.isOverLimit ==
                                          true,
                                    ),
                                        ],
                                      );
                                    }),
                                    Builder(
                                      builder: (context) {
                                        final keyboardInset =
                                            MediaQuery.viewInsetsOf(
                                              context,
                                            ).bottom;
                                        final mq = MediaQuery.of(context);
                                        final defaultH =
                                            mq.size.height * 0.42;
                                        // fullScreen-режим панели стикеров:
                                        // ограничиваем сверху safe-area
                                        // top (status bar + Dynamic Island)
                                        // + extra 24pt — иначе search-input
                                        // панели застревал под DI.
                                        final maxFullH = mq.size.height
                                            - mq.padding.top
                                            - 24;
                                        final fullScreenH =
                                            (mq.size.height * 0.88).clamp(
                                              mq.size.height * 0.62,
                                              maxFullH,
                                            );
                                        // Высота панели — locked snapshot,
                                        // взятый при открытии. Не пересматриваем
                                        // её каждый кадр, иначе panel
                                        // схлопывается вместе с уезжающей
                                        // клавиатурой.
                                        final lockedPanelH =
                                            _stickerPanelLockedHeight > 0
                                            ? _stickerPanelLockedHeight
                                            : (_lastKeyboardHeight > 0
                                                  ? _lastKeyboardHeight
                                                  : defaultH);
                                        final panelHeight =
                                            _stickersPanelOpen
                                            ? (_stickersPanelFullscreen
                                                  ? fullScreenH
                                                  : lockedPanelH)
                                            : 0.0;
                                        // ВАЖНО: Scaffold здесь с
                                        // `resizeToAvoidBottomInset: false`
                                        // (см. l. 1553) — body заполняет
                                        // весь экран, клавиатура НЕ
                                        // вычитается автоматически. Поэтому
                                        // footer должен сам зарезервировать
                                        // место под клавиатуру/шторку:
                                        //   footer = max(panelH, kbInset, floor)
                                        // При переходе keyboard↔panel
                                        // panelH стабильно держит footer,
                                        // даже когда kbInset падает с 290→0,
                                        // и composer стоит на месте.
                                        final footerHeight = [
                                          panelHeight,
                                          keyboardInset,
                                          _stickersTransitionFooterFloor,
                                        ].reduce((a, b) => a > b ? a : b);
                                        if (!_stickersPanelOpen) {
                                          // БЕЗ AnimatedSize: при переходе
                                          // panel→keyboard виджет-тип
                                          // менялся (SizedBox в panelOpen-
                                          // ветке → AnimatedSize здесь),
                                          // у нового AnimatedSize
                                          // currentSize = 0 и он анимировал
                                          // 0 → 345 за 180 ms, из-за чего
                                          // composer на мгновение
                                          // проседал вниз. Locked snapshot
                                          // (см. _stickerPanelLockedHeight)
                                          // уже даёт стабильный footer на
                                          // штатных переходах — анимация
                                          // больше не нужна.
                                          if (footerHeight <= 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return SizedBox(
                                            height: footerHeight,
                                          );
                                        }
                                        final stickerRepo = ref.read(
                                          userStickerPacksRepositoryProvider,
                                        );
                                        final chatRepo = ref.read(
                                          chatRepositoryProvider,
                                        );
                                        if (stickerRepo == null ||
                                            chatRepo == null) {
                                          return SizedBox(
                                            height: footerHeight,
                                          );
                                        }
                                        final panel = ComposerStickerGifPanel(
                                          userId: user.uid,
                                          repo: stickerRepo,
                                          directUploadConversationId:
                                              widget.conversationId,
                                          sharedSearchQuery:
                                              _stickersSearchQuery,
                                          onSearchHintChanged: (hint) {
                                            if (!mounted) return;
                                            setState(
                                              () => _stickersSearchHint = hint,
                                            );
                                          },
                                          onFullscreenModeChanged: (v) {
                                            if (!mounted ||
                                                _stickersPanelFullscreen == v) {
                                              return;
                                            }
                                            setState(() {
                                              _stickersPanelFullscreen = v;
                                            });
                                          },
                                          onPickAttachment: (att) {
                                            unawaited(
                                              _sendStickerOrGifAttachment(
                                                user.uid,
                                                chatRepo,
                                                att,
                                              ),
                                            );
                                          },
                                          onEmojiTapped:
                                              _handleEmojiPickFromStickersPanel,
                                          onClose: () {
                                            _closeStickersPanel();
                                          },
                                        );
                                        // footerHeight == max(panelH, kbInset)
                                        // — пока клавиатура ещё опускается,
                                        // panelH её перекрывает, шторка
                                        // рендерится на полной высоте, низ
                                        // прячется за клавиатурой (она
                                        // системно поверх Flutter-view).
                                        return SizedBox(
                                          height: footerHeight,
                                          child: panel,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // iOS-only: DmGameLobbyBanner + Pinned-pill
                            // оба под native bar'ом. Оборачиваем в один
                            // Positioned+Column — если оба активны,
                            // лобби сверху, pinned ниже без визуального
                            // overlap'а. Inline-вариант (внутри Column'а
                            // body) уезжал бы под status bar, потому что
                            // на iOS-native Column начинается с y=0
                            // (belowHeaderGap=0).
                            if (usesNativeBar &&
                                conv != null &&
                                !_inChatSearch &&
                                !_stickersPanelOpen)
                              Positioned(
                                top: nativeBarBottom - 8,
                                left: 20,
                                right: 20,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DmGameLobbyBanner(
                                      conversationId: conversationId,
                                      isGroup: conv.data.isGroup,
                                    ),
                                    if (topPin != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: ChatPinnedStrip(
                                          pin: topPin,
                                          totalPins: sortedPins.length,
                                          pill: true,
                                          onUnpin: () => _unpinMessage(
                                            topPin,
                                            conv.data,
                                          ),
                                          onOpenPinned: () {
                                            final n = sortedPins.length;
                                            if (n == 0) return;
                                            final i = displayPinIdx;
                                            final target = sortedPins[i];
                                            _scrollToMessageId(
                                              target.messageId,
                                            );
                                            setState(() {
                                              _pinnedBarSkipSyncUntilMs =
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch +
                                                  900;
                                              _barPinIndex = (i - 1 + n) % n;
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (showCalls &&
                                dmOtherId != null &&
                                dmOtherId.isNotEmpty)
                              Positioned(
                                // На iOS native bar поверх Column'а с
                                // belowHeaderGap=0 → banner надо
                                // позиционировать по nativeBarBottom.
                                top: nativeBarBottom + 8,
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
                                                  await FirebaseFirestore
                                                      .instance
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
                                                  currentUserAvatarUrl:
                                                      meAvatar,
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
                        // Гаптик «пришло новое сообщение»: только когда счётчик
                        // вырос и последнее — не от меня (иначе сами себе
                        // вибрируем после отправки). previousVisibleCount > 0
                        // — исключаем первый рендер чата (история-загрузка
                        // не должна стрелять).
                        if (previousVisibleCount > 0 &&
                            visibleMsgs.length > previousVisibleCount &&
                            _sortedAscCache.isNotEmpty &&
                            _sortedAscCache.last.senderId != user.uid) {
                          unawaited(ChatHaptics.instance.receiveMessage());
                        }
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
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
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

  void _handleDroppedFiles(List<XFile> files) {
    if (files.isEmpty || !mounted) return;
    if (_editingMessageId != null) {
      _toast(AppLocalizations.of(context)!.chat_finish_editing_first);
      return;
    }
    // Telegram-style sticker drop: PNG/WebP ≤512px с прозрачными углами
    // распознаём как стикер и отправляем сразу одним сообщением, без
    // прохода через pending. Остальные файлы идут привычным путём.
    unawaited(_dispatchDroppedFiles(files));
  }

  Future<void> _dispatchDroppedFiles(List<XFile> files) async {
    debugPrint('[chat-drop] dispatch: ${files.length} file(s) to classify');
    final stickers = <XFile>[];
    final pending = <XFile>[];
    for (final f in files) {
      final isSticker = await isLikelyStickerXFile(f);
      if (isSticker) {
        stickers.add(f);
      } else {
        pending.add(f);
      }
    }
    debugPrint(
      '[chat-drop] dispatch result: '
      'stickers=${stickers.length} pending=${pending.length}',
    );
    if (!mounted) return;
    if (pending.isNotEmpty) {
      setState(() => _pendingAttachments.addAll(pending));
      _scheduleChatDraftSave();
      _recomputeComposerLimits();
    }
    if (stickers.isNotEmpty) {
      unawaited(_sendDroppedStickers(stickers));
    }
  }

  /// Загружает каждый файл-«стикер» в Storage и отправляет тем же путём,
  /// что стикеры из панели — это автоматически обновит Recent stickers и
  /// корректно обработает E2EE‑envelope в зашифрованных чатах.
  Future<void> _sendDroppedStickers(List<XFile> stickers) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    for (final s in stickers) {
      if (!mounted) return;
      try {
        // iOS Lift Subject отдаёт PNG в исходном разрешении камеры
        // (3024×3292+, 7–15 MiB). Перед upload ужимаем до 1024px по
        // большей стороне — Telegram-style, ~200–400 KiB на выходе,
        // мгновенный upload. Decode/encode идут в isolate (compute),
        // UI не фризится.
        final compact = await downscaleStickerForSend(s);
        if (!mounted) return;
        // ВАЖНО: displayName с префиксом 'sticker_' — иначе message UI
        // (см. _isStickerAttachment в message_attachments.dart и
        // _isStickerAttachmentForMenu в message_context_menu.dart)
        // не распознаёт это как стикер: рендерится крупным изображением,
        // в context-menu показывается «Создать стикер» вместо «Сохранить
        // в стикеры». Префикс — единственный дискриминатор по проекту.
        final stickerName =
            'sticker_${DateTime.now().toUtc().microsecondsSinceEpoch}.png';
        final att = await uploadChatAttachmentFromXFile(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          file: compact,
          displayName: stickerName,
        );
        if (!mounted) return;
        await _sendStickerOrGifAttachment(uid, repo, att);
      } catch (e) {
        if (!mounted) return;
        _toast(AppLocalizations.of(context)!.chat_send_failed(e));
      }
    }
  }

  /// Пересчёт лимитов вложений для текущего черновика.
  ///
  /// Async из-за чтения `XFile.length()` (нужно только для E2EE-чатов, где
  /// есть лимит на суммарный размер). Через serial-counter защищаемся от
  /// гонок: если за время `await` пользователь успел добавить/удалить ещё —
  /// результат пред-пересчёта молча отбрасываем.
  void _recomputeComposerLimits() {
    final limits = ComposerAttachmentLimits.forChat(isE2ee: _lastConvIsE2ee);
    final filesSnapshot = List<XFile>.unmodifiable(_pendingAttachments);
    final mySerial = ++_composerLimitsSerial;
    unawaited(() async {
      final state = await computeComposerLimitsState(filesSnapshot, limits);
      if (!mounted || mySerial != _composerLimitsSerial) return;
      setState(() => _composerLimitsState = state);
    }());
  }

  void _handleDroppedText(String text) {
    if (text.trim().isEmpty || !mounted) return;
    _insertComposerTextAtCursor(text);
  }

  Future<void> _pasteContentFromClipboard() async {
    try {
      final payload = await readComposerClipboardPayload();
      if (!mounted) return;
      if (payload.files.isNotEmpty) {
        setState(() => _pendingAttachments.addAll(payload.files));
        _scheduleChatDraftSave();
        _recomputeComposerLimits();
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
    final ok = await showDestructiveConfirmDialog(
      context: context,
      title: l10n.chat_delete_message_title_single,
      body: l10n.chat_delete_message_body_single,
      confirmLabel: l10n.common_delete,
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
          onAttachToComposer: (path) {
            if (!mounted) return;
            setState(() {
              _pendingAttachments.add(XFile(path, name: 'subject.png'));
            });
            _scheduleChatDraftSave();
            _recomputeComposerLimits();
          },
          onShowInChat: (galleryItem) {
            _scrollToMessageId(galleryItem.message.id);
          },
        ),
      ),
    );
  }

  Future<void> _openFileAttachment(
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
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.secret_chat_unlock_failed)),
        );
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
    final ok = await showDestructiveConfirmDialog(
      context: context,
      title: targets.length > 1
          ? l10n.chat_delete_message_title_multi
          : l10n.chat_delete_message_title_single,
      body: targets.length > 1
          ? l10n.chat_delete_message_body_multi(targets.length)
          : l10n.chat_delete_message_body_single,
      confirmLabel: l10n.common_delete,
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
      // Запоминаем createdAt как ISO-строку: репозиторий и preview-кэш
      // оперируют строками, чтобы потом сравнить с `lastMessageTimestamp`
      // в Firestore (там тоже строка, в формате `toUtc().toIso8601String()`).
      _editingCreatedAt = m.createdAt.toUtc().toIso8601String();
      _replyingTo = null;
      _composerFormattingOpen = false;
      _controller.text = forEdit;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocusNode.requestFocus();
    });
  }

  /// Можно ли показать пункт «Translate» в context-меню сообщения.
  /// Считает, что да, если:
  /// - в тексте есть что переводить (> 1 буква),
  /// - определённый язык надёжен и отличается от UI-локали,
  /// - ML Kit поддерживает пару.
  Future<bool> _canTranslateMessage(String rawText) async {
    // Кнопка всегда видна для непустых сообщений: пользователь сам решает
    // на какой язык перевести (даже если язык совпадает с UI). Если язык
    // не определён или не поддерживается ML Kit — кнопка всё равно есть,
    // sheet сам разрулит fallback (en→ru или ru→en).
    final stripped = rawText.contains('<')
        ? messageHtmlToPlainText(rawText)
        : rawText;
    return stripped.trim().length >= 2;
  }

  /// Показывает bottom-sheet с переводом сообщения и кнопкой «Copy».
  /// Перевод on-device через ML Kit; результат кэшируется в SQLite, поэтому
  /// повторный «Перевести» того же сообщения мгновенный.
  /// Apple Intelligence «Переписать» — выделенный текст composer-а (или весь,
  /// если selection пуст). Sheet даёт 5 стилей: friendlier / formal / shorter
  /// / longer / proofread. Кнопка «Применить» подменяет содержимое composer-а
  /// результатом.
  Future<void> _openRewriteWithAi() async {
    final raw = _controller.text;
    final original = raw.contains('<')
        ? messageHtmlToPlainText(raw)
        : raw;
    final clean = original.trim();
    if (clean.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    await AiTextActionSheet.show(
      context: context,
      title: l10n.ai_action_rewrite,
      original: clean,
      styleVariants: [
        AiStyleVariant(
          id: 'friendly',
          label: l10n.ai_style_friendly,
          icon: Icons.favorite_rounded,
        ),
        AiStyleVariant(
          id: 'formal',
          label: l10n.ai_style_formal,
          icon: Icons.account_balance_rounded,
        ),
        AiStyleVariant(
          id: 'shorter',
          label: l10n.ai_style_shorter,
          icon: Icons.compress_rounded,
        ),
        AiStyleVariant(
          id: 'longer',
          label: l10n.ai_style_longer,
          icon: Icons.expand_rounded,
        ),
        AiStyleVariant(
          id: 'proofread',
          label: l10n.ai_style_proofread,
          icon: Icons.spellcheck_rounded,
        ),
      ],
      initialStyleId: 'friendly',
      run: (styleId) => AppleIntelligence.instance.rewrite(
        clean,
        style: styleId ?? 'friendly',
      ),
      runStream: (styleId) => AppleIntelligence.instance.streamRewrite(
        clean,
        style: styleId ?? 'friendly',
      ),
      applyLabel: l10n.ai_action_apply,
      onApply: (result) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: result,
          selection: TextSelection.collapsed(offset: result.length),
        );
        _scheduleChatDraftSave();
        _recomputeComposerLimits();
        unawaited(ChatHaptics.instance.success());
      },
    );
  }

  /// TL;DR через Apple Intelligence — открывает premium sheet с резюме
  /// (1-2 предложения, на языке сообщения). Доступно только iOS 18.1+/26+
  /// с включённой Apple Intelligence; в меню эта кнопка вообще не появится
  /// если LLM недоступен.
  Future<void> _summarizeMessageWithAi(String rawText) async {
    final stripped = rawText.contains('<')
        ? messageHtmlToPlainText(rawText)
        : rawText;
    final clean = stripped.trim();
    if (clean.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    await AiTextActionSheet.show(
      context: context,
      title: l10n.ai_action_summarize,
      original: clean,
      run: (_) => AppleIntelligence.instance.summarize(clean),
      runStream: (_) => AppleIntelligence.instance.streamSummarize(clean),
    );
  }

  Future<void> _translateMessage(ChatMessage m, String rawText) async {
    final stripped = rawText.contains('<')
        ? messageHtmlToPlainText(rawText)
        : rawText;
    final original = stripped.trim();
    if (original.isEmpty) return;
    final detection =
        await LocalTextLanguageDetector.instance.detect(original);
    if (!mounted) return;
    final ui = Localizations.localeOf(context).languageCode.toLowerCase();
    // Резолвим from: detected → ui → en. Если не поддерживается ML Kit —
    // sheet нарисует ошибку и даст выбрать другой source.
    var from = detection.language;
    if (from.isEmpty ||
        !LocalMessageTranslator.instance.supportsLanguage(from)) {
      from = LocalMessageTranslator.instance.supportsLanguage(ui) ? ui : 'en';
    }
    // Резолвим target. Если from == ui — берём 'en' (а если ui сам english,
    // то 'ru' как разумный второй язык). Иначе — ui, если он поддерживается,
    // иначе 'en'.
    String to;
    if (from == ui) {
      to = ui == 'en' ? 'ru' : 'en';
    } else {
      to = LocalMessageTranslator.instance.supportsLanguage(ui) ? ui : 'en';
    }
    if (to == from) to = from == 'en' ? 'ru' : 'en';

    await MessageTranslationSheet.show(
      context,
      messageId: m.id,
      originalText: original,
      from: from,
      to: to,
    );
  }

  /// Озвучивает текст через нативный TTS. Перед чтением — детект языка
  /// (через тот же `LocalTextLanguageDetector`), чтобы движок выбрал
  /// правильный голос.
  Future<void> _readMessageAloud(String rawText) async {
    final stripped =
        rawText.contains('<') ? messageHtmlToPlainText(rawText) : rawText;
    final text = stripped.trim();
    if (text.isEmpty) return;
    String? langTag;
    try {
      final det = await LocalTextLanguageDetector.instance.detect(text);
      if (det.isReliable) langTag = det.language;
    } catch (_) {/* fall back to system locale */}
    await LocalTextToSpeech.instance.speak(text: text, languageTag: langTag);
  }

  Future<void> _pinMessage(
    ChatMessage m,
    User user,
    ConversationWithId? convWrap,
    bool isGroup,
    String? otherId,
    UserProfile? profile, {
    String? e2eeDecryptedText,
  }) async {
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
      decryptedText: e2eeDecryptedText,
    );
    final next = [...existing, entry];
    try {
      await repo.setPinnedMessages(
        conversationId: widget.conversationId,
        pins: next,
      );
      unawaited(ChatHaptics.instance.tick());
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
      unawaited(ChatHaptics.instance.tick());
    } catch (e) {
      if (mounted) _toast(l10n.chat_unpin_failed(e));
    }
  }

  bool _isMessageSendingByMe(ChatMessage m, String currentUserId) {
    if (m.senderId != currentUserId) return false;
    if (m.id.startsWith(kLocalOutboxMessageIdPrefix)) return false;
    return (m.deliveryStatus ?? '') == 'sending';
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
      appLogger.w('cancel stale-pending message $m.id failed', error: e);
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
    String? e2eeDecryptedText,
    bool e2eeDecryptionFailed = false,
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
    if (_isMessageSendingByMe(m, user.uid)) {
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
    // Для E2EE сообщения текст в `m.text` пустой — берём расшифрованный.
    final menuTextSource = (e2eeDecryptedText ?? m.text ?? '').trim();
    final hasMenuText =
        menuTextSource.isNotEmpty &&
        (menuTextSource.contains('<')
            ? messageHtmlToPlainText(menuTextSource).trim().isNotEmpty
            : true);

    final secretRestrictions = convWrap?.data.secretChat?.restrictions;
    final allowCopy = !(secretRestrictions?.noCopy == true);
    final allowForward = !(secretRestrictions?.noForward == true);

    // Можно ли предложить перевод: язык текста ≠ UI-локали и ML Kit
    // поддерживает пару. Детектим заранее (на момент показа меню), чтобы
    // сразу отрисовать пункт «Translate» — без задержки.
    final canTranslate = await _canTranslateMessage(menuTextSource);
    if (!mounted) return;

    // AI TL;DR — только если устройство поддерживает Foundation Models
    // и текст достаточно длинный (короткие сообщения суммаризовать незачем).
    final aiAvailable = await AppleIntelligence.instance.isAvailable();
    final menuPlain = menuTextSource.contains('<')
        ? messageHtmlToPlainText(menuTextSource)
        : menuTextSource;
    final canSummarizeAi = aiAvailable && menuPlain.trim().length >= 80;
    if (!mounted) return;

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
      canTranslate: canTranslate,
      canSummarizeAi: canSummarizeAi,
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
        unawaited(ChatHaptics.instance.success());
        if (mounted) _toast(AppLocalizations.of(context)!.chat_text_copied);
      case MessageMenuActionType.translate:
        await _translateMessage(m, menuTextSource);
      case MessageMenuActionType.summarizeAi:
        await _summarizeMessageWithAi(menuTextSource);
      case MessageMenuActionType.readAloud:
        await _readMessageAloud(menuTextSource);
      case MessageMenuActionType.edit:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startInlineEdit(m);
        });
      case MessageMenuActionType.pin:
        await _pinMessage(
          m,
          user,
          convWrap,
          isGroup,
          otherId,
          profile,
          e2eeDecryptedText: e2eeDecryptedText,
        );
      case MessageMenuActionType.star:
        await _toggleMessageStar(
          message: m,
          currentUserId: user.uid,
          isStarredNow: starredMessageIds.contains(m.id),
        );
      case MessageMenuActionType.createSticker:
        final att = messageMenuCreateStickerAttachmentCandidate(m);
        if (att == null) return;
        final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
        if (stickerRepo == null) {
          _toast(AppLocalizations.of(context)!.chat_service_unavailable);
          return;
        }
        await saveAttachmentToMyStickersFlow(
          context: context,
          repo: stickerRepo,
          userId: user.uid,
          attachment: att,
          onToast: _toast,
        );
      case MessageMenuActionType.saveToMyStickers:
        final att = messageMenuStickerAttachmentCandidate(m);
        if (att == null) return;
        final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
        if (stickerRepo == null) {
          _toast(AppLocalizations.of(context)!.chat_service_unavailable);
          return;
        }
        await saveAttachmentToMyStickersFlow(
          context: context,
          repo: stickerRepo,
          userId: user.uid,
          attachment: att,
          onToast: _toast,
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
        unawaited(ChatHaptics.instance.success());
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
      case MessageMenuActionType.report:
        if (!mounted) return;
        // ignore: use_build_context_synchronously — mounted checked above
        await showReportSheet(
          context,
          reportedUserId: m.senderId,
          conversationId: widget.conversationId,
          messageId: m.id,
          // Sender name: use loaded profile when it's a 1:1 chat with this sender
          messageSenderName:
              m.senderId == otherId ? profile?.name : null,
          messageText: m.text,
        );
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

    // Защитный guard: пользователь мог отправить через keyboard, пока кнопка
    // ещё не успела перерисоваться, или экспериментально через accessibility-
    // shortcut. Не пускаем дальше, если лимит вложений превышен — иначе:
    //  * E2EE: упадём с E2eeAttachmentSendLimitException в outbox-пайплайне;
    //  * обычный чат: получим PERMISSION_DENIED от firestore.rules после
    //    загрузки в Storage (бесполезный трафик и failed-message).
    final limitsSnapshot = _composerLimitsState;
    if (limitsSnapshot != null &&
        limitsSnapshot.isOverLimit &&
        _pendingAttachments.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final String msg;
      if (limitsSnapshot.isOverFiles) {
        msg = l10n.composer_limit_too_many_files(
          limitsSnapshot.currentCount,
          limitsSnapshot.limits.maxFiles,
          limitsSnapshot.excessFiles,
        );
      } else {
        final cap = limitsSnapshot.limits.maxTotalBytes ?? 0;
        final used = limitsSnapshot.currentBytes ?? 0;
        msg = l10n.composer_limit_total_size_exceeded(
          formatComposerBytesMb(used),
          formatComposerBytesMb(cap),
        );
      }
      _toast(msg);
      return;
    }

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
        // E2EE-edit: репозиторий перезаписал `lastMessageText` плейсхолдером.
        // Кладём настоящий plaintext в локальный preview-кэш с тем же `ts`,
        // что у редактируемого сообщения (createdAt не меняется при правке),
        // чтобы ChatListScreen отобразил обновление вместо плейсхолдера.
        if (editEnvelope != null &&
            _editingCreatedAt != null &&
            plainOut.isNotEmpty) {
          var preview = plainOut;
          if (preview.length > 240) preview = preview.substring(0, 240);
          unawaited(
            E2eePlaintextCache.instance.putPreview(
              conversationId: widget.conversationId,
              text: preview,
              ts: _editingCreatedAt!,
              messageId: editingId,
            ),
          );
        }
        if (!mounted) return;
        setState(() {
          _editingMessageId = null;
          _editingPreviewPlain = null;
          _editingCreatedAt = null;
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
          _composerLimitsState = null;
          _controller.clear();
          _replyingTo = null;
          _composerFormattingOpen = false;
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
      final restoreReply = _replyingTo;
      final restoreFormatting = _composerFormattingOpen;
      setState(() {
        _pendingAttachments.clear();
        _composerLimitsState = null;
        _controller.clear();
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
              convIsE2ee: convIsE2ee,
              e2eeEncryptText: effectiveE2eePolicy.text,
              e2eeEncryptMedia: effectiveE2eePolicy.media,
              e2eeEpoch: e2eeEpoch,
            );
      } catch (e) {
        if (mounted) {
          setState(() {
            _pendingAttachments
              ..clear()
              ..addAll(pending);
            _controller.text = rawComposer;
            _replyingTo = restoreReply;
            _composerFormattingOpen = restoreFormatting;
          });
          _recomputeComposerLimits();
          _toast(AppLocalizations.of(context)!.chat_send_failed(e));
        }
        return;
      }
      if (mounted) {
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
    if (_videoCircleSendBusy) return;
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
    if (_videoCircleSendBusy) return;
    _videoCircleSendBusy = true;
    final lower = raw.path.toLowerCase();
    final ext = lower.endsWith('.mov') || lower.endsWith('.qt') ? 'mov' : 'mp4';
    final mime = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    final name = 'video-circle_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = XFile(raw.path, mimeType: mime);
    final policy = _resolveEffectiveE2eePolicyForChat(uid);
    final replySnap = _stripReplyPreviewByPolicy(_replyingTo, policy);
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
      _videoCircleSendBusy = false;
    }
  }

  Future<void> _sendVoiceMessage(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _voiceSendBusy) return;
    final rec = await showVoiceMessageRecordSheet(context);
    if (!mounted || rec == null) return;
    await _sendVoiceMessageFromRecord(uid, rec);
  }

  Future<void> _sendVoiceMessageFromRecord(
    String uid,
    VoiceMessageRecordResult rec,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null || _voiceSendBusy) return;
    _voiceSendBusy = true;
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
      _voiceSendBusy = false;
      unawaited(_deleteFileSilently(rec.filePath));
    }
  }

  Future<void> _deleteFileSilently(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  void _openStickersGifPanel() {
    unawaited(_openStickersGifPanelImpl());
  }

  /// Удерживает «пол» под composer'ом на время переключения keyboard↔panel,
  /// чтобы поле ввода не уезжало вниз и не было видно «прыжка» содержимого
  /// чата. [hold] — fallback-таймер на случай, если клавиатура так и не
  /// поднимется. Основной сценарий очистки — `didChangeMetrics`
  /// (см. ниже): как только kbInset догнал floor, floor сбрасывается
  /// синхронно, и composer не дёргается.
  void _holdStickersFooterTransition(
    double height, {
    Duration hold = const Duration(milliseconds: 800),
  }) {
    if (!mounted || height <= 0) return;
    _stickersTransitionFooterTimer?.cancel();
    setState(() => _stickersTransitionFooterFloor = height);
    _stickersTransitionFooterTimer = Timer(hold, () {
      if (!mounted) return;
      setState(() => _stickersTransitionFooterFloor = 0);
    });
  }

  Future<void> _openStickersGifPanelImpl() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast(AppLocalizations.of(context)!.forward_error_not_authorized);
      return;
    }
    final stickerRepo = ref.read(userStickerPacksRepositoryProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    if (stickerRepo == null || chatRepo == null) {
      _toast(AppLocalizations.of(context)!.chat_service_unavailable);
      return;
    }
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > 0 &&
        (keyboardInset - _lastKeyboardHeight).abs() > 0.5) {
      _lastKeyboardHeight = keyboardInset;
    }
    _captureKeyboardHeight();
    final hadKeyboard = keyboardInset > 0;
    // Фиксируем высоту шторки СЕЙЧАС: реальный kbInset > всё остальное,
    // иначе lastKb, иначе дефолт 42% экрана. Эта величина живёт всё
    // время пока панель открыта и не пересматривается при дальнейших
    // обновлениях `_lastKeyboardHeight` (которые иначе схлопывают
    // панель вместе с убегающей клавиатурой).
    final lockedH = keyboardInset > 0
        ? keyboardInset
        : (_lastKeyboardHeight > 0
              ? _lastKeyboardHeight
              : MediaQuery.of(context).size.height * 0.42);
    if (mounted) {
      setState(() {
        _composerTextBeforeStickerSearch = _controller.text;
        _controller.clear();
        _stickersSearchQuery = '';
        _stickersPanelFullscreen = false;
        _stickerPanelLockedHeight = lockedH;
        _stickersPanelOpen = true;
      });
    }
    if (hadKeyboard) {
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    }
  }

  void _switchFromStickersToKeyboard() {
    // Используем locked-snapshot — захваченную при открытии шторки
    // высоту, она = реальной kb на тот момент. `_lastKeyboardHeight`
    // здесь брать НЕЛЬЗЯ: didChangeMetrics во время iOS-анимации
    // скрытия kb тянет его вниз, и к моменту тапа на иконку
    // клавиатуры он может оказаться ≈0 (хотя теперь monotonic-grow
    // в _captureKeyboardHeight это страхует).
    final hold = _stickerPanelLockedHeight > 0
        ? _stickerPanelLockedHeight
        : (_lastKeyboardHeight > 0
              ? _lastKeyboardHeight
              : MediaQuery.of(context).size.height * 0.42);
    _holdStickersFooterTransition(hold);
    _closeStickersPanel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocusNode.requestFocus();
    });
  }

  void _closeStickersPanel() {
    if (!mounted) return;
    setState(() {
      _stickersPanelOpen = false;
      _controller.text = _composerTextBeforeStickerSearch ?? _controller.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _composerTextBeforeStickerSearch = null;
      _stickersPanelFullscreen = false;
      _stickersSearchQuery = '';
      _stickerPanelLockedHeight = 0;
    });
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

  void _handleEmojiPickFromStickersPanel(String emoji) {
    _closeStickersPanel();
    _insertEmojiIntoComposer(emoji);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocusNode.requestFocus();
    });
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
              _recomputeComposerLimits();
              break;
            case 'camera_photo':
              final x = await picker.pickImage(source: ImageSource.camera);
              if (!mounted || x == null) return;
              setState(() => _pendingAttachments.add(x));
              _scheduleChatDraftSave();
              _recomputeComposerLimits();
              break;
            case 'camera_video':
              final xv = await picker.pickVideo(source: ImageSource.camera);
              if (!mounted || xv == null) return;
              setState(() => _pendingAttachments.add(xv));
              _scheduleChatDraftSave();
              _recomputeComposerLimits();
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
            _recomputeComposerLimits();
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
        _openStickersGifPanel();
        break;
      case ComposerAttachmentAction.format:
        setState(() => _composerFormattingOpen = true);
        break;
      case ComposerAttachmentAction.scanDocument:
        try {
          final paths = await DocumentScanner.instance.scan();
          if (!mounted || paths.isEmpty) return;
          // Preview screen — пользователь может удалить страницы,
          // переупорядочить, переснять отдельную, добавить ещё.
          final curated = await DocumentScannerPreviewScreen.open(
            context,
            initialPaths: paths,
          );
          if (!mounted || curated == null || curated.isEmpty) return;
          final add = curated
              .map((p) => XFile(p, name: p.split(Platform.pathSeparator).last))
              .toList();
          setState(() => _pendingAttachments.addAll(add));
          _scheduleChatDraftSave();
          _recomputeComposerLimits();
        } catch (e) {
          if (mounted) {
            _toast(AppLocalizations.of(context)!.chat_file_pick_failed(e));
          }
        }
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
