import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'message_attachments.dart';
import 'message_deleted_stub.dart';
import 'message_html_text.dart';
import 'message_reactions_row.dart';
import 'message_reply_preview.dart';

/// Chronological order: sort by `createdAt` + `id`, then `ListView(reverse: true)` so the
/// **newest** row sits at the **bottom** (composer side) and short threads don’t float to the top.
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messagesDesc,
    required this.currentUserId,
    required this.controller,
    this.selectionMode = false,
    this.selectedMessageIds = const <String>{},
    this.onMessageTap,
    this.onMessageLongPress,
    this.showTimestamps = true,
    this.fontSize = 'medium',
    this.bubbleRadius = 'rounded',
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  /// Raw messages from `watchMessages` (typically `createdAt` descending); sorted ascending internally.
  final List<ChatMessage> messagesDesc;
  final String currentUserId;
  final ScrollController controller;
  final bool selectionMode;
  final Set<String> selectedMessageIds;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final bool showTimestamps;
  final String fontSize;
  final String bubbleRadius;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  @override
  Widget build(BuildContext context) {
    final asc = List<ChatMessage>.from(messagesDesc)
      ..sort((a, b) {
        final t = a.createdAt.compareTo(b.createdAt);
        if (t != 0) return t;
        return a.id.compareTo(b.id);
      });

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: asc.length,
      itemBuilder: (context, index) {
        final len = asc.length;
        final m = asc[len - 1 - index];
        final mine = m.senderId == currentUserId;
        final showDate = _shouldShowDateSeparatorReversed(asc, index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _DateSeparatorLabel(dt: m.createdAt.toLocal()),
            _ChatMessageBubble(
              message: m,
              isMine: mine,
              currentUserId: currentUserId,
              selectionMode: selectionMode,
              selected: selectedMessageIds.contains(m.id),
              onMessageTap: onMessageTap,
              onMessageLongPress: onMessageLongPress,
              showTimestamps: showTimestamps,
              fontSize: fontSize,
              bubbleRadius: bubbleRadius,
              outgoingBubbleColor: outgoingBubbleColor,
              incomingBubbleColor: incomingBubbleColor,
            ),
          ],
        );
      },
    );
  }

  /// [index] is `ListView` builder index with `reverse: true` (0 = newest / bottom).
  bool _shouldShowDateSeparatorReversed(List<ChatMessage> asc, int index) {
    final len = asc.length;
    final cur = asc[len - 1 - index];
    if (index == 0) return true;
    final newer = asc[len - index];
    final a = cur.createdAt.toLocal();
    final b = newer.createdAt.toLocal();
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

class _DateSeparatorLabel extends StatelessWidget {
  const _DateSeparatorLabel({required this.dt});

  final DateTime dt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final day = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (day == today) {
      label = 'СЕГОДНЯ';
    } else if (day == yesterday) {
      label = 'ВЧЕРА';
    } else {
      label =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.black.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUserId,
    this.selectionMode = false,
    this.selected = false,
    this.onMessageTap,
    this.onMessageLongPress,
    this.showTimestamps = true,
    this.fontSize = 'medium',
    this.bubbleRadius = 'rounded',
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  final ChatMessage message;
  final bool isMine;
  final String currentUserId;
  final bool selectionMode;
  final bool selected;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final bool showTimestamps;
  final String fontSize;
  final String bubbleRadius;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

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
    final html = message.text ?? '';
    final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;

    final reactions =
        message.reactions ?? const <String, List<ReactionEntry>>{};

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      color: isMine
                          ? (outgoingBubbleColor ??
                                scheme.primary.withValues(
                                  alpha: scheme.brightness == Brightness.dark
                                      ? 0.45
                                      : 0.28,
                                ))
                          : (incomingBubbleColor ?? incomingDefault),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : (isMine ? scheme.primary : Colors.white)
                                  .withValues(
                                    alpha: scheme.brightness == Brightness.dark
                                        ? 0.18
                                        : 0.30,
                                  ),
                        width: selected ? 2.2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (message.forwardedFrom != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Переслано от ${message.forwardedFrom!.name}',
                              style: TextStyle(
                                fontSize: editedTimeSize,
                                fontWeight: FontWeight.w800,
                                color:
                                    (isMine
                                            ? scheme.onPrimary
                                            : scheme.onSurface)
                                        .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        if (message.replyTo != null)
                          MessageReplyPreview(
                            replyTo: message.replyTo!,
                            isMine: isMine,
                          ),
                        if (plain.trim().isNotEmpty)
                          Text(
                            plain,
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: isMine
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        if (message.attachments.isNotEmpty) ...[
                          if (plain.trim().isNotEmpty)
                            const SizedBox(height: 8),
                          MessageAttachments(attachments: message.attachments),
                        ],
                        if (showTimestamps ||
                            (message.updatedAt != null &&
                                message.updatedAt!.isNotEmpty &&
                                !message.isDeleted)) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (message.updatedAt != null &&
                                  message.updatedAt!.isNotEmpty &&
                                  !message.isDeleted) ...[
                                Text(
                                  'изм.',
                                  style: TextStyle(
                                    fontSize: editedTimeSize - 1,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        (isMine
                                                ? scheme.onPrimary
                                                : scheme.onSurface)
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                                if (showTimestamps) const SizedBox(width: 6),
                              ],
                              if (showTimestamps)
                                Text(
                                  _timeHm(message.createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: editedTimeSize,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        (isMine
                                                ? scheme.onPrimary
                                                : scheme.onSurface)
                                            .withValues(alpha: 0.65),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
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
        ],
      ),
    );
  }

  String _timeHm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
