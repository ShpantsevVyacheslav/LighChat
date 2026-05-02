import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_chat_message.dart';
import '../data/meeting_chat_storage_upload.dart';
import '../data/meeting_models.dart';
import '../data/meeting_providers.dart';
import 'meeting_chat_message_bubble.dart';
import 'meeting_polls_panel.dart';

/// Сайдбар митинга:
///   - «Участники» — список members, для host — force-mute/kick;
///   - «Опросы»   — `meetings/{id}/polls`, паритет web;
///   - «Чат»      — `meetings/{id}/messages`;
///   - «Заявки»   — только host/admin.
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
  });

  final String currentUserId;

  /// Имя, под которым будут публиковаться сообщения чата. Берём из
  /// `participants/{uid}.name` (или `displayName`) выше по дереву.
  final String currentUserName;

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

  @override
  ConsumerState<MeetingSidebar> createState() => _MeetingSidebarState();
}

class _MeetingSidebarState extends ConsumerState<MeetingSidebar>
    with TickerProviderStateMixin {
  /// Индекс вкладки «Чат» (после «Участники» и «Опросы»).
  static const int _kChatTabIndex = 2;

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
  }

  void _rebuildTabControllerIfNeeded() {
    final count = 3 + (widget.isHostOrAdmin ? 1 : 0);
    if (_tabCount == count) return;
    if (_tabCount > 0) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    _tabController = TabController(length: count, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabCount = count;
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    if (_tabController.index != _kChatTabIndex) return;
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
    if (_tabController.index == _kChatTabIndex) {
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
      Tab(
        text: activePolls > 0 ? l10n.meeting_tab_polls_count(activePolls.toString()) : l10n.meeting_tab_polls,
      ),
      Tab(text: unread > 0 ? l10n.meeting_tab_chat_count(unread.toString()) : l10n.meeting_tab_chat),
      if (widget.isHostOrAdmin) Tab(text: l10n.meeting_tab_requests(widget.requests.length.toString())),
    ];
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: const Color(0xFF0B1020),
        child: Column(
          children: [
            _header(context),
            TabBar(
              controller: _tabController,
              tabs: tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: const Color(0xFF3B82F6),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _participantsList(context),
                  _pollsTab(context),
                  _chatTab(context),
                  if (widget.isHostOrAdmin) _requestsList(context),
                ],
              ),
            ),
          ],
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
      separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
      itemBuilder: (context, i) {
        final p = widget.participants[i];
        final isSelf = p.id == widget.currentUserId;
        final isHost = widget.meeting.hostId == p.id;
        final canModerate = widget.isHostOrAdmin && !isSelf && !isHost;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1F2937),
            backgroundImage:
                p.avatarThumb != null ? NetworkImage(p.avatarThumb!) : null,
            child: p.avatarThumb == null
                ? Text(
                    p.name.characters.first.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            isSelf ? '${p.name} (Вы)' : p.name,
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
        messages: messages,
        tabController: _tabController,
        chatTabIndex: _kChatTabIndex,
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
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1F2937),
            backgroundImage:
                r.avatar != null ? NetworkImage(r.avatar!) : null,
            child: r.avatar == null
                ? Text(
                    r.name.characters.first.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
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

/// Внутренности вкладки «Чат»: список, вложения, правка/удаление, автопрокрутка.
class _ChatTabBody extends ConsumerStatefulWidget {
  const _ChatTabBody({
    required this.meetingId,
    required this.currentUserId,
    required this.currentUserName,
    required this.messages,
    required this.tabController,
    required this.chatTabIndex,
  });

  final String meetingId;
  final String currentUserId;
  final String currentUserName;
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
  bool _sending = false;
  final List<_StagedAttachment> _staging = [];

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

  Future<void> _send() async {
    if (_sending) return;
    final textRaw = _input.text;
    if (textRaw.trim().isEmpty && _staging.isEmpty) return;
    setState(() => _sending = true);
    try {
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
      await ref.read(meetingChatRepositoryProvider).sendMessage(
            meetingId: widget.meetingId,
            senderId: widget.currentUserId,
            senderName: widget.currentUserName,
            text: textRaw,
            attachmentMaps: maps,
          );
      _input.clear();
      setState(() => _staging.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_send_error(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editMessage(MeetingChatMessage msg) async {
    final c = TextEditingController(text: msg.text ?? '');
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.meeting_edit_message_title),
        content: TextField(
          controller: c,
          maxLines: 5,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(AppLocalizations.of(context)!.common_save),
          ),
        ],
      ),
    );
    if (r == null || r.isEmpty) return;
    try {
      await ref.read(meetingChatRepositoryProvider).updateMessageText(
            meetingId: widget.meetingId,
            messageId: msg.id,
            text: r,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.meeting_save_error(e.toString()))),
      );
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
                      onEditText: isSelf ? _editMessage : null,
                      onDelete: isSelf ? () => _confirmDelete(m) : null,
                    );
                  },
                ),
        ),
        _inputBar(),
      ],
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded,
                      color: Colors.white54),
                  onPressed: _sending ? null : _pickAttachments,
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
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
                const SizedBox(width: 4),
                Material(
                  color: _sending
                      ? Colors.white12
                      : const Color(0xFF2563EB),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _send,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
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
