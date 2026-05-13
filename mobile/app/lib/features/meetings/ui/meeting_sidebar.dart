import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../chat/ui/chat_avatar.dart';
import '../data/meeting_chat_message.dart';
import '../data/meeting_chat_storage_upload.dart';
import '../data/meeting_models.dart';
import '../data/meeting_providers.dart';
import '../data/meeting_sidebar_tabs.dart';
import 'meeting_chat_message_bubble.dart';
import 'meeting_polls_panel.dart';

/// Сайдбар митинга:
///   - «Участники» — список members, для host — force-mute/kick;
///   - «Заявки»   — только host/admin **в приватном** митинге, сразу после
///     «Участники»;
///   - «Опросы»   — `meetings/{id}/polls`, паритет web;
///   - «Чат»      — `meetings/{id}/messages` (long-press → меню как в общем
///     чате, инлайн-правка/ответ, реакции).
///
/// Чат: live-лента, вложения в Storage (`meeting-attachments/…`), long-press
/// для копирования / правки текста / мягкого удаления (`isDeleted`). Пока
/// открыты «Участники» или «Заявки», на вкладке «Чат» показывается счётчик
/// новых сообщений. Репозиторий — [MeetingChatRepository], загрузка файлов —
/// см. `meeting_chat_storage_upload.dart`.
class MeetingSidebar extends ConsumerStatefulWidget {
  const MeetingSidebar({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.meeting,
    required this.participants,
    required this.requests,
    required this.isHostOrAdmin,
    required this.onClose,
    required this.onForceMuteAudio,
    required this.onForceMuteVideo,
    required this.onKick,
    required this.onApproveRequest,
    required this.onDenyRequest,
    this.initialTabIndex,
    this.requestedChatTabNonce = 0,
  });

  final String currentUserId;

  /// Имя, под которым будут публиковаться сообщения чата. Берём из
  /// `participants/{uid}.name` (или `displayName`) выше по дереву.
  final String currentUserName;
  final String? currentUserAvatar;

  final MeetingDoc meeting;
  final List<MeetingParticipant> participants;
  final List<MeetingRequestDoc> requests;
  final bool isHostOrAdmin;
  final VoidCallback onClose;
  final void Function(String userId) onForceMuteAudio;
  final void Function(String userId) onForceMuteVideo;
  final void Function(String userId) onKick;
  final void Function(String userId) onApproveRequest;
  final void Function(String userId) onDenyRequest;
  final int? initialTabIndex;

  /// Каждое изменение этого значения === «открыли шторку через иконку
  /// чата в шапке» — sidebar анимирует переключение на вкладку «Чат».
  final int requestedChatTabNonce;

  @override
  ConsumerState<MeetingSidebar> createState() => _MeetingSidebarState();
}

