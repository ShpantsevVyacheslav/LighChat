import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

const _kRoleLabels = {'admin': 'Администратор', 'worker': 'Участник'};

class ChatPartnerProfileSheet extends ConsumerStatefulWidget {
  const ChatPartnerProfileSheet({
    super.key,
    required this.conversationId,
    required this.conversation,
    required this.currentUserId,
    required this.selfProfile,
    required this.partnerProfile,
  });

  final String conversationId;
  final Conversation conversation;
  final String currentUserId;
  final UserProfile? selfProfile;
  final UserProfile? partnerProfile;

  @override
  ConsumerState<ChatPartnerProfileSheet> createState() => _ChatPartnerProfileSheetState();
}

class _ChatPartnerProfileSheetState extends ConsumerState<ChatPartnerProfileSheet> {
  bool _addContactBusy = false;

  bool get _isGroup => widget.conversation.isGroup;

  bool get _isSaved => isSavedMessagesConversation(widget.conversation, widget.currentUserId);

  String? get _dmPartnerId {
    if (_isGroup || _isSaved) return null;
    final others = widget.conversation.participantIds.where((id) => id != widget.currentUserId).toList();
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
    if (_isSaved) return widget.selfProfile?.avatarThumb ?? widget.selfProfile?.avatar;
    final pid = _dmPartnerId;
    return widget.partnerProfile?.avatarThumb ??
        widget.partnerProfile?.avatar ??
        (pid == null ? null : widget.conversation.participantInfo?[pid]?.avatarThumb) ??
        (pid == null ? null : widget.conversation.participantInfo?[pid]?.avatar);
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
      return ('~$u', second);
    }
    return (statusForDm, null);
  }

  UserProfile? _contactTarget(String? partnerId) {
    if (partnerId == null) return null;
    if (widget.partnerProfile != null && widget.partnerProfile!.id == partnerId) {
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
    if (isProfileFieldVisibleToOthers(fresh, 'email') && (fresh.email != null && fresh.email!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'phone') && (fresh.phone != null && fresh.phone!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'dateOfBirth') &&
        (fresh.dateOfBirth != null && fresh.dateOfBirth!.trim().isNotEmpty)) {
      return true;
    }
    if (isProfileFieldVisibleToOthers(fresh, 'bio') && (fresh.bio != null && fresh.bio!.trim().isNotEmpty)) {
      return true;
    }
    return false;
  }

  bool _canShowAddToContacts(UserProfile? target, String? partnerId, List<String> contactIds) {
    if (partnerId == null || partnerId == widget.currentUserId || _isSaved) return false;
    if (_isGroup) return false;
    if (target == null || (target.deletedAt != null && target.deletedAt!.isNotEmpty)) return false;
    final self = widget.selfProfile;
    if (self == null) return false;
    final isContact = contactIds.contains(partnerId);
    if (isContact) return true;
    return canStartDirectChat(self, target);
  }

  bool _isGroupAdmin() {
    if (!_isGroup) return false;
    if (widget.conversation.createdByUserId == widget.currentUserId) return true;
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

  Future<void> _copyChatId() async {
    await Clipboard.setData(ClipboardData(text: widget.conversationId));
    if (mounted) _toast('Идентификатор чата скопирован');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final partnerId = _dmPartnerId;
    final fresh = widget.partnerProfile;
    final statusDm = partnerPresenceLine(fresh);
    final (subtitleLine1, subtitleLine2) = _profileHeaderSubtitles(statusDm);

    final contactsAsync = ref.watch(userContactsIndexProvider(widget.currentUserId));
    final contactIds = contactsAsync.value?.contactIds ?? const <String>[];
    final target = _contactTarget(partnerId);
    final showAdd = partnerId != null && _canShowAddToContacts(target, partnerId, contactIds);
    final isContact = partnerId != null && contactIds.contains(partnerId);
    final hasDetailRows = _hasContactDetailRows(fresh, partnerId);

    final msgsAsync = ref.watch(messagesProvider((conversationId: widget.conversationId, limit: 100)));
    final mediaCount = msgsAsync.when(
      data: (m) => profileMediaDocsCount(m),
      loading: () => 0,
      error: (_, _) => 0,
    );
    final mediaLabel = mediaCount == 0 ? 'Нет' : '$mediaCount';

    final showEncryptionRow = !_isGroup && !_isSaved;
    final e2eeOn = widget.conversation.e2eeEnabled == true && (widget.conversation.e2eeKeyEpoch ?? 0) > 0;
    final encryptionLabel = e2eeOn ? 'Вкл' : 'Выкл';

    final roleLabel = fresh?.role;
    final roleDisplay = roleLabel == null || roleLabel.isEmpty
        ? null
        : (_kRoleLabels[roleLabel] ?? roleLabel);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scheme.onSurface.withValues(alpha: 0.18),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    color: scheme.primary,
                    onPressed: _copyChatId,
                    tooltip: 'Скопировать ID чата',
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ChatAvatar(title: _displayTitle, radius: 44, avatarUrl: _displayAvatarUrl),
                      const SizedBox(height: 12),
                      Text(
                        _displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitleLine1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.60),
                        ),
                      ),
                      if (subtitleLine2 != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleLine2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (hasDetailRows && fresh != null && partnerId != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                  child: ExpansionTile(
                                    title: const Text(
                                      'Контакты и данные',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                    initiallyExpanded: false,
                                    children: [
                                      if (roleDisplay != null && fresh.role != null && fresh.role!.isNotEmpty && fresh.role != 'worker')
                                        _detailTile(
                                          context,
                                          Icons.verified_user_rounded,
                                          'Роль в системе',
                                          roleDisplay,
                                        ),
                                      if (isProfileFieldVisibleToOthers(fresh, 'email') &&
                                          fresh.email != null &&
                                          fresh.email!.trim().isNotEmpty)
                                        _detailTile(context, Icons.mail_rounded, 'Электронная почта', fresh.email!),
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
                                        _detailTile(context, Icons.cake_rounded, 'День рождения', fresh.dateOfBirth!),
                                      if (isProfileFieldVisibleToOthers(fresh, 'bio') &&
                                          fresh.bio != null &&
                                          fresh.bio!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(fresh.bio!, style: const TextStyle(fontSize: 14, height: 1.35)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (showAdd) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 96,
                                child: _ActionCard(
                                  icon: _addContactBusy ? Icons.hourglass_top_rounded : Icons.person_add_rounded,
                                  label: isContact ? 'В контактах' : 'В контакты',
                                  onTap: isContact || _addContactBusy ? () {} : () => _onAddContact(partnerId),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                      ] else if (showAdd) ...[
                        _ActionCard(
                          icon: _addContactBusy ? Icons.hourglass_top_rounded : Icons.person_add_rounded,
                          label: isContact ? 'В контактах' : 'Добавить в контакты',
                                                   onTap: isContact || _addContactBusy ? () {} : () => _onAddContact(partnerId),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_isGroup) ...[
                        _menuButton(
                          context,
                          icon: Icons.group_rounded,
                          title: 'Участники',
                          trailing: '${widget.conversation.participantIds.length}',
                          onTap: () => _toast('Участники: скоро'),
                        ),
                        if (_isGroupAdmin())
                          _menuButton(
                            context,
                            icon: Icons.edit_rounded,
                            title: 'Редактировать группу',
                            onTap: () => _toast('Редактирование группы: скоро'),
                          ),
                        const SizedBox(height: 8),
                      ],
                      _menuButton(
                        context,
                        icon: Icons.perm_media_rounded,
                        title: 'Медиа, ссылки и файлы',
                        trailing: mediaLabel,
                        onTap: () => _toast('Медиа: скоро'),
                      ),
                      _menuButton(
                        context,
                        icon: Icons.star_rounded,
                        title: 'Избранное',
                        trailing: 'Нет',
                        onTap: () => _toast('Избранное: скоро'),
                      ),
                      _menuButton(
                        context,
                        icon: Icons.forum_rounded,
                        title: 'Обсуждения',
                        trailing: 'Нет',
                        onTap: () => _toast('Обсуждения: скоро'),
                      ),
                      const SizedBox(height: 6),
                      _menuButton(
                        context,
                        icon: Icons.notifications_rounded,
                        title: 'Уведомления',
                        onTap: () => _toast('Уведомления: скоро'),
                      ),
                      _menuButton(
                        context,
                        icon: Icons.palette_rounded,
                        title: 'Тема чата',
                        onTap: () => _toast('Тема чата: скоро'),
                      ),
                      const SizedBox(height: 6),
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
                          subtitle: e2eeOn
                              ? 'Сообщения защищены сквозным шифрованием.'
                              : 'Сквозное шифрование выключено.',
                          trailing: encryptionLabel,
                          onTap: () => _toast('Шифрование: скоро'),
                        ),
                      if (!_isSaved && !_isGroup && partnerId != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Нет общих групп',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _menuButton(
                          context,
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Создать группу с ${fresh?.name ?? _displayTitle}',
                          onTap: () => _toast('Скоро'),
                        ),
                      ],
                      if (_isGroup) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _toast('Покинуть группу: скоро'),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Покинуть группу'),
                        ),
                      ],
                      const SizedBox(height: 8),
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

  Widget _detailTile(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary.withValues(alpha: 0.85)),
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
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.10 : 0.32)),
            ),
            child: Row(
              children: [
                Icon(icon, color: scheme.onSurface.withValues(alpha: 0.80)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.10 : 0.32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: scheme.onSurface.withValues(alpha: 0.80)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
