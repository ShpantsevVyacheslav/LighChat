import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/partner_presence_line.dart';
import '../data/phone_display.dart';
import '../data/profile_attachment_stats.dart';
import '../data/profile_field_visibility.dart';
import '../data/saved_messages_chat.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'e2ee_fingerprint_badge.dart';
import 'chat_conversation_notifications_screen.dart';
import 'conversation_encryption_screen.dart';
import 'conversation_media_links_files_screen.dart';
import 'conversation_starred_screen.dart';
import 'chat_shell_backdrop.dart';
import 'user_avatar_fullscreen_viewer.dart';

const _kRoleLabels = {'admin': 'Администратор', 'worker': 'Участник'};

class ChatPartnerProfileSheet extends ConsumerStatefulWidget {
  const ChatPartnerProfileSheet({
    super.key,
    required this.conversationId,
    required this.conversation,
    required this.currentUserId,
    required this.selfProfile,
    required this.partnerProfile,
    this.onJumpToMessageId,
    this.fullScreen = false,
  });

  final String conversationId;
  final Conversation conversation;
  final String currentUserId;
  final UserProfile? selfProfile;
  final UserProfile? partnerProfile;
  final void Function(String messageId)? onJumpToMessageId;
  final bool fullScreen;

  @override
  ConsumerState<ChatPartnerProfileSheet> createState() =>
      _ChatPartnerProfileSheetState();
}

