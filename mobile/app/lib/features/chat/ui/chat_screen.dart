import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../data/partner_presence_line.dart';
import '../data/pinned_messages_helper.dart';
import '../data/reply_preview_builder.dart';
import '../data/saved_messages_chat.dart';
import '../data/user_profile.dart';
import 'chat_header.dart';
import 'chat_message_list.dart';
import 'chat_partner_profile_sheet.dart';
import 'chat_pinned_strip.dart';
import 'chat_selection_app_bar.dart';
import 'composer_reply_banner.dart';
import 'message_action_sheet.dart';
import 'message_html_text.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _limit = 100;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _loadingOlder = false;
  bool _historyListenerAttached = false;
  ReplyContext? _replyingTo;
  final Set<String> _selectedMessageIds = <String>{};
  bool _actionBusy = false;

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

  Widget _buildChatBackground({
    required String? wallpaper,
    required Widget child,
  }) {
    if (wallpaper == null || wallpaper.trim().isEmpty) {
      return AuthBackground(child: child);
    }

    final gradients = <String, Gradient>{
      'linear-gradient(135deg, #667eea 0%, #764ba2 100%)': const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      ),
      'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)': const LinearGradient(
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      ),
      'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)': const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ),
      'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)': const LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      'linear-gradient(135deg, #fa709a 0%, #fee140 100%)': const LinearGradient(
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      ),
      'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)': const LinearGradient(
        colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      ),
      'linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)': const LinearGradient(
        colors: [Color(0xFF0C0C0C), Color(0xFF1A1A2E)],
      ),
      'linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)': const LinearGradient(
        colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
      ),
    };

    final gradient = gradients[wallpaper];
    return Stack(
      fit: StackFit.expand,
      children: [
        if (wallpaper.startsWith('http'))
          Image.network(
            wallpaper,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        else if (gradient != null)
          DecoratedBox(decoration: BoxDecoration(gradient: gradient))
        else
          AuthBackground(child: const SizedBox.expand()),
        if (wallpaper.startsWith('http'))
          Container(color: Colors.black.withValues(alpha: 0.35)),
        child,
      ],
    );
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      if (_historyListenerAttached) {
        _scroll.removeListener(_onScrollLoadOlder);
        _historyListenerAttached = false;
      }
      _limit = 100;
      _replyingTo = null;
      _selectedMessageIds.clear();
      _loadingOlder = false;
    }
  }

  @override
  void dispose() {
    if (_historyListenerAttached) {
      _scroll.removeListener(_onScrollLoadOlder);
    }
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
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
            final profileWatchIds = <String>[user.uid];
            if (dmOtherId != null && dmOtherId.isNotEmpty) {
              profileWatchIds.add(dmOtherId);
            }
            final profilesStream = profilesRepo?.watchUsersByIds(
              profileWatchIds,
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

                void toast(String msg) => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                void handleBack() {
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
                  final isGroup = conv?.data.isGroup ?? false;
                  final pins = conv == null
                      ? <PinnedMessage>[]
                      : conversationPinnedList(conv.data);
                  final byId = {for (final m in msgs) m.id: m};
                  final sortedPins = sortPinnedMessagesByTime(pins, byId);
                  final topPin = sortedPins.isNotEmpty ? sortedPins.last : null;
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
                                onThreadsTap: () => toast('Треды: скоро'),
                                onSearchTap: () => toast('Поиск: скоро'),
                                onVideoCallTap: () =>
                                    toast('Видеозвонок: скоро'),
                                onAudioCallTap: () =>
                                    toast('Аудиозвонок: скоро'),
                                onProfileTap: openProfile,
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
                    body: _buildChatBackground(
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
                                            controller: _scroll,
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
                                            onMessageLongPress: (m) =>
                                                _onMessageLongPress(
                                                  m,
                                                  user,
                                                  conv,
                                                  isGroup,
                                                  dmOtherId,
                                                  profile,
                                                ),
                                          ),
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
                            if (_selectedMessageIds.isEmpty)
                              _ChatComposer(
                                controller: _controller,
                                replyingTo: _replyingTo,
                                onCancelReply: () =>
                                    setState(() => _replyingTo = null),
                                onSend: () => _send(user.uid),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return msgsAsync.when(
                  skipLoadingOnReload: true,
                  data: (msgs) {
                    _maybeAttachHistoryLoader();
                    return chatShell(msgs, showSpinner: false);
                  },
                  loading: () =>
                      chatShell(const <ChatMessage>[], showSpinner: true),
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

  Future<void> _promptEditMessage(ChatMessage m) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final initial = messageHtmlToPlainText(m.text ?? '');
    final ctrl = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить сообщение'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Текст сообщения'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      ctrl.dispose();
      return;
    }
    final text = ctrl.text;
    ctrl.dispose();
    try {
      await repo.updateMessageText(
        conversationId: widget.conversationId,
        messageId: m.id,
        text: text,
      );
    } catch (e) {
      _toast('Не удалось сохранить: $e');
    }
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
    UserProfile? profile,
  ) async {
    final isMine = m.senderId == user.uid;
    final canEdit =
        isMine && !m.isDeleted && (m.text?.trim().isNotEmpty ?? false);
    final canDelete = isMine && !m.isDeleted;
    final action = await showMessageActionSheet(
      context,
      message: m,
      canEdit: canEdit,
      canDelete: canDelete,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case MessageSheetAction.reply:
        setState(() {
          _replyingTo = buildReplyPreview(
            message: m,
            currentUserId: user.uid,
            isGroup: isGroup,
            otherUserId: otherId,
            otherUserName: profile?.name,
          );
        });
      case MessageSheetAction.forward:
        if (m.isDeleted) return;
        if (!mounted) return;
        context.push('/chats/forward', extra: <ChatMessage>[m]);
      case MessageSheetAction.pin:
        await _pinMessage(m, user, convWrap, isGroup, otherId, profile);
      case MessageSheetAction.select:
        setState(() => _selectedMessageIds.add(m.id));
      case MessageSheetAction.edit:
        await _promptEditMessage(m);
      case MessageSheetAction.delete:
        await _confirmDeleteMessages([m]);
    }
  }

  void _onScrollLoadOlder() {
    if (!_scroll.hasClients) return;
    // `ChatMessageList` uses `reverse: true`; older messages load when scrolled toward max offset.
    final pos = _scroll.position;
    final nearTop = pos.pixels >= pos.maxScrollExtent - 240;
    if (!nearTop) return;
    if (_loadingOlder) return;
    final prevPixels = pos.pixels;
    final prevMax = pos.maxScrollExtent;
    setState(() => _loadingOlder = true);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _limit += 50;
        _loadingOlder = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final newMax = _scroll.position.maxScrollExtent;
        final anchor = prevPixels + (newMax - prevMax);
        final min = _scroll.position.minScrollExtent;
        final max = _scroll.position.maxScrollExtent;
        final clamped = anchor.clamp(min, max).toDouble();
        if ((_scroll.position.pixels - clamped).abs() > 1) {
          _scroll.jumpTo(clamped);
        }
      });
    });
  }

  void _maybeAttachHistoryLoader() {
    if (_historyListenerAttached) return;
    _historyListenerAttached = true;
    _scroll.addListener(_onScrollLoadOlder);
  }

  Future<void> _send(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final replySnap = _replyingTo;
    _controller.clear();
    try {
      await repo.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: text,
        replyTo: replySnap,
      );
      if (mounted) {
        setState(() => _replyingTo = null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      _controller.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить сообщение: $e')),
      );
    }
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    this.replyingTo,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ReplyContext? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (replyingTo != null && onCancelReply != null)
              ComposerReplyBanner(
                replyTo: replyingTo!,
                onCancel: onCancelReply!,
              ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file_rounded),
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
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
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
                  child: IconButton(
                    onPressed: onSend,
                    icon: Icon(Icons.send_rounded, color: scheme.onPrimary),
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
