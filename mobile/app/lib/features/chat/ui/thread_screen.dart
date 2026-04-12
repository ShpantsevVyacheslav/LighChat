import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/chat_media_gallery.dart';

import '../data/chat_emoji_only.dart';
import '../data/chat_media_layout_tokens.dart';
import '../data/chat_poll_stub_text.dart';
import 'chat_message_list.dart';
import 'message_attachments.dart';
import 'message_bubble_delivery_icons.dart';
import 'message_chat_poll.dart';
import 'message_deleted_stub.dart';
import '../data/composer_html_editing.dart';
import 'message_html_text.dart';
import 'message_location_card.dart';
import 'chat_media_viewer_screen.dart';
import 'chat_wallpaper_background.dart';

String _threadRepliesUpperRu(int n) {
  if (n % 100 >= 11 && n % 100 <= 14) return '$n ОТВЕТОВ';
  switch (n % 10) {
    case 1:
      return '$n ОТВЕТ';
    case 2:
    case 3:
    case 4:
      return '$n ОТВЕТА';
    default:
      return '$n ОТВЕТОВ';
  }
}

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({
    super.key,
    required this.conversationId,
    required this.parentMessageId,
    this.parentMessage,
  });

  final String conversationId;
  final String parentMessageId;
  final ChatMessage? parentMessage;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();
  bool _sendBusy = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  String _timeHm(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  PreferredSizeWidget _threadAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.22),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text('Обсуждение'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/chats/${widget.conversationId}');
          }
        },
      ),
    );
  }

  String _threadSenderLabel(String senderId, User user, Conversation? conv) {
    if (senderId == user.uid) return 'Вы';
    final n = conv?.participantInfo?[senderId]?.name;
    if ((n ?? '').trim().isNotEmpty) return n!.trim();
    return 'Участник';
  }

  Future<bool> _confirmDeleteMessageInThread(ChatMessage m) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить: $e')),
        );
      }
      return false;
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
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => ChatMediaViewerScreen(
          items: items,
          initialIndex: ix,
          currentUserId: user.uid,
          senderLabel: (sid) => _threadSenderLabel(sid, user, conv),
          onReply: null,
          onForward: (m) {
            if (m.isDeleted) return;
            context.push('/chats/forward', extra: <ChatMessage>[m]);
          },
          onDeleteMessage: (m) => _confirmDeleteMessageInThread(m),
        ),
      ),
    );
  }

  Future<void> _submit(String uid) async {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      _composerController.text,
    );
    final plain =
        prepared.isEmpty ? '' : messageHtmlToPlainText(prepared).trim();
    if (plain.isEmpty || _sendBusy) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    setState(() => _sendBusy = true);
    try {
      await repo.sendThreadTextMessage(
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        senderId: uid,
        text: prepared,
      );
      if (mounted) {
        _composerController.clear();
        _composerFocus.unfocus();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
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

    final userDocAsync = ref.watch(userChatSettingsDocProvider(user.uid));
    final userDoc =
        userDocAsync.asData?.value ?? const <String, dynamic>{};
    final rawChatSettings = Map<String, dynamic>.from(
      userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
    );
    final wallpaper = rawChatSettings['chatWallpaper'] as String?;

    final threadAsync = ref.watch(
      threadMessagesProvider((
        conversationId: widget.conversationId,
        parentMessageId: widget.parentMessageId,
        limit: 200,
      )),
    );

    final topUnderAppBar =
        MediaQuery.paddingOf(context).top + kToolbarHeight;

    return parentAsync.when(
      loading: () => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _threadAppBar(context),
        body: ChatWallpaperBackground(
          wallpaper: wallpaper,
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
        appBar: _threadAppBar(context),
        body: ChatWallpaperBackground(
          wallpaper: wallpaper,
          child: Column(
            children: [
              SizedBox(height: topUnderAppBar),
              Expanded(child: Center(child: Text('Ошибка: $e'))),
            ],
          ),
        ),
      ),
      data: (parent) {
        if (parent == null || parent.isDeleted) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _threadAppBar(context),
            body: ChatWallpaperBackground(
              wallpaper: wallpaper,
              child: Column(
                children: [
                  SizedBox(height: topUnderAppBar),
                  const Expanded(
                    child: Center(child: Text('Сообщение не найдено')),
                  ),
                ],
              ),
            ),
          );
        }

        final replyCount = parent.threadCount ?? 0;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _threadAppBar(context),
          body: ChatWallpaperBackground(
            wallpaper: wallpaper,
            child: Column(
              children: [
                SizedBox(height: topUnderAppBar),
                Expanded(
                  child: threadAsync.when(
                    data: (threadMsgs) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            onOpenMediaGallery: (att) {
                              _openThreadMediaGallery(
                                att,
                                parent,
                                parent: parent,
                                threadMsgsDesc: threadMsgs,
                                user: user,
                                conv: conv,
                              );
                            },
                          ),
                          Expanded(
                            child: ChatMessageList(
                              messagesDesc: threadMsgs,
                              currentUserId: user.uid,
                              conversationId: widget.conversationId,
                              conversation: conv,
                              scrollController: _scrollController,
                              showTimestamps: true,
                              fontSize: 'medium',
                              bubbleRadius: 'rounded',
                              outgoingBubbleColor: scheme.primary,
                              incomingBubbleColor: Colors.white.withValues(
                                alpha: scheme.brightness == Brightness.dark
                                    ? 0.08
                                    : 0.22,
                              ),
                              onOpenMediaGallery: (att, m) {
                                _openThreadMediaGallery(
                                  att,
                                  m,
                                  parent: parent,
                                  threadMsgsDesc: threadMsgs,
                                  user: user,
                                  conv: conv,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Column(
                      children: [
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
                    error: (e, _) =>
                        Center(child: Text('Ошибка ветки: $e')),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _composerController,
                              focusNode: _composerFocus,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submit(user.uid),
                              decoration: const InputDecoration(
                                hintText: 'Сообщение',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed:
                              _sendBusy ? null : () => _submit(user.uid),
                          icon: _sendBusy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
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
  final void Function(ChatAttachment attachment)? onOpenMediaGallery;

  @override
  Widget build(BuildContext context) {
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

    final html = message.text ?? '';
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
    final radius = 18.0;
    final textSize = 15.0;
    final metaColor =
        (isMine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.72);
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
              plain,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(fontSize: 44, height: 1.05),
            ),
          );
        } else if (html.contains('<')) {
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
                ),
              ),
            ),
          );
        } else {
          children.add(Text(plain, style: baseStyle));
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
            messageId: message.id,
            messageCreatedAt: message.createdAt,
            isMine: isMine,
            deliveryStatus: message.deliveryStatus,
            readAt: message.readAt,
            showTimestamps: false,
            onOpenGridGallery: onOpenMediaGallery,
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
        children.add(Text('Сообщение', style: baseStyle));
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
          children: [
            ...children,
            const SizedBox(height: 4),
            metaRow,
          ],
        );
      }

      return Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _threadRepliesUpperRu(replyCount),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