String? _strOrNull(dynamic v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

class _MeetingSidebarState extends ConsumerState<MeetingSidebar>
    with TickerProviderStateMixin {
  late MeetingSidebarTabsLayout _layout;
  late TabController _tabController;
  int _tabCount = 0;

  /// Маркер «дочитано до» для бейджа непрочитанных, пока открыта другая вкладка.
  String? _chatReadAnchorId;
  bool _chatFirstSnapshot = false;

  @override
  void initState() {
    super.initState();
    _rebuildTabControllerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MeetingSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meeting.id != widget.meeting.id) {
      _chatReadAnchorId = null;
      _chatFirstSnapshot = false;
    }
    _rebuildTabControllerIfNeeded();
    // Сигнал «открыли чат через иконку в шапке» — переключаемся на
    // вкладку «Чат» (даже если шторка уже была открыта на другой).
    if (oldWidget.requestedChatTabNonce != widget.requestedChatTabNonce &&
        widget.requestedChatTabNonce > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabController.index != _layout.chatIndex) {
          _tabController.animateTo(_layout.chatIndex);
        }
      });
    }
  }

  void _rebuildTabControllerIfNeeded() {
    final layout = MeetingSidebarTabsLayout.from(
      isPrivate: widget.meeting.isPrivate,
      isHostOrAdmin: widget.isHostOrAdmin,
    );
    if (_tabCount == layout.totalCount) {
      _layout = layout;
      return;
    }
    if (_tabCount > 0) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    _layout = layout;
    final initial = (widget.initialTabIndex ?? 0).clamp(0, layout.totalCount - 1);
    _tabController = TabController(
      length: layout.totalCount,
      vsync: this,
      initialIndex: initial,
    );
    _tabController.addListener(_onTabChanged);
    _tabCount = layout.totalCount;
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    if (_tabController.index != _layout.chatIndex) return;
    final list =
        ref.read(meetingChatMessagesProvider(widget.meeting.id)).asData?.value;
    if (list != null && list.isNotEmpty) {
      setState(() => _chatReadAnchorId = list.last.id);
    }
  }

  void _onChatMessagesChanged(List<MeetingChatMessage> list) {
    if (!mounted) return;
    if (list.isEmpty) {
      setState(() {});
      return;
    }
    if (!_chatFirstSnapshot) {
      _chatFirstSnapshot = true;
      _chatReadAnchorId = list.last.id;
      setState(() {});
      return;
    }
    if (_tabController.index == _layout.chatIndex) {
      final lastId = list.last.id;
      if (_chatReadAnchorId != lastId) {
        setState(() => _chatReadAnchorId = lastId);
      }
      return;
    }
    setState(() {});
  }

  int _chatUnreadCount(List<MeetingChatMessage> list) {
    if (_chatReadAnchorId == null) return 0;
    final idx = list.indexWhere((m) => m.id == _chatReadAnchorId);
    if (idx < 0) return list.isNotEmpty ? 1 : 0;
    return list.length - idx - 1;
  }

  @override
  void dispose() {
    if (_tabCount > 0) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rebuildTabControllerIfNeeded();

    ref.listen<AsyncValue<List<MeetingChatMessage>>>(
      meetingChatMessagesProvider(widget.meeting.id),
      (prev, next) {
        next.whenData(_onChatMessagesChanged);
      },
    );

    final chatAsync = ref.watch(meetingChatMessagesProvider(widget.meeting.id));
    final chatList = chatAsync.asData?.value;
    final unread = chatList == null ? 0 : _chatUnreadCount(chatList);

    final pollsAsync = ref.watch(meetingPollsProvider(widget.meeting.id));
    final activePolls = switch (pollsAsync) {
      AsyncData(:final value) =>
        value.where((p) => p.status == 'active').length,
      _ => 0,
    };

    final l10n = AppLocalizations.of(context)!;
    final tabs = <Tab>[
      Tab(text: l10n.meeting_tab_participants(widget.participants.length.toString())),
      if (_layout.showRequests)
        Tab(text: l10n.meeting_tab_requests(widget.requests.length.toString())),
      Tab(
        text: activePolls > 0
            ? l10n.meeting_tab_polls_count(activePolls.toString())
            : l10n.meeting_tab_polls,
      ),
      Tab(
        text: unread > 0
            ? l10n.meeting_tab_chat_count(unread.toString())
            : l10n.meeting_tab_chat,
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x99101521),
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _header(context),
                TabBar(
                  controller: _tabController,
                  tabs: tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: const Color(0xFF3B82F6),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _participantsList(context),
                      if (_layout.showRequests) _requestsList(context),
                      _pollsTab(context),
                      _chatTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.meeting.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _participantsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.participants.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Colors.white10),
      itemBuilder: (context, i) {
        final p = widget.participants[i];
        final isSelf = p.id == widget.currentUserId;
        final isHost = widget.meeting.hostId == p.id;
        final canModerate = widget.isHostOrAdmin && !isSelf && !isHost;
        // Поверх никнейма (введённого при джойне) тянем глобальное имя
        // из `users/{uid}` — то самое, под которым человек виден в чатах.
        final overlay = ref.watch(
          userChatSettingsDocProvider(p.id),
        ).asData?.value ?? const <String, dynamic>{};
        final profileName = _strOrNull(overlay['name']);
        final profileAvatar = _strOrNull(overlay['avatar']) ??
            _strOrNull(overlay['avatarThumb']);
        final displayName = profileName ?? p.name;
        return ListTile(
          leading: ChatAvatar(
            title: displayName,
            radius: 18,
            avatarUrl: profileAvatar ?? p.avatarThumb ?? p.avatar,
          ),
          title: Text(
            isSelf ? '$displayName (Вы)' : displayName,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: isHost
              ? Text(l10n.meeting_host_label,
                  style: const TextStyle(color: Color(0xFF60A5FA)))
              : null,
          trailing: canModerate
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white70),
                  onSelected: (v) {
                    switch (v) {
                      case 'mute_audio':
                        widget.onForceMuteAudio(p.id);
                      case 'mute_video':
                        widget.onForceMuteVideo(p.id);
                      case 'kick':
                        widget.onKick(p.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'mute_audio',
                      child: Text(l10n.meeting_force_mute_mic),
                    ),
                    PopupMenuItem(
                      value: 'mute_video',
                      child: Text(l10n.meeting_force_mute_camera),
                    ),
                    PopupMenuItem(
                      value: 'kick',
                      child: Text(l10n.meeting_kick,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.isAudioMuted)
                      const Icon(Icons.mic_off_rounded,
                          size: 16, color: Colors.redAccent),
                    if (p.isVideoMuted) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.videocam_off_rounded,
                          size: 16, color: Colors.white70),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _pollsTab(BuildContext context) {
    return MeetingPollsPanel(
      meetingId: widget.meeting.id,
      currentUserId: widget.currentUserId,
      participants: widget.participants,
      isHostOrAdmin: widget.isHostOrAdmin,
    );
  }

  Widget _chatTab(BuildContext context) {
    final async = ref.watch(meetingChatMessagesProvider(widget.meeting.id));
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.meeting_chat_load_error(e.toString()),
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (messages) => _ChatTabBody(
        meetingId: widget.meeting.id,
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
        currentUserAvatar: widget.currentUserAvatar,
        messages: messages,
        tabController: _tabController,
        chatTabIndex: _layout.chatIndex,
      ),
    );
  }

  Widget _requestsList(BuildContext context) {
    if (widget.requests.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.meeting_no_requests,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.requests.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Colors.white10),
      itemBuilder: (context, i) {
        final r = widget.requests[i];
        final isPending = r.status == 'pending';
        return ListTile(
          leading: ChatAvatar(
            title: r.name,
            radius: 18,
            avatarUrl: r.avatar,
          ),
          title:
              Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            r.status,
            style: TextStyle(
              color: r.status == 'pending'
                  ? Colors.amber
                  : r.status == 'approved'
                      ? const Color(0xFF34D399)
                      : Colors.redAccent,
              fontSize: 12,
            ),
          ),
          trailing: isPending
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_rounded,
                          color: Color(0xFF34D399)),
                      onPressed: () => widget.onApproveRequest(r.userId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.redAccent),
                      onPressed: () => widget.onDenyRequest(r.userId),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

/// Внутренности вкладки «Чат»: список, вложения, инлайн правка/ответ,
/// реакции, автопрокрутка. Меню действий вынесено в [MeetingChatMessageBubble].
class _ChatTabBody extends ConsumerStatefulWidget {
  const _ChatTabBody({
    required this.meetingId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.messages,
    required this.tabController,
    required this.chatTabIndex,
  });

  final String meetingId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final List<MeetingChatMessage> messages;
  final TabController tabController;
  final int chatTabIndex;

  @override
  ConsumerState<_ChatTabBody> createState() => _ChatTabBodyState();
}

class _StagedAttachment {
  _StagedAttachment({required this.name, required this.bytes, this.mime});
  final String name;
  final Uint8List bytes;
  final String? mime;
}

class _ChatTabBodyState extends ConsumerState<_ChatTabBody> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  bool _sending = false;
  final List<_StagedAttachment> _staging = [];

  /// Идёт инлайн-правка: id целевого сообщения + превью текста.
  String? _editingMessageId;
  String? _editingPreview;

  /// Активный reply (то, что покажется выше композера).
  MeetingChatMessage? _replyTo;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.messages.length;
    widget.tabController.addListener(_onTabVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant _ChatTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController.removeListener(_onTabVisible);
      widget.tabController.addListener(_onTabVisible);
    }
    if (widget.messages.length != _lastMessageCount) {
      _lastMessageCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onTabVisible() {
    if (!widget.tabController.indexIsChanging &&
        widget.tabController.index == widget.chatTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (widget.tabController.index != widget.chatTabIndex) return;
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabVisible);
    _scroll.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final r = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    const maxFiles = 10;
    const maxBytes = 40 * 1024 * 1024;
    final add = <_StagedAttachment>[];
    for (final f in r.files) {
      if (_staging.length + add.length >= maxFiles) break;
      var b = f.bytes;
      if (b == null && f.path != null) {
        try {
          b = await File(f.path!).readAsBytes();
        } catch (_) {}
      }
      if (b == null) continue;
      if (b.length > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.meeting_file_too_big(f.name))),
          );
        }
        continue;
      }
      final name = f.name.isNotEmpty ? f.name : 'file';
      add.add(_StagedAttachment(name: name, bytes: b, mime: null));
    }
    if (add.isEmpty) return;
    setState(() => _staging.addAll(add));
  }

  void _startInlineEdit(MeetingChatMessage msg) {
    final raw = msg.text ?? '';
    setState(() {
      _editingMessageId = msg.id;
      _editingPreview =
          raw.length > 140 ? '${raw.substring(0, 140)}…' : raw;
      _replyTo = null;
      _input.text = raw;
      _input.selection =
          TextSelection.fromPosition(TextPosition(offset: raw.length));
    });
    FocusScope.of(context).requestFocus(_inputFocus);
  }

  void _cancelInlineEdit() {
    setState(() {
      _editingMessageId = null;
      _editingPreview = null;
      _input.clear();
    });
  }

  void _startReply(MeetingChatMessage msg) {
    setState(() {
      _replyTo = msg;
      _editingMessageId = null;
      _editingPreview = null;
    });
    FocusScope.of(context).requestFocus(_inputFocus);
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
  }

  Future<void> _toggleReaction(
    MeetingChatMessage msg,
    String emoji,
    bool currentlyReacted,
  ) async {
    try {
      await ref.read(meetingChatRepositoryProvider).toggleReaction(
            meetingId: widget.meetingId,
            messageId: msg.id,
            userId: widget.currentUserId,
            emoji: emoji,
            currentlyReacted: currentlyReacted,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_save_error(e.toString()))),
      );
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final textRaw = _input.text;
    if (textRaw.trim().isEmpty && _staging.isEmpty && _editingMessageId == null) {
      return;
    }
    // l10n надо взять до первого `await` — после suspend BuildContext
    // нестабилен.
    final attachmentPlaceholder =
        AppLocalizations.of(context)!.meeting_chat_attachment_placeholder;
    setState(() => _sending = true);
    try {
      // Инлайн-правка существующего сообщения.
      if (_editingMessageId != null) {
        await ref.read(meetingChatRepositoryProvider).updateMessageText(
              meetingId: widget.meetingId,
              messageId: _editingMessageId!,
              text: textRaw,
            );
        if (!mounted) return;
        setState(() {
          _editingMessageId = null;
          _editingPreview = null;
          _input.clear();
        });
        return;
      }

      final storage = ref.read(meetingFirebaseStorageProvider);
      final maps = <Map<String, dynamic>>[];
      for (final s in _staging) {
        final att = await uploadMeetingChatBytes(
          storage: storage,
          meetingId: widget.meetingId,
          bytes: s.bytes,
          displayName: s.name,
          mimeType: s.mime,
        );
        maps.add(att.toFirestoreMap());
      }

      Map<String, dynamic>? replyToMap;
      final r = _replyTo;
      if (r != null) {
        final preview = (r.text != null && r.text!.isNotEmpty)
            ? r.text!
            : (r.attachments.isNotEmpty ? attachmentPlaceholder : '');
        replyToMap = MeetingChatReplyTo(
          messageId: r.id,
          senderId: r.senderId,
          senderName: r.senderName,
          preview: preview.length > 200 ? '${preview.substring(0, 200)}…' : preview,
        ).toMap();
      }

      await ref.read(meetingChatRepositoryProvider).sendMessage(
            meetingId: widget.meetingId,
            senderId: widget.currentUserId,
            senderName: widget.currentUserName,
            text: textRaw,
            attachmentMaps: maps,
            replyToMap: replyToMap,
            senderAvatar: widget.currentUserAvatar,
          );
      _input.clear();
      setState(() {
        _staging.clear();
        _replyTo = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_send_error(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelete(MeetingChatMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.meeting_delete_message_title),
        content: Text(AppLocalizations.of(context)!.meeting_delete_message_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(meetingChatRepositoryProvider).softDeleteMessage(
            meetingId: widget.meetingId,
            messageId: msg.id,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_delete_error(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emptyList = widget.messages.isEmpty && _staging.isEmpty;
    return Column(
      children: [
        Expanded(
          child: emptyList
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.meeting_no_messages,
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.messages.length,
                  itemBuilder: (ctx, i) {
                    final m = widget.messages[i];
                    final isSelf = m.senderId == widget.currentUserId;
                    return MeetingChatMessageBubble(
                      message: m,
                      isSelf: isSelf,
                      selfUserId: widget.currentUserId,
                      onEditText: isSelf ? _startInlineEdit : null,
                      onDelete: isSelf ? () => _confirmDelete(m) : null,
                      onReply: _startReply,
                      onToggleReaction: _toggleReaction,
                    );
                  },
                ),
        ),
        _inputBar(),
      ],
    );
  }

  Widget _inputBar() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editingMessageId != null)
            _ComposerEditingBanner(
              previewPlain: _editingPreview ?? '',
              onCancel: _cancelInlineEdit,
              l10n: l10n,
            ),
          if (_replyTo != null)
            _ComposerReplyBanner(
              replyTo: _replyTo!,
              onCancel: _cancelReply,
              l10n: l10n,
            ),
          if (_staging.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _staging.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final s = _staging[i];
                  return Chip(
                    label: Text(
                      s.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: _sending
                        ? null
                        : () => setState(() => _staging.removeAt(i)),
                    deleteIconColor: Colors.white70,
                    backgroundColor: Colors.white12,
                    labelStyle: const TextStyle(color: Colors.white70),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_editingMessageId == null)
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded,
                        color: Colors.white54),
                    onPressed: _sending ? null : _pickAttachments,
                  ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF60A5FA),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.meeting_message_hint,
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Send button: высота композера (40 px) — паритет с основным
                // чатом мобилки. Раньше было 44 px и кнопка торчала.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sending
                        ? Colors.white12
                        : const Color(0xFF2A79FF),
                    boxShadow: _sending
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x592A79FF),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Полоса над композером при инлайн-правке текста — стилем зеркалит
/// `ComposerEditingBanner` основного чата.
class _ComposerEditingBanner extends StatelessWidget {
  const _ComposerEditingBanner({
    required this.previewPlain,
    required this.onCancel,
    required this.l10n,
  });
  final String previewPlain;
  final VoidCallback onCancel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_rounded, size: 22, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meeting_chat_editing.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                    if (previewPlain.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        previewPlain,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerReplyBanner extends StatelessWidget {
  const _ComposerReplyBanner({
    required this.replyTo,
    required this.onCancel,
    required this.l10n,
  });
  final MeetingChatMessage replyTo;
  final VoidCallback onCancel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final preview = (replyTo.text != null && replyTo.text!.isNotEmpty)
        ? replyTo.text!
        : (replyTo.attachments.isNotEmpty
            ? l10n.meeting_chat_attachment_placeholder
            : '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.reply_rounded,
                  size: 22, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meeting_chat_reply_to(replyTo.senderName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
