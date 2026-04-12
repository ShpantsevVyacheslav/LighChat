import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/sanitize_message_html.dart';
import '../data/chat_poll_stub_text.dart';
import '../data/chat_emoji_only.dart';
import '../data/video_circle_utils.dart';
import '../data/chat_media_layout_tokens.dart';
import 'chat_date_capsule.dart';
import 'message_attachments.dart';
import 'message_bubble_delivery_icons.dart';
import 'message_chat_poll.dart';
import 'message_deleted_stub.dart';
import 'message_location_card.dart';
import 'message_html_text.dart';
import 'message_reactions_row.dart';
import 'message_reply_preview.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.messagesDesc,
    required this.currentUserId,
    required this.conversationId,
    this.conversation,
    required this.scrollController,
    this.onNearOldestEdge,
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
  });

  final List<ChatMessage> messagesDesc;
  final String currentUserId;
  final String conversationId;
  final Conversation? conversation;
  final ScrollController scrollController;
  /// Вызов при приближении к самым старым сообщениям (подгрузка истории).
  final VoidCallback? onNearOldestEdge;
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
  bool _didInitialScroll = false;
  final ValueNotifier<String?> _videoCirclePlayingSlotId =
      ValueNotifier<String?>(null);

  /// Ключи на первое сообщение календарного дня — для одной плавающей капсулы даты.
  final Map<String, GlobalKey> _dayStartKeys = <String, GlobalKey>{};

  /// Последняя группировка по дням (синхронно с текущим build).
  List<List<ChatMessage>> _cachedGroups = <List<ChatMessage>>[];

  String? _stickyDayLabel;
  bool _stickyDayUpdateScheduled = false;

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _didInitialScroll = false;
      _videoCirclePlayingSlotId.value = null;
      _dayStartKeys.clear();
      _stickyDayLabel = null;
    } else if (oldWidget.messagesDesc.length != widget.messagesDesc.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyStickyDayLabel());
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
  }

  void _onScrollControllerTick() => _scheduleStickyDayUpdate();

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
    double? lastMax;
    var stableFrames = 0;
    var frames = 0;
    const maxFrames = 10;
    void tick(Duration? _) {
      if (!mounted || _didInitialScroll) return;
      final c = widget.scrollController;
      if (!c.hasClients) {
        frames++;
        if (frames < maxFrames) {
          WidgetsBinding.instance.addPostFrameCallback(tick);
        } else {
          _didInitialScroll = true;
          _scheduleStickyDayUpdate();
        }
        return;
      }
      final max = c.position.maxScrollExtent;
      c.jumpTo(max);
      frames++;
      if (lastMax != null && (max - lastMax!).abs() < 1.0) {
        stableFrames++;
      } else {
        stableFrames = 0;
      }
      lastMax = max;
      if (stableFrames >= 2 || frames >= maxFrames) {
        _didInitialScroll = true;
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
    if (m.pixels > m.minScrollExtent + 280) return false;

    // Не реагировать на программный скролл (ensureVisible после подгрузки истории) —
    // иначе у верхнего края снова запускается _limit и скролл «залипает».
    final userDriven = n is UserScrollNotification ||
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
        final t = a.createdAt.compareTo(b.createdAt);
        if (t != 0) return t;
        return a.id.compareTo(b.id);
      });

    _maybeInitialScrollToBottom(asc);

    final groups = _groupByDay(asc);
    _cachedGroups = groups;
    final validDayKeys =
        groups.map((g) => ChatMessageList.dayKey(g.first.createdAt)).toSet();
    _dayStartKeys.removeWhere((k, _) => !validDayKeys.contains(k));

    if (groups.isNotEmpty && _stickyDayLabel == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyStickyDayLabel());
    }

    final slivers = <Widget>[];

    for (final g in groups) {
      if (g.isEmpty) continue;
      final dayKey = ChatMessageList.dayKey(g.first.createdAt);
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final m = g[i];
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
                  flashHighlightMessageId: widget.flashHighlightMessageId,
                ),
              );
              final rowKey = widget.messageItemKeys[m.id];
              final padded = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: bubble,
              );
              Widget row = i == 0
                  ? KeyedSubtree(
                      key: _dayStartKeys.putIfAbsent(dayKey, GlobalKey.new),
                      child: padded,
                    )
                  : padded;
              if (rowKey != null) {
                row = KeyedSubtree(key: rowKey, child: row);
              }
              return row;
            },
            childCount: g.length,
          ),
        ),
      );
    }

    if (widget.outgoingMediaFooter != null) {
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

    final boostJump = widget.jumpScrollBoostMessageId != null &&
        widget.jumpScrollBoostMessageId!.isNotEmpty;

    final stickyFallback = groups.isEmpty
        ? null
        : formatChatDayLabelRu(groups.last.first.createdAt.toLocal());
    final stickyDisplay = _stickyDayLabel ?? stickyFallback;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            controller: widget.scrollController,
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
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification ||
        n is ScrollEndNotification ||
        n is UserScrollNotification) {
      _scheduleStickyDayUpdate();
    }
    return _onScrollNotification(n);
  }
}

