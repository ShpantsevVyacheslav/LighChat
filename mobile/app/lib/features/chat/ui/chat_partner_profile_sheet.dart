import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lighchat_models/lighchat_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/partner_presence_line.dart';
import '../data/phone_display.dart';
import '../data/profile_attachment_stats.dart';
import '../data/profile_field_visibility.dart';
import '../data/saved_messages_chat.dart';
import '../data/user_chat_policy.dart';
import '../data/user_block_utils.dart';
import '../data/contact_display_name.dart';
import '../data/e2ee_auto_enable_helper.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_block_providers.dart';
import '../data/user_profile.dart';
import 'chat_audio_call_screen.dart';
import 'chat_avatar.dart';
import 'e2ee_fingerprint_badge.dart';
import 'chat_conversation_notifications_screen.dart';
import 'chat_conversation_theme_screen.dart';
import 'conversation_encryption_screen.dart';
import 'conversation_disappearing_screen.dart';
import '../data/disappearing_messages_label.dart';
import 'conversation_media_links_files_screen.dart';
import 'conversation_starred_screen.dart';
import 'chat_shell_backdrop.dart';
import 'chat_video_call_screen.dart';
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
    this.showChatsAction = false,
  });

  final String conversationId;
  final Conversation conversation;
  final String currentUserId;
  final UserProfile? selfProfile;
  final UserProfile? partnerProfile;
  final void Function(String messageId)? onJumpToMessageId;
  final bool fullScreen;
  final bool showChatsAction;

  @override
  ConsumerState<ChatPartnerProfileSheet> createState() =>
      _ChatPartnerProfileSheetState();
}