class _ChatPartnerProfileSheetState
    extends ConsumerState<ChatPartnerProfileSheet> {
  bool _addContactBusy = false;

  bool get _isGroup => widget.conversation.isGroup;

  bool get _isSaved =>
      isSavedMessagesConversation(widget.conversation, widget.currentUserId);

  String? get _dmPartnerId {
    if (_isGroup || _isSaved) return null;
    final others = widget.conversation.participantIds
        .where((id) => id != widget.currentUserId)
        .toList();
    return others.isEmpty ? null : others.first;
  }

  String get _displayTitle {
    if (_isGroup) return widget.conversation.name ?? 'Групповой чат';
    if (_isSaved) return widget.conversation.name ?? 'Избранное';
    final pid = _dmPartnerId;
    if (pid != null) {
      final fromConv = widget.conversation.participantInfo?[pid]?.name;
      return widget.partnerProfile?.name ?? fromConv ?? 'Чат';
    }
    return 'Чат';
  }

  String? get _displayAvatarUrl {
    if (_isGroup) return widget.conversation.photoUrl;
    if (_isSaved) {
      return widget.selfProfile?.avatarThumb ?? widget.selfProfile?.avatar;
    }
    final pid = _dmPartnerId;
    return widget.partnerProfile?.avatarThumb ??
        widget.partnerProfile?.avatar ??
        (pid == null
            ? null
            : widget.conversation.participantInfo?[pid]?.avatarThumb) ??
        (pid == null
            ? null
            : widget.conversation.participantInfo?[pid]?.avatar);
  }

  /// Для полноэкранного просмотра: сначала полный `avatar`, иначе превью (как на вебе).
  String? _fullscreenAvatarUrl() {
    if (_isGroup) {
      final u = (widget.conversation.photoUrl ?? '').trim();
      return u.isEmpty ? null : u;
    }
    if (_isSaved) {
      final self = widget.selfProfile;
      final full = (self?.avatar ?? '').trim();
      if (full.isNotEmpty) return full;
      final t = (self?.avatarThumb ?? '').trim();
      return t.isEmpty ? null : t;
    }
    final pid = _dmPartnerId;
    if (pid == null) return null;
    final p = widget.partnerProfile;
    final full = (p?.avatar ?? '').trim();
    if (full.isNotEmpty) return full;
    final fromConv = (widget.conversation.participantInfo?[pid]?.avatar ?? '')
        .trim();
    if (fromConv.isNotEmpty) return fromConv;
    final thumbP = (p?.avatarThumb ?? '').trim();
    if (thumbP.isNotEmpty) return thumbP;
    final fromConvT =
        (widget.conversation.participantInfo?[pid]?.avatarThumb ?? '').trim();
    if (fromConvT.isNotEmpty) return fromConvT;
    return null;
  }

  void _openAvatarFullscreen() {
    final url = _fullscreenAvatarUrl()?.trim();
    if (url == null || url.isEmpty) {
      return;
    }
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UserAvatarFullscreenViewer(imageUrl: url),
        ),
      ),
    );
  }

  /// При username раньше терялась строка «последний вход».
  (String, String?) _profileHeaderSubtitles(String statusForDm) {
    if (_isGroup) {
      final d = widget.conversation.description?.trim();
      if (d != null && d.isNotEmpty) return (d, null);
      return ('${widget.conversation.participantIds.length} участников', null);
    }
    if (_isSaved) return ('Сообщения и заметки только для вас', null);
    final u = widget.partnerProfile?.username?.trim();
    if (u != null && u.isNotEmpty) {
      final second = statusForDm.trim().isEmpty ? null : statusForDm;
      final at = u.startsWith('@') ? u : '@$u';
      return (at, second);
    }
    return (statusForDm, null);
  }

  UserProfile? _contactTarget(String? partnerId) {
    if (partnerId == null) return null;
    if (widget.partnerProfile != null &&
        widget.partnerProfile!.id == partnerId) {
      return widget.partnerProfile;
    }
    final info = widget.conversation.participantInfo?[partnerId];
    if (info == null) return widget.partnerProfile;
    return UserProfile(
      id: partnerId,
      name: info.name,
      avatar: info.avatar,
      avatarThumb: info.avatarThumb,
    );
  }

  bool _hasContactDetailRows(UserProfile? fresh, String? partnerId) {
    if (partnerId == null || _isSaved || _isGroup) return false;
    final p = widget.partnerProfile;
    final role = p?.role;
    if (role != null && role.isNotEmpty && role != 'worker') return true;
    if (fresh == null) return false;
    if (isProfileFieldVisibleToOthers(fresh, 'email') &&
        (fresh.email != null && fresh.email!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'phone') &&
        (fresh.phone != null && fresh.phone!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'dateOfBirth') &&
        (fresh.dateOfBirth != null && fresh.dateOfBirth!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'bio') &&
        (fresh.bio != null && fresh.bio!.trim().isNotEmpty)) {
      return true;
    }
    return false;
  }

  bool _canShowAddToContacts(
    UserProfile? target,
    String? partnerId,
    List<String> contactIds,
  ) {
    if (partnerId == null || partnerId == widget.currentUserId || _isSaved) {
      return false;
    }
    if (_isGroup) return false;
    if (target == null ||
        (target.deletedAt != null && target.deletedAt!.isNotEmpty)) {
      return false;
    }
    final self = widget.selfProfile;
    if (self == null) return false;
    final isContact = contactIds.contains(partnerId);
    if (isContact) return true;
    return canStartDirectChat(self, target);
  }

  bool _isGroupAdmin() {
    if (!_isGroup) return false;
    if (widget.conversation.createdByUserId == widget.currentUserId) {
      return true;
    }
    return widget.conversation.adminIds.contains(widget.currentUserId);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onAddContact(String partnerId) async {
    final repo = ref.read(userContactsRepositoryProvider);
    if (repo == null) return;
    setState(() => _addContactBusy = true);
    try {
      await repo.addContactId(widget.currentUserId, partnerId);
      if (mounted) _toast('Добавлено в контакты');
    } catch (e) {
      if (mounted) _toast('Не удалось добавить в контакты');
    } finally {
      if (mounted) setState(() => _addContactBusy = false);
    }
  }

  Future<void> _onRemoveContact(String partnerId) async {
    final repo = ref.read(userContactsRepositoryProvider);
    if (repo == null) return;
    setState(() => _addContactBusy = true);
    try {
      await repo.removeContactId(widget.currentUserId, partnerId);
      if (mounted) _toast('Удалено из контактов');
    } catch (e) {
      if (mounted) _toast('Не удалось удалить из контактов');
    } finally {
      if (mounted) setState(() => _addContactBusy = false);
    }
  }

  Future<void> _copyChatId() async {
    await Clipboard.setData(ClipboardData(text: widget.conversationId));
    if (mounted) _toast('Идентификатор чата скопирован');
  }

  Future<void> _openStarredMessages() async {
    final selectedMessageId = await Navigator.of(context).push<String>(
      CupertinoPageRoute(
        builder: (_) => ConversationStarredScreen(
          conversationId: widget.conversationId,
          currentUserId: widget.currentUserId,
          conversation: widget.conversation,
        ),
      ),
    );
    if (!mounted) return;
    if (selectedMessageId == null || selectedMessageId.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onJumpToMessageId?.call(selectedMessageId.trim());
  }

  Future<void> _openMediaLinksFiles() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (_) => ConversationMediaLinksFilesScreen(
          conversationId: widget.conversationId,
          currentUserId: widget.currentUserId,
          conversation: widget.conversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerId = _dmPartnerId;
    final fresh = widget.partnerProfile;
    final statusDm = partnerPresenceLine(fresh);
    final (subtitleLine1, subtitleLine2) = _profileHeaderSubtitles(statusDm);

    final contactsAsync = ref.watch(
      userContactsIndexProvider(widget.currentUserId),
    );
    final contactIds = contactsAsync.value?.contactIds ?? const <String>[];
    final target = _contactTarget(partnerId);
    final showAdd =
        partnerId != null &&
        _canShowAddToContacts(target, partnerId, contactIds);
    final isContact = partnerId != null && contactIds.contains(partnerId);
    final hasDetailRows = _hasContactDetailRows(fresh, partnerId);

    final msgsAsync = ref.watch(
      messagesProvider((conversationId: widget.conversationId, limit: 400)),
    );
    final mediaCount = msgsAsync.when(
      data: (m) => profileMediaDocsCount(m),
      loading: () => 0,
      error: (_, _) => 0,
    );
    final mediaLabel = mediaCount == 0 ? 'Нет' : '$mediaCount';
    final starredIdsAsync = ref.watch(
      starredMessageIdsInConversationProvider((
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
      )),
    );
    final starredCount = starredIdsAsync.value?.length ?? 0;
    final starredLabel = starredCount == 0 ? 'Нет' : '$starredCount';

    final threadsCount = msgsAsync.when(
      data: (m) =>
          m.where((x) => !x.isDeleted && (x.threadCount ?? 0) > 0).length,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final threadsLabel = threadsCount == 0 ? 'Нет' : '$threadsCount';

    final showEncryptionRow = !_isGroup && !_isSaved;
    final e2eeOn =
        widget.conversation.e2eeEnabled == true &&
        (widget.conversation.e2eeKeyEpoch ?? 0) > 0;
    final encryptionLabel = e2eeOn ? 'Вкл' : 'Выкл';

    final roleLabel = fresh?.role;
    final roleDisplay = roleLabel == null || roleLabel.isEmpty
        ? null
        : (_kRoleLabels[roleLabel] ?? roleLabel);

    const hiPrimary = Color(0xFFF2F4FA);
    const hiMuted = Color(0xFFB4BDD1);
    const hiFaint = Color(0xFF8B95AD);

    final encryptionSubtitle = e2eeOn
        ? 'Сквозное шифрование включено. Нажмите для подробностей.'
        : 'Сквозное шифрование выключено. Нажмите, чтобы включить.';

    List<Widget> buildScrollChildren() {
      return [
          if (!widget.fullScreen) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: hiPrimary.withValues(alpha: 0.94),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: widget.fullScreen ? 'Назад' : 'Закрыть',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 22),
                  color: hiPrimary.withValues(alpha: 0.94),
                  onPressed: _copyChatId,
                  tooltip: 'Скопировать ID чата',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_fullscreenAvatarUrl() ?? '').trim().isNotEmpty
                        ? _openAvatarFullscreen
                        : null,
                    customBorder: const CircleBorder(),
                    child: ChatAvatar(
                      title: _displayTitle,
                      radius: 54,
                      avatarUrl: _displayAvatarUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: hiPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitleLine1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: hiMuted,
                  ),
                ),
                if (subtitleLine2 != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitleLine2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: hiMuted.withValues(alpha: 0.82),
                    ),
                  ),
                ],
                if (partnerId != null &&
                    (isContact || showAdd) &&
                    !_isGroup &&
                    !_isSaved) ...[
                  const SizedBox(height: 18),
                  _ContactPill(
                    isContact: isContact,
                    busy: _addContactBusy,
                    onPressed: _addContactBusy
                        ? null
                        : () => isContact
                            ? _onRemoveContact(partnerId)
                            : _onAddContact(partnerId),
                  ),
                ],
                const SizedBox(height: 18),
                if (hasDetailRows && fresh != null && partnerId != null)
                  _buildContactDataExpansion(
                    context,
                    fresh: fresh,
                    roleDisplay: roleDisplay,
                  ),
                if (_isGroup) ...[
                  _menuButton(
                    context,
                    icon: Icons.group_rounded,
                    title: 'Участники',
                    trailing:
                        '${widget.conversation.participantIds.length}',
                    onTap: () => _toast('Участники: скоро'),
                  ),
                  if (_isGroupAdmin())
                    _menuButton(
                      context,
                      icon: Icons.edit_rounded,
                      title: 'Редактировать группу',
                      onTap: () => _toast('Редактирование группы: скоро'),
                    ),
                  _sectionDivider(),
                ],
                _menuButton(
                  context,
                  icon: Icons.perm_media_rounded,
                  title: 'Медиа, ссылки и файлы',
                  trailing: mediaLabel,
                  onTap: _openMediaLinksFiles,
                ),
                _menuButton(
                  context,
                  icon: Icons.star_rounded,
                  title: 'Избранное',
                  trailing: starredLabel,
                  onTap: _openStarredMessages,
                ),
                _menuButton(
                  context,
                  icon: Icons.forum_rounded,
                  title: 'Обсуждения',
                  trailing: threadsLabel,
                  onTap: () {
                    if (!widget.fullScreen) {
                      Navigator.of(context).pop();
                    }
                    context.push(
                      '/chats/${widget.conversationId}/threads',
                    );
                  },
                ),
                _sectionDivider(),
                _menuButton(
                  context,
                  icon: Icons.notifications_rounded,
                  title: 'Уведомления',
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      CupertinoPageRoute(
                        builder: (_) =>
                            ChatConversationNotificationsScreen(
                              currentUserId: widget.currentUserId,
                              conversationId: widget.conversationId,
                            ),
                      ),
                    );
                  },
                ),
                _menuButton(
                  context,
                  icon: Icons.palette_rounded,
                  title: 'Тема чата',
                  onTap: () => _toast('Тема чата: скоро'),
                ),
                _menuButton(
                  context,
                  icon: Icons.timer_rounded,
                  title: 'Исчезающие сообщения',
                  trailing: 'Выкл',
                  onTap: () => _toast('Скоро'),
                ),
                _menuButton(
                  context,
                  icon: Icons.shield_rounded,
                  title: 'Расширенная приватность чата',
                  trailing: 'По умолчанию',
                  onTap: () => _toast('Приватность: скоро'),
                ),
                if (showEncryptionRow)
                  _menuButton(
                    context,
                    icon: Icons.lock_rounded,
                    title: 'Шифрование',
                    subtitle: encryptionSubtitle,
                    trailing: encryptionLabel,
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        CupertinoPageRoute<void>(
                          builder: (_) => ConversationEncryptionScreen(
                            conversationId: widget.conversationId,
                            currentUserId: widget.currentUserId,
                            conversation: widget.conversation,
                          ),
                        ),
                      );
                    },
                  ),
                // Phase 8: отпечаток E2EE собеседника в DM. Рисуем, только
                // если шифрование включено и это не группа/Saved.
                if (showEncryptionRow && e2eeOn && partnerId != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
                    child: E2eeFingerprintBadge(
                      firestore: FirebaseFirestore.instance,
                      userId: partnerId,
                      userLabel: fresh?.name ?? _displayTitle,
                    ),
                  ),
                ],
                if (!_isSaved && !_isGroup && partnerId != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    'НЕТ ОБЩИХ ГРУПП',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: hiFaint.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _menuButton(
                    context,
                    icon: Icons.group_add_rounded,
                    title:
                        'Создать группу с ${fresh?.name ?? _displayTitle}',
                    onTap: () => _toast('Скоро'),
                  ),
                ],
                if (_isGroup) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: hiPrimary.withValues(alpha: 0.88),
                    ),
                    onPressed: () => _toast('Покинуть группу: скоро'),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Покинуть группу'),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
      ];
    }

    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildScrollChildren(),
          ),
        ),
      ],
    );

    final backdrop = Stack(
      fit: StackFit.expand,
      children: [
        const ChatShellBackdrop(),
        Stack(
          fit: StackFit.expand,
          children: [
            if (!widget.fullScreen)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
            Positioned.fill(
              child: SafeArea(
                child: widget.fullScreen
                    ? scroll
                    : Column(
                        children: [
                          Expanded(child: scroll),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.fullScreen
          ? backdrop
          : Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: backdrop,
                ),
              ),
            ),
    );
  }

  /// Раскрывающийся блок «Контакты и данные» — те же поля, что и раньше.
  Widget _buildContactDataExpansion(
    BuildContext context, {
    required UserProfile fresh,
    required String? roleDisplay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: const Text(
              'Контакты и данные',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFFF2F4FA),
              ),
            ),
            iconColor: const Color(0xFFB4BDD1),
            collapsedIconColor: const Color(0xFFB4BDD1),
            initiallyExpanded: false,
            children: [
              if (roleDisplay != null &&
                  fresh.role != null &&
                  fresh.role!.isNotEmpty &&
                  fresh.role != 'worker')
                _detailTile(
                  context,
                  Icons.verified_user_rounded,
                  'Роль в системе',
                  roleDisplay,
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'email') &&
                  fresh.email != null &&
                  fresh.email!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.mail_rounded,
                  'Электронная почта',
                  fresh.email!,
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'phone') &&
                  fresh.phone != null &&
                  fresh.phone!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.smartphone_rounded,
                  'Телефон',
                  formatPhoneNumberForDisplay(fresh.phone!),
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'dateOfBirth') &&
                  fresh.dateOfBirth != null &&
                  fresh.dateOfBirth!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.cake_rounded,
                  'День рождения',
                  fresh.dateOfBirth!,
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'bio') &&
                  fresh.bio != null &&
                  fresh.bio!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'О себе',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.48),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fresh.bio!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Color(0xFFF2F4FA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }

  Widget _detailTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFF2F4FA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFFF2F4FA),
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: Colors.white.withValues(alpha: 0.52),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({
    required this.isContact,
    required this.busy,
    this.onPressed,
  });

  final bool isContact;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = Color(0xFFF2F4FA).withValues(alpha: enabled ? 0.95 : 0.42);
    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          busy
              ? Icons.hourglass_top_rounded
              : (isContact
                    ? Icons.person_remove_outlined
                    : Icons.person_add_rounded),
          size: 19,
          color: fg,
        ),
        label: Text(
          isContact ? 'Удалить из контактов' : 'Добавить в контакты',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: fg,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