/// Резерв справа под «изм.», время и статус — чтобы не наезжали на последнюю строку (Telegram-style).
double _outgoingBubbleFooterReserveWidth(
  BuildContext context, {
  required ChatMessage message,
  required bool showTimestamps,
  required double editedTimeSize,
  required String timeHmText,
}) {
  final showEdited =
      message.updatedAt != null && message.updatedAt!.isNotEmpty && !message.isDeleted;
  if (!showTimestamps && !showEdited) return 0;

  final metaStyle = TextStyle(
    fontSize: editedTimeSize,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
  final editedStyle = TextStyle(
    fontSize: editedTimeSize - 1,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  final painter = TextPainter(
    text: TextSpan(
      children: [
        if (showEdited) TextSpan(text: 'изм. ', style: editedStyle),
        if (showTimestamps) TextSpan(text: timeHmText, style: metaStyle),
      ],
    ),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();

  var w = painter.width;
  if (showTimestamps) w += 22;
  return math.max(76.0, w + 12);
}

List<InlineSpan> _chatBubbleInlineMetaSpans({
  required ChatMessage message,
  required bool isMine,
  required bool showTimestamps,
  required TextStyle baseBodyStyle,
  required double editedTimeSize,
  required Color onPrimary,
  required Color onSurface,
  required String timeHmText,
}) {
  final showEdited =
      message.updatedAt != null && message.updatedAt!.isNotEmpty && !message.isDeleted;
  if (!showTimestamps && !showEdited) {
    return const <InlineSpan>[];
  }
  final metaColor = (isMine ? onPrimary : onSurface).withValues(alpha: 0.65);
  final editedColor = (isMine ? onPrimary : onSurface).withValues(alpha: 0.5);
  final metaStyle = TextStyle(
    fontSize: editedTimeSize,
    fontWeight: FontWeight.w800,
    color: metaColor,
    height: 1.15,
  );
  final editedStyle = TextStyle(
    fontSize: editedTimeSize - 1,
    fontWeight: FontWeight.w800,
    color: editedColor,
    height: 1.15,
  );
  return <InlineSpan>[
    TextSpan(text: '\u00A0', style: baseBodyStyle),
    if (showEdited) TextSpan(text: 'изм. ', style: editedStyle),
    if (showTimestamps) TextSpan(text: timeHmText, style: metaStyle),
    if (isMine && showTimestamps)
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(left: 2),
          child: SizedBox(
            height: 15,
            child: MessageBubbleDeliveryIcons(
              deliveryStatus: message.deliveryStatus,
              readAt: message.readAt,
              iconColor: metaColor,
              size: 11,
            ),
          ),
        ),
      ),
  ];
}

/// Время и статус доставки исходящего — блок для `Positioned(right:0,bottom:0)` в пузырьке (паритет Telegram).
class _OutgoingBubbleMetaRow extends StatelessWidget {
  const _OutgoingBubbleMetaRow({
    required this.message,
    required this.showTimestamps,
    required this.editedTimeSize,
    required this.onPrimary,
    required this.timeHmText,
  });

  final ChatMessage message;
  final bool showTimestamps;
  final double editedTimeSize;
  final Color onPrimary;
  final String timeHmText;

  @override
  Widget build(BuildContext context) {
    final showEdited =
        message.updatedAt != null && message.updatedAt!.isNotEmpty && !message.isDeleted;
    if (!showTimestamps && !showEdited) {
      return const SizedBox.shrink();
    }
    final metaColor = onPrimary.withValues(alpha: 0.65);
    final editedColor = onPrimary.withValues(alpha: 0.5);
    final metaStyle = TextStyle(
      fontSize: editedTimeSize,
      fontWeight: FontWeight.w800,
      color: metaColor,
      height: 1.15,
    );
    final editedStyle = TextStyle(
      fontSize: editedTimeSize - 1,
      fontWeight: FontWeight.w800,
      color: editedColor,
      height: 1.15,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showEdited) Text('изм. ', style: editedStyle),
        if (showTimestamps) Text(timeHmText, style: metaStyle),
        if (showTimestamps) ...[
          const SizedBox(width: 2),
          SizedBox(
            height: 15,
            child: MessageBubbleDeliveryIcons(
              deliveryStatus: message.deliveryStatus,
              readAt: message.readAt,
              iconColor: metaColor,
              size: 11,
            ),
          ),
        ],
      ],
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
    this.flashHighlightMessageId,
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
  final String? flashHighlightMessageId;

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
    final radius = bubbleRadius == 'square' ? 8.0 : 18.0;
    final incomingDefault = Colors.white.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.08 : 0.22,
    );
    if (message.isDeleted) {
      return MessageDeletedStub(alignRight: isMine);
    }
    final raw = message.text ?? '';
    final html = raw.contains('<') ? sanitizeMessageHtml(raw) : raw;
    final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;
    final hasText = plain.trim().isNotEmpty;
    final hasMedia = message.attachments.isNotEmpty;
    final pollId = (message.chatPollId ?? '').trim();
    final hasPoll = pollId.isNotEmpty;
    final pollStubCaption =
        hasPoll && hasText && isChatPollStubCaptionPlain(plain);
    final hasVisibleText = hasText && !pollStubCaption;
    final hasLocation = message.locationShare != null;
    final isPureEmoji = hasText &&
        isOnlyEmojisMessage(html) &&
        !hasMedia &&
        !hasPoll &&
        message.replyTo == null &&
        !hasLocation;
    final reactions =
        message.reactions ?? const <String, List<ReactionEntry>>{};
    /// Без `stretch` исходящий текстовый пузырёк не растягивается на maxWidth — время в `Stack` остаётся у правого края краски.
    final bubbleStackCrossAlign =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

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
              child: Text(
                'Переслано от ${message.forwardedFrom!.name}',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: editedTimeSize,
                  fontWeight: FontWeight.w800,
                  color: (isMine ? scheme.onPrimary : scheme.onSurface)
                      .withValues(alpha: 0.55),
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
                onOpenOriginal: onJumpToMessageId != null &&
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
      final timeStr = _timeHm(message.createdAt.toLocal());
      final baseStyle = TextStyle(
        fontSize: textSize,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: isMine ? scheme.onPrimary : scheme.onSurface,
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
          );

      Widget? textBlock;
      if (hasVisibleText) {
        if (!isPureEmoji &&
            (showTimestamps ||
                (message.updatedAt != null &&
                    message.updatedAt!.isNotEmpty &&
                    !message.isDeleted))) {
          final useOutgoingMetaFooter = isMine;
          if (useOutgoingMetaFooter) {
            final footer = _OutgoingBubbleMetaRow(
              message: message,
              showTimestamps: showTimestamps,
              editedTimeSize: editedTimeSize,
              onPrimary: scheme.onPrimary,
              timeHmText: timeStr,
            );
            // Telegram-style: текст слева на всю ширину минус «карман» справа; время прижато к правому
            // нижнему углу пузырька, на одной горизонтали с последней строкой (если хватает места в кармане).
            final metaReserve = _outgoingBubbleFooterReserveWidth(
              context,
              message: message,
              showTimestamps: showTimestamps,
              editedTimeSize: editedTimeSize,
              timeHmText: timeStr,
            );
            final innerMax =
                ChatMediaLayoutTokens.messageBubbleMaxWidth -
                (compact ? 20 : 24); // гориз. padding пузырька
            if (html.contains('<')) {
              textBlock = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: innerMax),
                child: IntrinsicWidth(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: metaReserve, bottom: 1),
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: baseStyle,
                            children: htmlSpans(quoteMaxWidth: innerMax),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: footer,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              textBlock = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: innerMax),
                child: IntrinsicWidth(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: metaReserve, bottom: 1),
                        child: Text(
                          plain,
                          textAlign: TextAlign.left,
                          style: baseStyle,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: footer,
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            final metaSpans = _chatBubbleInlineMetaSpans(
              message: message,
              isMine: isMine,
              showTimestamps: showTimestamps,
              baseBodyStyle: baseStyle,
              editedTimeSize: editedTimeSize,
              onPrimary: scheme.onPrimary,
              onSurface: scheme.onSurface,
              timeHmText: timeStr,
            );
            if (html.contains('<')) {
              textBlock = RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: baseStyle,
                  children: <InlineSpan>[
                    ...htmlSpans(),
                    ...metaSpans,
                  ],
                ),
              );
            } else {
              textBlock = RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: baseStyle,
                  children: <InlineSpan>[
                    TextSpan(text: plain),
                    ...metaSpans,
                  ],
                ),
              );
            }
          }
        } else {
          if (html.contains('<')) {
            textBlock = RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                children: htmlSpans(),
              ),
            );
          } else {
            textBlock = Text(
              plain,
              textAlign: TextAlign.left,
              style: baseStyle,
            );
          }
        }
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 14 : radius),
          color: isMine
              ? (outgoingBubbleColor ??
                    scheme.primary.withValues(
                      alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.28,
                    ))
              : (incomingBubbleColor ?? incomingDefault),
          border: Border.all(
            color: (isMine ? scheme.primary : Colors.white).withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.18 : 0.30,
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
          children: [
            ...insertBeforeText,
            ?textBlock,
          ],
        ),
      );
    }

    Widget body;
    if (hasPoll && !hasVisibleText && !hasMedia) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pollBlock(),
        ],
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
              padding: const EdgeInsets.only(top: ChatMediaLayoutTokens.captionToStatusGap, right: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _timeHm(message.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: editedTimeSize,
                      fontWeight: FontWeight.w800,
                      color: (isMine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.62),
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
          plain,
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
          ),
          const SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap),
          textBubble(compact: true),
        ],
      );
    } else {
      body = textBubble(compact: false);
    }

    final mergeColumnCrossAlign =
        (message.replyTo != null ||
            (hasPoll && hasVisibleText) ||
            (hasMedia && hasText))
        ? bubbleStackCrossAlign
        : CrossAxisAlignment.stretch;

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

    // Нельзя оборачивать в IntrinsicWidth, если внутри есть опрос: у MessageChatPoll
    // контейнер с width: double.infinity — это ломает intrinsics и sliver (child.hasSize).
    final useIntrinsicWidth = !isPureEmoji &&
        !hasPoll &&
        !hasLocation &&
        !(hasMedia && !hasText && message.attachments.isNotEmpty);
    final wrappedBody = useIntrinsicWidth
        ? IntrinsicWidth(child: body)
        : body;

    final isVideoCircleMsg =
        message.attachments.any(isVideoCircleAttachment);
    final flashRow = flashHighlightMessageId != null &&
        flashHighlightMessageId == message.id;

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
                        onTap:
                            selectionMode &&
                                onMessageTap != null &&
                                !message.isDeleted
                            ? () => onMessageTap!(message)
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
                                  borderRadius:
                                      BorderRadius.circular(radius + 2),
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 2,
                                  ),
                                )
                              : flashRow
                              ? BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(radius + 3),
                                  border: Border.all(
                                    color: scheme.primary.withValues(
                                      alpha: 0.92,
                                    ),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 22,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                )
                              : const BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(
                              (selected || flashRow) ? 2 : 0,
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
              ),
            if (onOpenThread != null && (message.threadCount ?? 0) > 0)
              Align(
                alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
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
        colCross:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        rowMain:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        innerAlign:
            isMine ? Alignment.centerRight : Alignment.centerLeft,
        maxW: ChatMediaLayoutTokens.messageBubbleMaxWidth,
      );
    }

    return messageChrome(
      topPad: 0,
      colCross:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      rowMain:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      innerAlign:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      maxW: ChatMediaLayoutTokens.messageBubbleMaxWidth,
    );
  }

  String _timeHm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