class _ChatPartnerProfileSheetState
    extends ConsumerState<ChatPartnerProfileSheet> {
  bool _addContactBusy = false;
  bool _chatActionBusy = false;
  bool _callScreenOpening = false;
  bool _muteToggleBusy = false;

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
    List<String> contactIds, {
    List<String>? partnerBlockedSupplement,
    required bool partnerUserDocDenied,
  }) {
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
    return canStartDirectChat(
      self,
      target,
      partnerBlockedIdsSupplement: partnerBlockedSupplement,
      partnerUserDocDenied: partnerUserDocDenied,
    );
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

  Future<void> _openChatFromActions({
    required String partnerId,
    required String displayTitle,
  }) async {
    if (_chatActionBusy) return;
    final self = widget.selfProfile;
    final partner = widget.partnerProfile;
    final target = partner ?? _contactTarget(partnerId);
    final their = ref.read(userBlockedUserIdsProvider(partnerId));
    if (self == null ||
        target == null ||
        !canStartDirectChat(
          self,
          target,
          partnerBlockedIdsSupplement: their.asData?.value,
          partnerUserDocDenied: their.hasError,
        )) {
      _toast('С этим пользователем нельзя связаться.');
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;

    final selfNameTrimmed = self.name.trim();
    final selfName = selfNameTrimmed.isNotEmpty ? selfNameTrimmed : widget.currentUserId;
    final peerName =
        (partner?.name ??
                widget.conversation.participantInfo?[partnerId]?.name ??
                displayTitle)
            .trim()
            .isNotEmpty
        ? (partner?.name ??
                  widget.conversation.participantInfo?[partnerId]?.name ??
                  displayTitle)
              .trim()
        : 'Пользователь';
    final peerAvatar =
        partner?.avatar ??
        widget.conversation.participantInfo?[partnerId]?.avatar;
    final peerAvatarThumb =
        partner?.avatarThumb ??
        widget.conversation.participantInfo?[partnerId]?.avatarThumb;

    setState(() => _chatActionBusy = true);
    try {
      final id = await repo.createOrOpenDirectChat(
        currentUserId: widget.currentUserId,
        otherUserId: partnerId,
        currentUserInfo: (
          name: selfName,
          avatar: self.avatar,
          avatarThumb: self.avatarThumb,
        ),
        otherUserInfo: (
          name: peerName,
          avatar: peerAvatar,
          avatarThumb: peerAvatarThumb,
        ),
      );
      await tryAutoEnableE2eeForMobileDm(
        firestore: FirebaseFirestore.instance,
        conversationId: id,
        currentUserId: widget.currentUserId,
      );
      if (!mounted) return;
      context.push('/chats/$id');
    } catch (e) {
      if (!mounted) return;
      _toast('Не удалось открыть чат: $e');
    } finally {
      if (mounted) setState(() => _chatActionBusy = false);
    }
  }

  Future<void> _openCallFromActions({
    required String partnerId,
    required String displayTitle,
    required bool isVideo,
  }) async {
    if (_callScreenOpening) return;
    final self = widget.selfProfile;
    final partner = widget.partnerProfile;
    final target = partner ?? _contactTarget(partnerId);
    final their = ref.read(userBlockedUserIdsProvider(partnerId));
    if (self == null ||
        target == null ||
        !canStartDirectChat(
          self,
          target,
          partnerBlockedIdsSupplement: their.asData?.value,
          partnerUserDocDenied: their.hasError,
        )) {
      _toast(
        self != null && target != null
            ? directCallBlockedMessageRu(
                viewerId: self.id,
                viewerBlockedIds: self.blockedUserIds,
                partnerId: target.id,
                partnerBlockedIds: their.asData?.value ?? target.blockedUserIds,
                partnerUserDocDenied: their.hasError,
              )
            : 'С этим пользователем нельзя связаться.',
      );
      return;
    }

    final selfNameTrimmedCall = self.name.trim();
    final selfName = selfNameTrimmedCall.isNotEmpty
        ? selfNameTrimmedCall
        : widget.currentUserId;
    final peerName =
        (partner?.name ??
                widget.conversation.participantInfo?[partnerId]?.name ??
                displayTitle)
            .trim()
            .isNotEmpty
        ? (partner?.name ??
                  widget.conversation.participantInfo?[partnerId]?.name ??
                  displayTitle)
              .trim()
        : 'Собеседник';
    final peerAvatar =
        partner?.avatarThumb ??
        partner?.avatar ??
        widget.conversation.participantInfo?[partnerId]?.avatarThumb ??
        widget.conversation.participantInfo?[partnerId]?.avatar;

    if (mounted) {
      setState(() => _callScreenOpening = true);
    }
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => isVideo
              ? ChatVideoCallScreen(
                  currentUserId: widget.currentUserId,
                  currentUserName: selfName,
                  currentUserAvatarUrl: self.avatarThumb ?? self.avatar,
                  peerUserId: partnerId,
                  peerUserName: peerName,
                  peerAvatarUrl: peerAvatar,
                )
              : ChatAudioCallScreen(
                  currentUserId: widget.currentUserId,
                  currentUserName: selfName,
                  currentUserAvatarUrl: self.avatarThumb ?? self.avatar,
                  peerUserId: partnerId,
                  peerUserName: peerName,
                  peerAvatarUrl: peerAvatar,
                ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _callScreenOpening = false);
      }
    }
  }

  Future<void> _shareProfileFromActions({
    required String partnerId,
    required String displayTitle,
  }) async {
    final p = widget.partnerProfile;
    final username = (p?.username ?? '').trim();
    final phone = (p?.phone ?? '').trim();
    Rect? shareRect;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      final origin = ro.localToGlobal(Offset.zero);
      shareRect = origin & ro.size;
    }
    final avatarUrl = (p?.avatar ?? p?.avatarThumb ?? _displayAvatarUrl ?? '')
        .trim();
    final profileUrl =
        'https://lighchat.online/dashboard/contacts/${Uri.encodeComponent(partnerId)}';
    final sharedFiles = <XFile>[];
    final avatarFile = await _downloadAvatarForShare(
      avatarUrl: avatarUrl,
      partnerId: partnerId,
    );
    if (avatarFile != null) {
      sharedFiles.add(avatarFile);
    }
    final lines = <String>[
      'Контакт в LighChat',
      displayTitle,
      if (username.isNotEmpty)
        username.startsWith('@') ? username : '@$username',
      if (phone.isNotEmpty) formatPhoneNumberForDisplay(phone),
      if (avatarUrl.isNotEmpty) 'Аватар: $avatarUrl',
      'Профиль: $profileUrl',
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: lines.join('\n'),
          subject: 'Контакт LighChat: $displayTitle',
          files: sharedFiles,
          sharePositionOrigin: shareRect,
        ),
      );
      if (!mounted) return;
      _toast('Контакт отправлен');
    } catch (e) {
      if (!mounted) return;
      final fallback = lines.join('\n');
      await Clipboard.setData(ClipboardData(text: fallback));
      if (!mounted) return;
      _toast('Не удалось открыть шаринг. Текст контакта скопирован.');
    }
  }

  Future<XFile?> _downloadAvatarForShare({
    required String avatarUrl,
    required String partnerId,
  }) async {
    if (avatarUrl.isEmpty) return null;
    final uri = Uri.tryParse(avatarUrl);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 ||
          res.statusCode >= 300 ||
          res.bodyBytes.isEmpty) {
        return null;
      }
      final ext = _shareAvatarExt(
        contentType: res.headers['content-type'],
        path: uri.path,
      );
      final mimeType = _shareAvatarMimeType(
        contentType: res.headers['content-type'],
        ext: ext,
      );
      final dir = await getTemporaryDirectory();
      final safePartnerId = partnerId.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final file = File(
        '${dir.path}/lighchat_share_avatar_${safePartnerId}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return XFile(file.path, name: 'avatar.$ext', mimeType: mimeType);
    } catch (_) {
      return null;
    }
  }

  String _shareAvatarExt({required String? contentType, required String path}) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('png')) return 'png';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('gif')) return 'gif';
    if (ct.contains('heic')) return 'heic';
    if (ct.contains('heif')) return 'heif';
    if (ct.contains('jpeg') || ct.contains('jpg')) return 'jpg';
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    if (p.endsWith('.gif')) return 'gif';
    if (p.endsWith('.heic')) return 'heic';
    if (p.endsWith('.heif')) return 'heif';
    if (p.endsWith('.jpeg') || p.endsWith('.jpg')) return 'jpg';
    return 'jpg';
  }

  String _shareAvatarMimeType({
    required String? contentType,
    required String ext,
  }) {
    final ct = (contentType ?? '').trim();
    if (ct.startsWith('image/')) return ct;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _setConversationMuted(bool muted) async {
    if (_muteToggleBusy) return;
    final repo = ref.read(chatSettingsRepositoryProvider);
    if (repo == null) return;
    final convId = widget.conversationId.trim();
    if (convId.isEmpty) {
      _toast('Чат ещё не создан');
      return;
    }
    setState(() => _muteToggleBusy = true);
    try {
      await repo.patchChatConversationPrefs(
        userId: widget.currentUserId,
        conversationId: convId,
        patch: <String, Object?>{'notificationsMuted': muted},
      );
      if (!mounted) return;
      _toast(muted ? 'Уведомления отключены' : 'Уведомления включены');
    } catch (e) {
      if (!mounted) return;
      _toast('Не удалось изменить уведомления');
    } finally {
      if (mounted) setState(() => _muteToggleBusy = false);
    }
  }

  Future<void> _onAddContact(String partnerId) async {
    if (!mounted) return;
    final url = ((widget.partnerProfile?.avatarThumb ??
                widget.partnerProfile?.avatar) ??
            '')
        .trim();
    if (url.isNotEmpty) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {}
    }
    if (!mounted) return;
    context.push('/contacts/user/${Uri.encodeComponent(partnerId)}/edit');
  }

  void _onLeadingAppBarBack() {
    if (widget.fullScreen) {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        context.go('/contacts');
      }
    } else {
      Navigator.of(context).pop();
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

  Future<void> _toggleBlockPartner(
    String partnerId,
    bool currentlyBlocked,
  ) async {
    if (currentlyBlocked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Разблокировать пользователя?'),
          content: const Text(
            'Пользователь снова сможет писать вам и видеть ваш профиль в поиске (в пределах правил приватности).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Разблокировать'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .set(
          <String, Object?>{
            'blockedUserIds': FieldValue.arrayRemove([partnerId]),
          },
          SetOptions(merge: true),
        );
        if (mounted) _toast('Пользователь разблокирован');
      } catch (e) {
        if (mounted) _toast('Не удалось разблокировать: $e');
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Заблокировать пользователя?'),
        content: const Text(
          'Он не увидит чат с вами, не сможет найти вас в поиске и добавить в контакты. '
          'У него вы пропадёте из контактов. Вы сохраните переписку, но не сможете писать ему, '
          'пока он в списке заблокированных.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .set(
        <String, Object?>{
          'blockedUserIds': FieldValue.arrayUnion([partnerId]),
        },
        SetOptions(merge: true),
      );
      if (mounted) _toast('Пользователь заблокирован');
    } catch (e) {
      if (mounted) _toast('Не удалось заблокировать: $e');
    }
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
    final contactProfiles =
        contactsAsync.value?.contactProfiles ??
        const <String, ContactLocalProfile>{};
    final target = _contactTarget(partnerId);
    final myBlockedAsync = ref.watch(
      userBlockedUserIdsProvider(widget.currentUserId),
    );
    final theirBlockedAsync = partnerId != null
        ? ref.watch(userBlockedUserIdsProvider(partnerId))
        : null;
    final showAdd =
        partnerId != null &&
        _canShowAddToContacts(
          target,
          partnerId,
          contactIds,
          partnerBlockedSupplement: theirBlockedAsync?.asData?.value,
          partnerUserDocDenied: theirBlockedAsync?.hasError == true,
        );
    final isContact = partnerId != null && contactIds.contains(partnerId);
    final displayTitle = !_isGroup && !_isSaved && partnerId != null
        ? resolveContactDisplayName(
            contactProfiles: contactProfiles,
            contactUserId: partnerId,
            fallbackName: _displayTitle,
          )
        : _displayTitle;
    final hasDetailRows = _hasContactDetailRows(fresh, partnerId);
    final settingsRepo = ref.watch(chatSettingsRepositoryProvider);

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
    final showDisappearingMessagesRow = !_isSaved;
    final disappearingTrailing =
        formatDisappearingTtlSummary(widget.conversation.disappearingMessageTtlSec);
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

    final myBlocked = myBlockedAsync.value ?? const <String>[];
    final partnerIsBlocked =
        partnerId != null && myBlocked.contains(partnerId);
    final selfPr = widget.selfProfile;
    final canDirectInteract = selfPr != null &&
        target != null &&
        canStartDirectChat(
          selfPr,
          target,
          partnerBlockedIdsSupplement: theirBlockedAsync?.asData?.value,
          partnerUserDocDenied: theirBlockedAsync?.hasError == true,
        );

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
                onPressed: _onLeadingAppBarBack,
                tooltip: widget.fullScreen ? 'Назад' : 'Закрыть',
              ),
              const Spacer(),
              if (!_isGroup && !_isSaved && partnerId != null)
                TextButton(
                  onPressed: () => _onAddContact(partnerId),
                  child: Text(
                    'Изм.',
                    style: TextStyle(
                      color: hiPrimary.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                )
              else
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
                    title: displayTitle,
                    radius: 54,
                    avatarUrl: _displayAvatarUrl,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayTitle,
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
              if (!_isGroup && !_isSaved && partnerId != null) ...[
                const SizedBox(height: 18),
                StreamBuilder<Map<String, dynamic>>(
                  stream: settingsRepo?.watchChatConversationPrefs(
                    userId: widget.currentUserId,
                    conversationId: widget.conversationId,
                  ),
                  builder: (context, snap) {
                    final prefs = snap.data ?? const <String, dynamic>{};
                    final muted = prefs['notificationsMuted'] == true;
                    final actions = <_ProfileQuickAction>[
                      if (widget.showChatsAction)
                        _ProfileQuickAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Чаты',
                          busy: _chatActionBusy,
                          onTap: _chatActionBusy || !canDirectInteract
                              ? null
                              : () => _openChatFromActions(
                                  partnerId: partnerId,
                                  displayTitle: displayTitle,
                                ),
                        ),
                      _ProfileQuickAction(
                        icon: Icons.call_rounded,
                        label: 'Звонок',
                        busy: _callScreenOpening,
                        onTap: _callScreenOpening || !canDirectInteract
                            ? null
                            : () => _openCallFromActions(
                                partnerId: partnerId,
                                displayTitle: displayTitle,
                                isVideo: false,
                              ),
                      ),
                      _ProfileQuickAction(
                        icon: Icons.videocam_rounded,
                        label: 'Видео',
                        busy: _callScreenOpening,
                        onTap: _callScreenOpening || !canDirectInteract
                            ? null
                            : () => _openCallFromActions(
                                partnerId: partnerId,
                                displayTitle: displayTitle,
                                isVideo: true,
                              ),
                      ),
                      _ProfileQuickAction(
                        icon: Icons.share_outlined,
                        label: 'Поделиться',
                        onTap: () => _shareProfileFromActions(
                          partnerId: partnerId,
                          displayTitle: displayTitle,
                        ),
                      ),
                      _ProfileQuickAction(
                        icon: muted
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_rounded,
                        label: 'Звук',
                        busy: _muteToggleBusy,
                        onTap: _muteToggleBusy
                            ? null
                            : () => _setConversationMuted(!muted),
                      ),
                    ];
                    return _ProfileQuickActions(actions: actions);
                  },
                ),
              ],
              if (partnerId != null &&
                  showAdd &&
                  !isContact &&
                  !_isGroup &&
                  !_isSaved) ...[
                const SizedBox(height: 18),
                _ContactPill(
                  isContact: false,
                  busy: _addContactBusy,
                  onPressed: _addContactBusy
                      ? null
                      : () => _onAddContact(partnerId),
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
                  context.push('/chats/${widget.conversationId}/threads');
                },
              ),
              if (!_isGroup && !_isSaved && partnerId != null)
                _menuButton(
                  context,
                  icon: partnerIsBlocked
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  title:
                      partnerIsBlocked ? 'Разблокировать' : 'Заблокировать',
                  onTap: () => unawaited(
                    _toggleBlockPartner(partnerId, partnerIsBlocked),
                  ),
                ),
              _sectionDivider(),
              _menuButton(
                context,
                icon: Icons.notifications_rounded,
                title: 'Уведомления',
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    CupertinoPageRoute(
                      builder: (_) => ChatConversationNotificationsScreen(
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
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    CupertinoPageRoute(
                      builder: (_) => ChatConversationThemeScreen(
                        currentUserId: widget.currentUserId,
                        conversationId: widget.conversationId,
                      ),
                    ),
                  );
                },
              ),
              if (showDisappearingMessagesRow)
                _menuButton(
                  context,
                  icon: Icons.timer_rounded,
                  title: 'Исчезающие сообщения',
                  trailing: disappearingTrailing,
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      CupertinoPageRoute<void>(
                        builder: (_) => ConversationDisappearingScreen(
                          conversationId: widget.conversationId,
                          currentUserId: widget.currentUserId,
                          initialConversation: widget.conversation,
                        ),
                      ),
                    );
                  },
                ),
              _menuButton(
                context,
                icon: Icons.shield_rounded,
                title: 'Расширенная приватность чата',
                trailing: 'По умолчанию',
                onTap: () {
                  if (!widget.fullScreen) {
                    Navigator.of(context).pop();
                  }
                  context.push(
                    '/chats/${widget.conversationId}/privacy-advanced',
                  );
                },
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
                  title: 'Создать группу с ${fresh?.name ?? _displayTitle}',
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
              if (partnerId != null && isContact && !_isGroup && !_isSaved) ...[
                const SizedBox(height: 18),
                _ContactPill(
                  isContact: true,
                  busy: _addContactBusy,
                  onPressed: _addContactBusy
                      ? null
                      : () => _onRemoveContact(partnerId),
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
                    : Column(children: [Expanded(child: scroll)]),
              ),
            ),
          ],
        ),
      ],
    );

    final scheme = Theme.of(context).colorScheme;
    final baseBg = scheme.brightness == Brightness.dark
        ? const Color(0xFF04070C)
        : const Color(0xFFF3F6FC);

    return Scaffold(
      backgroundColor: baseBg,
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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
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
          Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.88)),
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
    final destructive = isContact;
    final fgBase = destructive
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFF2F4FA);
    final fg = fgBase.withValues(alpha: enabled ? 0.95 : 0.42);
    final borderColor = destructive
        ? const Color(0xFFFF6B6B).withValues(alpha: enabled ? 0.70 : 0.30)
        : Colors.white.withValues(alpha: 0.38);
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
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _ProfileQuickAction {
  const _ProfileQuickAction({
    required this.icon,
    required this.label,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({required this.actions});

  final List<_ProfileQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _ProfileQuickActionButton(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ProfileQuickActionButton extends StatelessWidget {
  const _ProfileQuickActionButton({required this.action});

  final _ProfileQuickAction action;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onTap != null;
    final fg = const Color(0xFFF2F4FA).withValues(alpha: enabled ? 0.92 : 0.45);
    final bg = Colors.white.withValues(alpha: 0.08);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (action.busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(action.icon, size: 22, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
