import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../data/sanitize_message_html.dart';
import '../data/chat_poll_stub_text.dart';
import '../data/chat_emoji_only.dart';
import '../data/video_circle_utils.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/link_preview_url_extractor.dart';
import '../data/user_profile.dart';
import 'chat_date_capsule.dart';
import 'chat_system_event_divider.dart';
import 'message_attachments.dart';
import 'message_bubble_delivery_icons.dart';
import 'message_chat_poll.dart';
import 'message_deleted_stub.dart';
import 'message_location_card.dart';
import 'message_html_text.dart';
import 'message_link_preview_card.dart';
import 'group_member_profile_sheet.dart';
import 'message_reactions_row.dart';
import 'message_reply_preview.dart';
import 'message_swipe_to_reply.dart';

typedef ChatMessageVisibleCallback =
    void Function(ChatMessage message, double visibleFraction);

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.messagesDesc,
    required this.currentUserId,
    required this.conversationId,
    this.reversed = false,
    this.conversation,
    required this.scrollController,
    this.onNearOldestEdge,
    this.unreadSeparatorMessageId,
    this.onAtBottomChanged,
    this.atBottomThresholdPx = 56,
    this.onMessageVisible,
    this.readVisibleFractionThreshold = 0.12,
    this.messageItemKeys = const <String, GlobalKey>{},
    this.jumpScrollBoostMessageId,
    this.onJumpToMessageId,
    this.selectionMode = false,
    this.selectedMessageIds = const <String>{},
    this.onMessageTap,
    this.onMessageLongPress,
    this.showTimestamps = true,
    this.fontSize = 'medium',
    this.bubbleRadius = 'rounded',
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
    this.outgoingMediaFooter,
    this.onOpenThread,
    this.onOpenMediaGallery,
    this.flashHighlightMessageId,
    this.profileMap,
    this.onToggleReaction,
    this.onRetryMediaNorm,
    this.onEmitEmojiBurstEvent,
    this.onSwipeReply,
    this.onSwipeBack,
    this.e2eeDecryptedTextByMessageId,
    this.e2eeDecryptionFailedMessageIds,
  });

  final List<ChatMessage> messagesDesc;
  final String currentUserId;
  final String conversationId;
  final bool reversed;
  final Conversation? conversation;
  final ScrollController scrollController;

  /// Вызов при приближении к самым старым сообщениям (подгрузка истории).
  final VoidCallback? onNearOldestEdge;

  /// id сообщения, возле которого показывается разделитель «Непрочитанные сообщения».
  final String? unreadSeparatorMessageId;

  /// Уведомление родителя о состоянии «у низа».
  final ValueChanged<bool>? onAtBottomChanged;

  /// Порог (px) для определения «у низа» списка.
  final double atBottomThresholdPx;
  final ChatMessageVisibleCallback? onMessageVisible;
  final double readVisibleFractionThreshold;

  /// Ключи строк для [Scrollable.ensureVisible] (закреплённое, ответ, якорь истории).
  final Map<String, GlobalKey> messageItemKeys;

  /// Увеличивает [CustomScrollView.cacheExtent], пока цель вне viewport (иначе у [GlobalKey] нет context).
  final String? jumpScrollBoostMessageId;
  final void Function(String messageId)? onJumpToMessageId;
  final bool selectionMode;
  final Set<String> selectedMessageIds;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final bool showTimestamps;
  final String fontSize;
  final String bubbleRadius;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  /// Исходящий альбом с локальными превью и прогрессом загрузки (ниже последнего дня).
  final Widget? outgoingMediaFooter;

  /// Бейдж с числом ответов в ветке (тап — экран обсуждения).
  final void Function(ChatMessage message)? onOpenThread;

  /// Полноэкранная галерея фото/видео (паритет веба).
  final void Function(ChatAttachment attachment, ChatMessage message)?
  onOpenMediaGallery;

  /// Подсветка строки ~2 с после перехода к сообщению.
  final String? flashHighlightMessageId;
  final Map<String, UserProfile>? profileMap;
  final Future<void> Function(ChatMessage message, String emoji)?
  onToggleReaction;
  final Future<void> Function(ChatMessage message)? onRetryMediaNorm;
  final Future<void> Function(
    ChatMessage message,
    String emoji,
    String eventId,
  )?
  onEmitEmojiBurstEvent;

  /// Свайп **влево** по строке сообщения — быстрый ответ (основной чат и ветки).
  final void Function(ChatMessage message)? onSwipeReply;

  /// Свайп **вправо** — назад (например [Navigator.pop] / `context.pop`).
  final VoidCallback? onSwipeBack;

  /// Предвычисленные plaintext'ы для E2EE-сообщений (Phase 4).
  ///
  /// Ключ — `ChatMessage.id`, значение — расшифрованный HTML (как у обычных
  /// сообщений). Если запись отсутствует:
  /// - когда `e2eeDecryptionFailedMessageIds` содержит id — показываем
  ///   «Не удалось расшифровать»;
  /// - иначе — «Зашифрованное сообщение» (ещё не расшифровано, либо read-only
  ///   placeholder как было до Phase 4).
  ///
  /// Решение: не делаем async-decrypt в widget'е списка, чтобы не завязывать
  /// этот файл на Riverpod/Firestore — оркестратор в [chat_screen] заполняет
  /// карту и передаёт её сюда.
  final Map<String, String>? e2eeDecryptedTextByMessageId;
  final Set<String>? e2eeDecryptionFailedMessageIds;

  static String dayKey(DateTime dt) {
    final d = dt.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

ScrollPhysics _chatMessageListPhysics() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
  return const ClampingScrollPhysics();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static final Set<String> _sessionSeenEmojiBurstEventIds = <String>{};

  bool _didInitialScroll = false;

  /// Один post-frame цикл [jumpTo] на сессию: иначе каждый [build] ставил новый
  /// callback и при частых перестроениях ломались layout/semantics.
  bool _initialScrollPostFrameScheduled = false;
  final ValueNotifier<String?> _videoCirclePlayingSlotId =
      ValueNotifier<String?>(null);

  /// Ключи на первое сообщение календарного дня — для одной плавающей капсулы даты.
  final Map<String, GlobalKey> _dayStartKeys = <String, GlobalKey>{};

  /// Последняя группировка по дням (синхронно с текущим build).
  List<List<ChatMessage>> _cachedGroups = <List<ChatMessage>>[];

  String? _stickyDayLabel;
  bool _stickyDayUpdateScheduled = false;
  _EmojiBurstTrigger? _emojiBurstTrigger;
  int _emojiBurstRunId = 0;
  int _emojiBurstEventSeq = 0;
  final Set<String> _seenEmojiBurstEventIds = <String>{};
  bool? _lastAtBottomReported;

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onAtBottomChanged != widget.onAtBottomChanged ||
        oldWidget.reversed != widget.reversed ||
        oldWidget.atBottomThresholdPx != widget.atBottomThresholdPx) {
      _lastAtBottomReported = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyAtBottomByController();
      });
    }
    if (oldWidget.conversationId != widget.conversationId) {
      _didInitialScroll = false;
      _initialScrollPostFrameScheduled = false;
      _videoCirclePlayingSlotId.value = null;
      _dayStartKeys.clear();
      _stickyDayLabel = null;
      _emojiBurstTrigger = null;
      _seenEmojiBurstEventIds.clear();
      _emojiBurstEventSeq = 0;
      _lastAtBottomReported = null;
    } else if (oldWidget.messagesDesc.length != widget.messagesDesc.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyStickyDayLabel(),
      );
    }
    if (widget.messagesDesc.isEmpty) {
      _stickyDayLabel = null;
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollControllerTick);
    _videoCirclePlayingSlotId.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyAtBottomByController();
    });
  }

  void _onScrollControllerTick() {
    _scheduleStickyDayUpdate();
    _notifyAtBottomByController();
  }

  void _notifyAtBottomByController() {
    if (widget.onAtBottomChanged == null) return;
    final c = widget.scrollController;
    if (!c.hasClients) return;
    _notifyAtBottomByMetrics(c.position);
  }

  bool _isAtBottom(ScrollMetrics m) {
    final threshold = widget.atBottomThresholdPx.clamp(0.0, 240.0);
    if (widget.reversed) {
      return (m.pixels - m.minScrollExtent).abs() <= threshold;
    }
    return (m.maxScrollExtent - m.pixels).abs() <= threshold;
  }

  void _notifyAtBottomByMetrics(ScrollMetrics m) {
    final cb = widget.onAtBottomChanged;
    if (cb == null) return;
    final atBottom = _isAtBottom(m);
    if (_lastAtBottomReported == atBottom) return;
    _lastAtBottomReported = atBottom;
    cb(atBottom);
  }

  void _scheduleStickyDayUpdate() {
    if (_stickyDayUpdateScheduled) return;
    _stickyDayUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stickyDayUpdateScheduled = false;
      if (mounted) _applyStickyDayLabel();
    });
  }

  void _applyStickyDayLabel() {
    if (!mounted) return;
    final next = _computeVisibleDayLabel();
    if (next == null) return;
    if (next != _stickyDayLabel) {
      setState(() => _stickyDayLabel = next);
    }
  }

  /// День «у верхнего края» списка: последний по порядку дней, чей маркер уже прошёл линию.
  String? _computeVisibleDayLabel() {
    final groups = _cachedGroups;
    if (groups.isEmpty) return null;

    RenderBox? vp;
    for (final g in groups) {
      final dk = ChatMessageList.dayKey(g.first.createdAt);
      final ctx = _dayStartKeys[dk]?.currentContext;
      if (ctx == null) continue;
      final obj = ctx.findRenderObject();
      if (obj == null) continue;
      final abstractVp = RenderAbstractViewport.maybeOf(obj);
      if (abstractVp != null) {
        vp = abstractVp as RenderBox;
        break;
      }
    }

    if (vp == null) {
      return _stickyDayLabel ??
          formatChatDayLabelRu(groups.last.first.createdAt.toLocal());
    }

    const stickyLineY = 28.0;
    String? picked;
    for (final g in groups) {
      final dk = ChatMessageList.dayKey(g.first.createdAt);
      final ctx = _dayStartKeys[dk]?.currentContext;
      if (ctx == null) continue;
      final ro = ctx.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      final y = ro.localToGlobal(Offset.zero, ancestor: vp).dy;
      if (y <= stickyLineY) {
        picked = formatChatDayLabelRu(g.first.createdAt.toLocal());
      }
    }

    return picked ??
        formatChatDayLabelRu(groups.first.first.createdAt.toLocal());
  }

  List<List<ChatMessage>> _groupByDay(List<ChatMessage> asc) {
    if (asc.isEmpty) return <List<ChatMessage>>[];
    final out = <List<ChatMessage>>[];
    for (final m in asc) {
      if (out.isEmpty) {
        out.add(<ChatMessage>[m]);
      } else {
        final last = out.last;
        if (ChatMessageList.dayKey(last.last.createdAt) ==
            ChatMessageList.dayKey(m.createdAt)) {
          last.add(m);
        } else {
          out.add(<ChatMessage>[m]);
        }
      }
    }
    return out;
  }

  void _maybeInitialScrollToBottom(List<ChatMessage> asc) {
    if (asc.isEmpty || _didInitialScroll) return;
    if (_initialScrollPostFrameScheduled) return;
    _initialScrollPostFrameScheduled = true;

    double? lastMax;
    var stableFrames = 0;
    var frames = 0;
    const maxFrames = 24;
    final startedAt = DateTime.now();
    const maxNoClientWait = Duration(seconds: 4);
    void tick(Duration? _) {
      if (!mounted) return;
      if (_didInitialScroll) {
        _initialScrollPostFrameScheduled = false;
        return;
      }
      final c = widget.scrollController;
      if (!c.hasClients) {
        if (DateTime.now().difference(startedAt) > maxNoClientWait) {
          // Не фиксируем _didInitialScroll=true: дадим следующему build попробовать снова.
          _initialScrollPostFrameScheduled = false;
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback(tick);
        return;
      }
      final max = c.position.maxScrollExtent;
      final target = widget.reversed ? c.position.minScrollExtent : max;
      c.jumpTo(target);
      frames++;
      if (lastMax != null && (max - lastMax!).abs() < 1.0) {
        stableFrames++;
      } else {
        stableFrames = 0;
      }
      lastMax = max;
      if (stableFrames >= 2 || frames >= maxFrames) {
        _didInitialScroll = true;
        _initialScrollPostFrameScheduled = false;
        _scheduleStickyDayUpdate();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback(tick);
    }

    WidgetsBinding.instance.addPostFrameCallback(tick);
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (widget.onNearOldestEdge == null) return false;
    if (n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    if (!m.hasViewportDimension || !m.hasPixels) return false;
    if (widget.reversed) {
      if (m.pixels < m.maxScrollExtent - 280) return false;
    } else {
      if (m.pixels > m.minScrollExtent + 280) return false;
    }

    // Не реагировать на программный скролл (ensureVisible после подгрузки истории) —
    // иначе у верхнего края снова запускается _limit и скролл «залипает».
    final userDriven =
        n is UserScrollNotification ||
        (n is ScrollUpdateNotification && n.dragDetails != null) ||
        n is ScrollEndNotification;
    if (!userDriven) return false;

    widget.onNearOldestEdge!();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final asc = List<ChatMessage>.from(widget.messagesDesc)
      ..sort((a, b) {
        final t = widget.reversed
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt);
        if (t != 0) return t;
        return widget.reversed ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
      });

    _maybeInitialScrollToBottom(asc);
    final pendingSyncedEmoji = _takePendingSyncedEmojiBurst(asc);
    if (pendingSyncedEmoji != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerEmojiBurst(pendingSyncedEmoji);
      });
    }

    final groups = _groupByDay(asc);
    _cachedGroups = groups;
    final validDayKeys = groups
        .map((g) => ChatMessageList.dayKey(g.first.createdAt))
        .toSet();
    _dayStartKeys.removeWhere((k, _) => !validDayKeys.contains(k));

    if (groups.isNotEmpty && _stickyDayLabel == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyStickyDayLabel(),
      );
    }

    final slivers = <Widget>[];
    final unreadSeparatorId = widget.unreadSeparatorMessageId;

    // For reversed chat lists (newest at bottom), the "outgoing footer" must be
    // inserted BEFORE message slivers so it appears near the composer.
    if (widget.outgoingMediaFooter != null && widget.reversed) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: widget.outgoingMediaFooter!,
          ),
        ),
      );
    }

    for (final g in groups) {
      if (g.isEmpty) continue;
      final dayKey = ChatMessageList.dayKey(g.first.createdAt);
      final separatorMessageIndex = unreadSeparatorId == null
          ? -1
          : g.indexWhere((m) => m.id == unreadSeparatorId);
      final hasSeparatorInDay = separatorMessageIndex >= 0;
      final separatorChildIndex = hasSeparatorInDay
          ? (widget.reversed
                ? separatorMessageIndex + 1
                : separatorMessageIndex)
          : -1;
      final childCount = g.length + (hasSeparatorInDay ? 1 : 0);
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            if (hasSeparatorInDay && i == separatorChildIndex) {
              return _buildUnreadSeparatorRow();
            }
            final messageIndex = hasSeparatorInDay && i > separatorChildIndex
                ? i - 1
                : i;
            final m = g[messageIndex];
            // Phase 8: system-события E2EE рендерятся как timeline-divider
            // вместо bubble. Маркируются `senderId == '__system__'` и непустым
            // `systemEvent`. Не шифруются, поэтому попадают сюда напрямую.
            if (m.systemEvent != null && m.senderId == '__system__') {
              return ChatSystemEventDivider(
                key: ValueKey<String>('sys-evt-${m.id}'),
                event: m.systemEvent!,
                actorName: () {
                  final actorId =
                      m.systemEvent!.data?['actorUserId'] as String?;
                  if (actorId == null) return null;
                  final profile = widget.profileMap?[actorId];
                  return profile?.name;
                }(),
              );
            }
            final mine = m.senderId == widget.currentUserId;
            final bubble = RepaintBoundary(
              key: ValueKey<String>('msg-row-${m.id}'),
              child: _ChatMessageBubble(
                message: m,
                isMine: mine,
                currentUserId: widget.currentUserId,
                conversationId: widget.conversationId,
                conversation: widget.conversation,
                selectionMode: widget.selectionMode,
                selected: widget.selectedMessageIds.contains(m.id),
                onMessageTap: widget.onMessageTap,
                onMessageLongPress: widget.onMessageLongPress,
                onJumpToMessageId: widget.onJumpToMessageId,
                showTimestamps: widget.showTimestamps,
                fontSize: widget.fontSize,
                bubbleRadius: widget.bubbleRadius,
                outgoingBubbleColor: widget.outgoingBubbleColor,
                incomingBubbleColor: widget.incomingBubbleColor,
                videoCirclePlayingSlotId: _videoCirclePlayingSlotId,
                onOpenThread: widget.onOpenThread,
                onOpenMediaGallery: widget.onOpenMediaGallery,
                profileMap: widget.profileMap,
                onToggleReaction: widget.onToggleReaction,
                onRetryMediaNorm: widget.onRetryMediaNorm,
                onSingleEmojiTap: _handleSingleEmojiTap,
                e2eeDecryptedText:
                    widget.e2eeDecryptedTextByMessageId?[m.id],
                e2eeDecryptionFailed:
                    widget.e2eeDecryptionFailedMessageIds?.contains(m.id) ??
                        false,
              ),
            );
            final rowKey = widget.messageItemKeys[m.id];
            Widget padded = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: bubble,
            );
            if (widget.flashHighlightMessageId == m.id) {
              final cs = Theme.of(context).colorScheme;
              padded = DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  border: Border(
                    left: BorderSide(
                      color: cs.primary.withValues(alpha: 0.82),
                      width: 3,
                    ),
                  ),
                ),
                child: padded,
              );
            }
            if ((widget.onSwipeReply != null || widget.onSwipeBack != null) &&
                !widget.selectionMode) {
              // Live swipe-to-reply: the row follows the finger to the
              // left and a reply icon appears on the right. Disabled for
              // deleted messages so a swipe over a tombstone is a no-op.
              padded = MessageSwipeToReply(
                enabled: !m.isDeleted,
                onSwipeReply: widget.onSwipeReply == null
                    ? null
                    : () => widget.onSwipeReply!.call(m),
                onSwipeBack: widget.onSwipeBack,
                child: padded,
              );
            }
            Widget row = messageIndex == 0
                ? KeyedSubtree(
                    key: _dayStartKeys.putIfAbsent(dayKey, GlobalKey.new),
                    child: padded,
                  )
                : padded;
            if (rowKey != null) {
              row = KeyedSubtree(key: rowKey, child: row);
            }
            if (widget.onMessageVisible != null) {
              final threshold = widget.readVisibleFractionThreshold.clamp(
                0.01,
                1.0,
              );
              row = VisibilityDetector(
                key: ValueKey<String>(
                  'msg-vis-${widget.conversationId}-${m.id}',
                ),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction < threshold) return;
                  widget.onMessageVisible?.call(m, info.visibleFraction);
                },
                child: row,
              );
            }
            return row;
          }, childCount: childCount),
        ),
      );
    }

    if (widget.outgoingMediaFooter != null && !widget.reversed) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: widget.outgoingMediaFooter!,
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));

    final boostJump =
        widget.jumpScrollBoostMessageId != null &&
        widget.jumpScrollBoostMessageId!.isNotEmpty;

    final stickyFallback = groups.isEmpty
        ? null
        : formatChatDayLabelRu(
            (widget.reversed ? groups.first : groups.last).first.createdAt
                .toLocal(),
          );
    // Без сообщений не показываем капсулу даты — иначе остаётся подпись от прошлого чата.
    final stickyDisplay = asc.isEmpty
        ? null
        : (_stickyDayLabel ?? stickyFallback);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            controller: widget.scrollController,
            reverse: widget.reversed,
            physics: _chatMessageListPhysics(),
            cacheExtent: boostJump ? 24000 : 900,
            slivers: slivers,
          ),
          if (stickyDisplay != null)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: ChatBlurredDateCapsule(label: stickyDisplay),
                ),
              ),
            ),
          if (_emojiBurstTrigger case final burst?)
            Positioned.fill(
              child: _EmojiBurstOverlay(
                key: ValueKey<int>(burst.runId),
                emoji: burst.emoji,
                onFinished: () {
                  if (!mounted) return;
                  if (_emojiBurstTrigger?.runId == burst.runId) {
                    setState(() => _emojiBurstTrigger = null);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnreadSeparatorRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Text(
              'Непрочитанные сообщения',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerEmojiBurst(String emoji) {
    final token = emoji.trim();
    if (token.isEmpty) return;
    setState(() {
      _emojiBurstRunId += 1;
      _emojiBurstTrigger = _EmojiBurstTrigger(
        emoji: token,
        runId: _emojiBurstRunId,
      );
    });
  }

  void _handleSingleEmojiTap(ChatMessage message, String emoji) {
    final token = emoji.trim();
    if (token.isEmpty) return;
    _triggerEmojiBurst(token);
    final eventId = _nextEmojiBurstEventId(message);
    _rememberEmojiBurstEvent(eventId);
    final emit = widget.onEmitEmojiBurstEvent;
    if (emit == null) return;
    unawaited(emit(message, token, eventId));
  }

  String _nextEmojiBurstEventId(ChatMessage message) {
    _emojiBurstEventSeq += 1;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '${widget.currentUserId}-$micros-${message.id}-$_emojiBurstEventSeq';
  }

  String? _takePendingSyncedEmojiBurst(List<ChatMessage> asc) {
    final unseenCandidates = <_SyncedEmojiBurstCandidate>[];
    final ordered = widget.reversed ? asc : asc.reversed;
    for (final m in ordered) {
      final burst = m.emojiBurst;
      if (burst == null) continue;
      final eventId = burst.eventId.trim();
      final emoji = burst.emoji.trim();
      if (eventId.isEmpty || emoji.isEmpty) continue;
      if (_isEmojiBurstEventSeen(eventId)) continue;
      unseenCandidates.add(
        _SyncedEmojiBurstCandidate(eventId: eventId, emoji: emoji),
      );
    }
    if (unseenCandidates.isEmpty) {
      return null;
    }
    // Не проигрываем «пачкой» несколько непросмотренных событий при открытии чата:
    // показываем только самое новое, остальные считаем обработанными.
    for (final candidate in unseenCandidates) {
      _rememberEmojiBurstEvent(candidate.eventId);
    }
    return unseenCandidates.first.emoji;
  }

  bool _isEmojiBurstEventSeen(String eventId) {
    return _seenEmojiBurstEventIds.contains(eventId) ||
        _sessionSeenEmojiBurstEventIds.contains(eventId);
  }

  void _rememberEmojiBurstEvent(String eventId) {
    if (eventId.isEmpty) return;
    _seenEmojiBurstEventIds.add(eventId);
    _sessionSeenEmojiBurstEventIds.add(eventId);
    if (_sessionSeenEmojiBurstEventIds.length > 4000) {
      _sessionSeenEmojiBurstEventIds.clear();
      _sessionSeenEmojiBurstEventIds.addAll(_seenEmojiBurstEventIds);
    }
  }

  bool _handleScrollNotification(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.hasPixels &&
        n.metrics.hasViewportDimension) {
      _notifyAtBottomByMetrics(n.metrics);
    }
    if (n is ScrollUpdateNotification ||
        n is ScrollEndNotification ||
        n is UserScrollNotification) {
      _scheduleStickyDayUpdate();
    }
    return _onScrollNotification(n);
  }
}

class _BubbleMetaLine extends StatelessWidget {
  const _BubbleMetaLine({
    required this.message,
    required this.isMine,
    required this.showTimestamps,
    required this.editedTimeSize,
    required this.onPrimary,
    required this.onSurface,
    required this.timeHmText,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTimestamps;
  final double editedTimeSize;
  final Color onPrimary;
  final Color onSurface;
  final String timeHmText;

  @override
  Widget build(BuildContext context) {
    final showEdited =
        message.updatedAt != null &&
        message.updatedAt!.isNotEmpty &&
        !message.isDeleted;
    if (!showTimestamps && !showEdited) {
      return const SizedBox.shrink();
    }
    final base = isMine ? onPrimary : onSurface;
    final metaColor = base.withValues(alpha: 0.65);
    final editedColor = base.withValues(alpha: 0.5);
    final statusColor = (message.deliveryStatus ?? 'sent') == 'failed'
        ? Colors.redAccent.withValues(alpha: 0.95)
        : metaColor;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showEdited)
            Text(
              'изм.',
              style: TextStyle(
                fontSize: editedTimeSize - 1,
                fontWeight: FontWeight.w800,
                color: editedColor,
                height: 1.1,
              ),
            ),
          if (showEdited && showTimestamps) const SizedBox(width: 4),
          if (showTimestamps)
            Text(
              timeHmText,
              style: TextStyle(
                fontSize: editedTimeSize,
                fontWeight: FontWeight.w800,
                color: metaColor,
                height: 1.1,
              ),
            ),
          if (showTimestamps && isMine) ...[
            const SizedBox(width: 4),
            MessageBubbleDeliveryIcons(
              deliveryStatus: message.deliveryStatus,
              readAt: message.readAt,
              iconColor: statusColor,
              size: editedTimeSize + 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUserId,
    required this.conversationId,
    this.conversation,
    this.selectionMode = false,
    this.selected = false,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onJumpToMessageId,
    this.showTimestamps = true,
    this.fontSize = 'medium',
    this.bubbleRadius = 'rounded',
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
    required this.videoCirclePlayingSlotId,
    this.onOpenThread,
    this.onOpenMediaGallery,
    this.profileMap,
    this.onToggleReaction,
    this.onRetryMediaNorm,
    this.onSingleEmojiTap,
    this.e2eeDecryptedText,
    this.e2eeDecryptionFailed = false,
  });

  final ChatMessage message;
  final bool isMine;
  final String currentUserId;
  final String conversationId;
  final Conversation? conversation;
  final bool selectionMode;
  final bool selected;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final void Function(String messageId)? onJumpToMessageId;
  final bool showTimestamps;
  final String fontSize;
  final String bubbleRadius;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;
  final ValueNotifier<String?> videoCirclePlayingSlotId;
  final void Function(ChatMessage message)? onOpenThread;
  final void Function(ChatAttachment attachment, ChatMessage message)?
  onOpenMediaGallery;
  final Map<String, UserProfile>? profileMap;
  final Future<void> Function(ChatMessage message, String emoji)?
  onToggleReaction;
  final Future<void> Function(ChatMessage message)? onRetryMediaNorm;
  final void Function(ChatMessage message, String emoji)? onSingleEmojiTap;

  /// Phase 4: текст, полученный в результате дешифровки `message.e2ee.ciphertext`.
  /// Если != null — используем вместо placeholder «Зашифрованное сообщение».
  final String? e2eeDecryptedText;

  /// Phase 4: попытка дешифровки завершилась ошибкой (нет ключа эпохи / wrap
  /// не предназначен этому устройству). Показываем «Не удалось расшифровать».
  final bool e2eeDecryptionFailed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textSize = switch (fontSize) {
      'small' => 13.0,
      'large' => 17.0,
      _ => 15.0,
    };
    final editedTimeSize = switch (fontSize) {
      'small' => 10.0,
      'large' => 12.0,
      _ => 11.0,
    };
    final radius = bubbleRadius == 'square' ? 8.0 : 16.0;
    final incomingDefault = scheme.brightness == Brightness.dark
        ? const Color(0xFF2A2D34).withValues(alpha: 0.92)
        : Colors.white;
    if (message.isDeleted) {
      return MessageDeletedStub(alignRight: isMine);
    }
    // Phase 4: если для этого сообщения есть дешифрованный текст, используем
    // его вместо `message.text` (там шифротекст отсутствует, как и ожидается).
    // Если попытка была и провалилась — подставляем фиксированный placeholder.
    final decryptedText = e2eeDecryptedText;
    final decryptionFailed = e2eeDecryptionFailed;
    final rawSource = decryptedText ?? (message.text ?? '');
    final raw = rawSource;
    final html = raw.contains('<') ? sanitizeMessageHtml(raw) : raw;
    final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;
    final hasRawText = plain.trim().isNotEmpty;
    final hasMedia = message.attachments.isNotEmpty;
    final pollId = (message.chatPollId ?? '').trim();
    final hasPoll = pollId.isNotEmpty;
    final hasLocation = message.locationShare != null;
    final hasE2eeOnlyCiphertext =
        message.hasE2eeCiphertext &&
        decryptedText == null &&
        !hasRawText &&
        !hasMedia &&
        !hasPoll &&
        !hasLocation;
    final String e2eeFallback = decryptionFailed
        ? 'Не удалось расшифровать. Откройте Настройки → Устройства'
        : 'Зашифрованное сообщение';
    final displayPlain = hasE2eeOnlyCiphertext ? e2eeFallback : plain;
    final hasText = displayPlain.trim().isNotEmpty;
    final pollStubCaption =
        hasPoll && hasText && isChatPollStubCaptionPlain(displayPlain);
    final hasVisibleText = hasText && !pollStubCaption;
    final isPureEmoji =
        hasText &&
        isOnlyEmojisMessage(html) &&
        !hasMedia &&
        !hasPoll &&
        message.replyTo == null &&
        !hasLocation;
    final singlePureEmoji = isPureEmoji
        ? _singleEmojiFromOnlyEmojiMessage(displayPlain)
        : null;
    final linkPreviewUrl = (!hasMedia && !hasPoll && !hasLocation && hasVisibleText)
        ? extractFirstHttpUrl(displayPlain)
        : null;
    final reactions =
        message.reactions ?? const <String, List<ReactionEntry>>{};
    ReactionUserView resolveReactionUser(String userId, {String? timestamp}) {
      final p = profileMap?[userId];
      if (p != null) {
        final name = p.name.trim().isEmpty ? userId : p.name.trim();
        final avatar = (p.avatarThumb ?? p.avatar);
        return ReactionUserView(
          id: userId,
          name: name,
          avatarUrl: avatar,
          timestamp: timestamp,
        );
      }
      final pi = conversation?.participantInfo?[userId];
      if (pi != null) {
        final name = pi.name.trim().isEmpty ? userId : pi.name.trim();
        final avatar = (pi.avatarThumb ?? pi.avatar);
        return ReactionUserView(
          id: userId,
          name: name,
          avatarUrl: avatar,
          timestamp: timestamp,
        );
      }
      return ReactionUserView(
        id: userId,
        name: userId,
        avatarUrl: null,
        timestamp: timestamp,
      );
    }

    /// Без `stretch` исходящий текстовый пузырёк не растягивается на maxWidth — время в `Stack` остаётся у правого края краски.
    final bubbleStackCrossAlign = isMine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final void Function(ChatAttachment attachment)? openGridGallery =
        onOpenMediaGallery == null
        ? null
        : (a) => onOpenMediaGallery!(a, message);

    Widget pollBlock() => MessageChatPoll(
      conversationId: conversationId,
      pollId: pollId,
      conversation: conversation,
      embedMessageStatus: showTimestamps && !hasVisibleText,
      messageCreatedAt: message.createdAt,
      isMine: isMine,
      deliveryStatus: message.deliveryStatus,
      readAt: message.readAt,
      metaFontSize: editedTimeSize,
    );

    List<Widget> forwardReplyLeading() => <Widget>[
      if (message.forwardedFrom != null)
        Padding(
          padding: const EdgeInsets.only(
            bottom: ChatMediaLayoutTokens.replyPreviewToBodyGap,
          ),
          child: Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChatMediaLayoutTokens.messageBubbleMaxWidth,
              ),
              child: Text(
                'Переслано от ${message.forwardedFrom!.name}',
                textAlign: isMine ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: editedTimeSize,
                  fontWeight: FontWeight.w800,
                  color: (isMine ? scheme.onPrimary : scheme.onSurface)
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      if (message.replyTo != null)
        Padding(
          padding: EdgeInsets.only(
            top: message.forwardedFrom == null
                ? ChatMediaLayoutTokens.replyPreviewToBodyGap
                : 0,
          ),
          child: MessageReplyPreview(
            replyTo: message.replyTo!,
            isMine: isMine,
            onOpenOriginal:
                onJumpToMessageId != null &&
                    message.replyTo!.messageId.trim().isNotEmpty
                ? () => onJumpToMessageId!(message.replyTo!.messageId)
                : null,
          ),
        ),
    ];

    Widget textBubble({
      required bool compact,
      List<Widget> insertBeforeText = const [],
    }) {
      final baseStyle = TextStyle(
        fontSize: textSize,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: isMine
            ? Colors.white
            : (scheme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.92)
                  : scheme.onSurface),
      );
      final linkColorForHtml = isMine
          ? Colors.white.withValues(alpha: 0.95)
          : scheme.primary;
      final quoteMaxFallback =
          ChatMediaLayoutTokens.messageBubbleMaxWidth - 24.0;
      List<InlineSpan> htmlSpans({double? quoteMaxWidth}) =>
          messageHtmlToStyledSpans(
            html,
            base: baseStyle,
            linkColor: linkColorForHtml,
            quoteAccent: scheme.primary,
            quoteMaxWidth: quoteMaxWidth ?? quoteMaxFallback,
            onMentionTap: (userId) async {
              final uid = userId.trim();
              if (uid.isEmpty) return;
              if (conversation == null || conversation!.isGroup != true) return;
              if (!context.mounted) return;
              await Navigator.of(context).push<void>(
                CupertinoPageRoute<void>(
                  builder: (_) => GroupMemberProfileSheet(
                    conversationId: conversationId,
                    conversation: conversation!,
                    currentUserId: currentUserId,
                    memberId: uid,
                    selfProfile: profileMap?[currentUserId],
                    memberProfile: profileMap?[uid],
                  ),
                ),
              );
            },
          );

      Widget? textBlock;
      if (hasVisibleText) {
        final innerMax =
            ChatMediaLayoutTokens.messageBubbleMaxWidth - (compact ? 20 : 24);
        final textWidget = html.contains('<')
            ? RichText(
                textAlign: TextAlign.left,
                text: TextSpan(children: htmlSpans()),
              )
            : Text(displayPlain, textAlign: TextAlign.left, style: baseStyle);
        textBlock = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: innerMax),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget,
              if (linkPreviewUrl != null) ...[
                const SizedBox(height: 10),
                MessageLinkPreviewCard(url: linkPreviewUrl, isMine: isMine),
              ],
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 14 : radius),
          color: isMine
              ? (outgoingBubbleColor ?? const Color(0xFF2A79FF))
              : (incomingBubbleColor ?? incomingDefault),
          border: Border.all(
            color: isMine
                ? const Color(0xFF4D92FF).withValues(alpha: 0.32)
                : Colors.white.withValues(
                    alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.24,
                  ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [...insertBeforeText, ?textBlock],
        ),
      );
    }

    final hasEditedMeta =
        message.updatedAt != null &&
        message.updatedAt!.isNotEmpty &&
        !message.isDeleted;
    final showTextMetaOutside =
        !isPureEmoji && hasVisibleText && (showTimestamps || hasEditedMeta);
    final timeStr = _timeHm(message.createdAt.toLocal());

    Widget textMetaOutside() {
      if (!showTextMetaOutside) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(
          top: ChatMediaLayoutTokens.captionToStatusGap,
          right: 2,
          left: 2,
        ),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: _BubbleMetaLine(
            message: message,
            isMine: isMine,
            showTimestamps: showTimestamps,
            editedTimeSize: editedTimeSize,
            onPrimary: scheme.onPrimary,
            onSurface: scheme.onSurface,
            timeHmText: timeStr,
          ),
        ),
      );
    }

    Widget body;
    if (hasPoll && !hasVisibleText && !hasMedia) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [pollBlock()],
      );
    } else if (hasPoll && hasMedia && !hasVisibleText) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageAttachments(
            attachments: message.attachments,
            alignRight: isMine,
            messageId: message.id,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            showTimestamps: false,
            videoCirclePlayingSlotId: videoCirclePlayingSlotId,
            onOpenGridGallery: openGridGallery,
            mediaNorm: message.mediaNorm,
            onRetryMediaNorm: onRetryMediaNorm == null
                ? null
                : () => onRetryMediaNorm!(message),
          ),
          const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
          pollBlock(),
        ],
      );
    } else if (hasPoll && hasVisibleText) {
      // Опрос вне цветного пузыря (паритет с веб: опрос не в «bubble»).
      final afterPoll = <Widget>[
        pollBlock(),
        const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
        textBubble(compact: true),
        textMetaOutside(),
      ];
      if (hasMedia) {
        body = Column(
          crossAxisAlignment: bubbleStackCrossAlign,
          children: [
            MessageAttachments(
              attachments: message.attachments,
              alignRight: isMine,
              messageId: message.id,
              messageCreatedAt: message.createdAt,
              isMine: isMine,
              deliveryStatus: message.deliveryStatus,
              readAt: message.readAt,
              showTimestamps: showTimestamps,
              videoCirclePlayingSlotId: videoCirclePlayingSlotId,
              onOpenGridGallery: openGridGallery,
              mediaNorm: message.mediaNorm,
              onRetryMediaNorm: onRetryMediaNorm == null
                  ? null
                  : () => onRetryMediaNorm!(message),
            ),
            const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
            ...afterPoll,
          ],
        );
      } else {
        body = Column(
          crossAxisAlignment: bubbleStackCrossAlign,
          children: afterPoll,
        );
      }
    } else if (hasLocation && !hasText && !hasMedia && !hasPoll) {
      // Иначе срабатывает общий textBubble с пустым текстом — остаётся полоска исходящего пузыря под картой.
      body = showTimestamps
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(
                top: ChatMediaLayoutTokens.captionToStatusGap,
                right: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _timeHm(message.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: editedTimeSize,
                      fontWeight: FontWeight.w800,
                      color: (isMine ? scheme.onPrimary : scheme.onSurface)
                          .withValues(alpha: 0.62),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    MessageBubbleDeliveryIcons(
                      deliveryStatus: message.deliveryStatus,
                      readAt: message.readAt,
                      iconColor: scheme.onPrimary.withValues(alpha: 0.62),
                      size: 11,
                    ),
                  ],
                ],
              ),
            );
    } else if (isPureEmoji) {
      // Web `MessageText` + `isPureEmoji`: ~5rem, без пузыря и без времени.
      // Родительская колонка — `stretch`; без Align эмодзи растягиваются на всю ширину и прилипают влево.
      final emojiSize = pureEmojiMessageFontSize(fontSize);
      body = Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          displayPlain,
          textAlign: isMine ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: emojiSize,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (hasMedia && !hasText) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageAttachments(
            attachments: message.attachments,
            alignRight: isMine,
            messageId: message.id,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            showTimestamps: showTimestamps,
            videoCirclePlayingSlotId: videoCirclePlayingSlotId,
            onOpenGridGallery: openGridGallery,
            mediaNorm: message.mediaNorm,
            onRetryMediaNorm: onRetryMediaNorm == null
                ? null
                : () => onRetryMediaNorm!(message),
          ),
          if (showTimestamps)
            Padding(
              padding: const EdgeInsets.only(
                top: ChatMediaLayoutTokens.captionToStatusGap,
                right: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _timeHm(message.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: editedTimeSize,
                      fontWeight: FontWeight.w800,
                      color: (isMine ? scheme.onPrimary : scheme.onSurface)
                          .withValues(alpha: 0.62),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    MessageBubbleDeliveryIcons(
                      deliveryStatus: message.deliveryStatus,
                      readAt: message.readAt,
                      iconColor: scheme.onPrimary.withValues(alpha: 0.62),
                      size: 11,
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    } else if (hasMedia && hasText) {
      body = Column(
        crossAxisAlignment: bubbleStackCrossAlign,
        children: [
          MessageAttachments(
            attachments: message.attachments,
            alignRight: isMine,
            messageId: message.id,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            showTimestamps: showTimestamps,
            videoCirclePlayingSlotId: videoCirclePlayingSlotId,
            onOpenGridGallery: openGridGallery,
            mediaNorm: message.mediaNorm,
            onRetryMediaNorm: onRetryMediaNorm == null
                ? null
                : () => onRetryMediaNorm!(message),
          ),
          const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
          textBubble(compact: true),
          textMetaOutside(),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: bubbleStackCrossAlign,
        children: [textBubble(compact: false), textMetaOutside()],
      );
    }

    // Для текстовых сообщений пузырь должен иметь динамическую ширину по контенту,
    // а не растягиваться на всю доступную ширину.
    final mergeColumnCrossAlign = bubbleStackCrossAlign;

    body = Column(
      crossAxisAlignment: mergeColumnCrossAlign,
      children: [
        ...forwardReplyLeading(),
        if (hasLocation) ...[
          MessageLocationCard(
            share: message.locationShare!,
            senderId: message.senderId,
            isMine: isMine,
            createdAt: message.createdAt,
            showTimestamps: showTimestamps,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
          ),
          SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
        ],
        body,
      ],
    );

    // На iOS/web engine сочетание IntrinsicWidth + RichText(WidgetSpan) может
    // падать в dry-layout/baseline (debugCannotComputeDryLayout). Поэтому
    // не используем IntrinsicWidth для пузыря.
    final wrappedBody = body;

    final isVideoCircleMsg = message.attachments.any(isVideoCircleAttachment);

    Widget messageChrome({
      required double topPad,
      required CrossAxisAlignment colCross,
      required MainAxisAlignment rowMain,
      required Alignment innerAlign,
      required double maxW,
    }) {
      return Padding(
        padding: EdgeInsets.only(
          top: topPad,
          bottom: ChatMediaLayoutTokens.messageVerticalGap,
        ),
        child: Column(
          crossAxisAlignment: colCross,
          children: [
            Row(
              mainAxisAlignment: rowMain,
              children: [
                Flexible(
                  child: Align(
                    alignment: innerAlign,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: GestureDetector(
                        onTap: !message.isDeleted
                            ? () {
                                if (selectionMode) {
                                  if (onMessageTap != null) {
                                    onMessageTap!(message);
                                  }
                                  return;
                                }
                                final burst = onSingleEmojiTap;
                                final emoji = singlePureEmoji;
                                if (burst != null && emoji != null) {
                                  burst(message, emoji);
                                }
                              }
                            : null,
                        onLongPress:
                            !selectionMode &&
                                onMessageLongPress != null &&
                                !message.isDeleted
                            ? () => onMessageLongPress!(message)
                            : null,
                        child: DecoratedBox(
                          decoration: selected
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    radius + 2,
                                  ),
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 2,
                                  ),
                                )
                              : const BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(
                              selected ? 2 : 0,
                            ),
                            child: wrappedBody,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (reactions.isNotEmpty)
              MessageReactionsRow(
                reactions: reactions,
                currentUserId: currentUserId,
                alignRight: isMine,
                isGroup: conversation?.isGroup == true,
                resolveUser: resolveReactionUser,
                enabled: onToggleReaction != null && !selectionMode,
                onToggleReaction: (emoji) async {
                  final fn = onToggleReaction;
                  if (fn == null) return;
                  await fn(message, emoji);
                },
              ),
            if (onOpenThread != null && (message.threadCount ?? 0) > 0)
              Align(
                alignment: isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onOpenThread!(message),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: scheme.onSurface.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${message.threadCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (isVideoCircleMsg) {
      return messageChrome(
        topPad: 0,
        colCross: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        rowMain: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        innerAlign: isMine ? Alignment.centerRight : Alignment.centerLeft,
        maxW: ChatMediaLayoutTokens.messageBubbleMaxWidth,
      );
    }

    return messageChrome(
      topPad: 0,
      colCross: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      rowMain: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      innerAlign: isMine ? Alignment.centerRight : Alignment.centerLeft,
      maxW: ChatMediaLayoutTokens.messageBubbleMaxWidth,
    );
  }

  String _timeHm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String? _singleEmojiFromOnlyEmojiMessage(String value) {
    final normalized = stripTagsForEmojiCheck(
      value,
    ).replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return null;
    final chars = normalized.characters.toList(growable: false);
    if (chars.length != 1) return null;
    final one = chars.first;
    if (!isOnlyEmojisMessage(one)) return null;
    return one;
  }
}

class _EmojiBurstTrigger {
  const _EmojiBurstTrigger({required this.emoji, required this.runId});

  final String emoji;
  final int runId;
}

class _EmojiBurstOverlay extends StatefulWidget {
  const _EmojiBurstOverlay({
    required this.emoji,
    required this.onFinished,
    super.key,
  });

  final String emoji;
  final VoidCallback onFinished;

  @override
  State<_EmojiBurstOverlay> createState() => _EmojiBurstOverlayState();
}

class _EmojiBurstOverlayState extends State<_EmojiBurstOverlay>
    with SingleTickerProviderStateMixin {
  static const int _particleCount = 118;
  static const List<double> _saturationBoostMatrix = <double>[
    1.27545,
    -0.25025,
    -0.0252,
    0,
    0,
    -0.07455,
    1.09975,
    -0.0252,
    0,
    0,
    -0.07455,
    -0.25025,
    1.3248,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  late final AnimationController _controller;
  late final List<_BurstParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List<_BurstParticle>.generate(_particleCount, (i) {
      final edge = rnd.nextInt(4);
      late final double startX;
      late final double startY;
      switch (edge) {
        case 0: // bottom
          startX = rnd.nextDouble() * 1.2 - 0.1;
          startY = 1.06 + rnd.nextDouble() * 0.24;
          break;
        case 1: // top
          startX = rnd.nextDouble() * 1.2 - 0.1;
          startY = -0.28 - rnd.nextDouble() * 0.22;
          break;
        case 2: // left
          startX = -0.28 - rnd.nextDouble() * 0.25;
          startY = rnd.nextDouble() * 1.2 - 0.1;
          break;
        default: // right
          startX = 1.06 + rnd.nextDouble() * 0.25;
          startY = rnd.nextDouble() * 1.2 - 0.1;
      }

      final hubX = 0.5 + (rnd.nextDouble() - 0.5) * 0.72;
      final hubY = 0.5 + (rnd.nextDouble() - 0.5) * 0.86;
      final endX = (hubX + (rnd.nextDouble() - 0.5) * 0.34).clamp(-0.2, 1.2);
      final endY = (hubY + (rnd.nextDouble() - 0.5) * 0.32).clamp(-0.2, 1.2);
      final size = 14 + rnd.nextDouble() * 86;
      final wobbleAmp = 0.008 + rnd.nextDouble() * 0.034;
      final wobbleSpeed = 0.42 + rnd.nextDouble() * 1.45;
      final spinTurns =
          (0.45 + rnd.nextDouble() * 1.45) * (rnd.nextBool() ? 1 : -1);
      final delay = rnd.nextDouble() * 0.38;
      final life = 0.78 + rnd.nextDouble() * 0.34;
      final displaySize = size * (0.62 + rnd.nextDouble() * 0.72);
      return _BurstParticle(
        startX: startX,
        endX: endX,
        startY: startY,
        endY: endY,
        size: size,
        displaySize: displaySize,
        wobbleAmp: wobbleAmp,
        wobbleSpeed: wobbleSpeed,
        rotationTurns: spinTurns,
        delay: delay,
        life: life,
      );
    });
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 4400),
          )
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) widget.onFinished();
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: _particles
                      .map((p) {
                        var local = (t - p.delay) / p.life;
                        local = local.clamp(0.0, 1.0);
                        if (local <= 0) return const SizedBox.shrink();
                        final eased = Curves.easeInOutCubic.transform(local);
                        final x =
                            (p.startX +
                                (p.endX - p.startX) * eased +
                                math.sin(
                                      (local + p.delay) *
                                          p.wobbleSpeed *
                                          2 *
                                          math.pi,
                                    ) *
                                    p.wobbleAmp) *
                            w;
                        final y =
                            (p.startY +
                                (p.endY - p.startY) * eased +
                                math.cos(
                                      (local + p.delay * 0.7) *
                                          p.wobbleSpeed *
                                          2 *
                                          math.pi,
                                    ) *
                                    (p.wobbleAmp * 0.85)) *
                            h;
                        final fadeIn = Curves.easeOut
                            .transform((local / 0.2).clamp(0.0, 1.0));
                        final fadeOut = local < 0.58
                            ? 1.0
                            : Curves.easeInOutCubic.transform(
                                (1.0 - (local - 0.58) / 0.42).clamp(0.0, 1.0),
                              );
                        final fade = (fadeIn * fadeOut).clamp(0.0, 1.0);
                        final pulse =
                            1 + 0.06 * math.sin(local * math.pi * 2.4);
                        final scale =
                            (0.52 +
                                0.62 * Curves.easeOutCubic.transform(local)) *
                            pulse;
                        return Positioned(
                          left: x,
                          top: y,
                          child: Opacity(
                            opacity: fade,
                            child: Transform.rotate(
                              angle:
                                  p.rotationTurns *
                                  2 *
                                  math.pi *
                                  Curves.easeOut.transform(local),
                              child: Transform.scale(
                                scale: scale,
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(
                                    _saturationBoostMatrix,
                                  ),
                                  child: Text(
                                    widget.emoji,
                                    style: TextStyle(
                                      fontSize: p.displaySize,
                                      height: 1,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 14,
                                          color: Color(0x60000000),
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BurstParticle {
  const _BurstParticle({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.size,
    required this.displaySize,
    required this.wobbleAmp,
    required this.wobbleSpeed,
    required this.rotationTurns,
    required this.delay,
    required this.life,
  });

  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final double size;
  final double displaySize;
  final double wobbleAmp;
  final double wobbleSpeed;
  final double rotationTurns;
  final double delay;
  final double life;
}

class _SyncedEmojiBurstCandidate {
  const _SyncedEmojiBurstCandidate({
    required this.eventId,
    required this.emoji,
  });

  final String eventId;
  final String emoji;
}
