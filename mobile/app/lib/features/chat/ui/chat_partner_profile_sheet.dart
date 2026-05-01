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
import '../data/secret_chat_create.dart';
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
import 'conversation_games_screen.dart';
import 'e2ee_fingerprint_badge.dart';
import 'chat_conversation_notifications_screen.dart';
import 'chat_conversation_theme_screen.dart';
import 'conversation_encryption_screen.dart';
import 'conversation_disappearing_screen.dart';
import '../data/disappearing_messages_label.dart';
import 'secret_chat_compose_screen.dart';
import 'conversation_media_links_files_screen.dart';
import 'conversation_starred_screen.dart';
import 'chat_shell_backdrop.dart';
import 'chat_video_call_screen.dart';
import 'user_avatar_fullscreen_viewer.dart';
import '../../../l10n/app_localizations.dart';

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

Conversation? _findConversationById(
  List<ConversationWithId>? conversations,
  String conversationId,
) {
  if (conversations == null) return null;
  for (final conversation in conversations) {
    if (conversation.id == conversationId) return conversation.data;
  }
  return null;
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

  String _displayTitleFor(AppLocalizations l10n) {
    if (_isGroup) {
      return widget.conversation.name ??
          l10n.partner_profile_title_fallback_group;
    }
    if (_isSaved) {
      return widget.conversation.name ??
          l10n.partner_profile_title_fallback_saved;
    }
    final pid = _dmPartnerId;
    if (pid != null) {
      final fromConv = widget.conversation.participantInfo?[pid]?.name;
      return widget.partnerProfile?.name ??
          fromConv ??
          l10n.partner_profile_title_fallback_chat;
    }
    return l10n.partner_profile_title_fallback_chat;
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
  (String, String?) _profileHeaderSubtitles(
    AppLocalizations l10n,
    String statusForDm,
  ) {
    if (_isGroup) {
      final d = widget.conversation.description?.trim();
      if (d != null && d.isNotEmpty) return (d, null);
      return (
        l10n.partner_profile_subtitle_group_member_count(
          widget.conversation.participantIds.length,
        ),
        null,
      );
    }
    if (_isSaved) {
      return (l10n.partner_profile_subtitle_saved_messages, null);
    }
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
    final l10n = AppLocalizations.of(context)!;
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
      _toast(l10n.partner_profile_error_cannot_contact_user);
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;

    final selfNameTrimmed = self.name.trim();
    final selfName = selfNameTrimmed.isNotEmpty
        ? selfNameTrimmed
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
        : l10n.new_chat_fallback_user_display_name;
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
      _toast(l10n.partner_profile_error_open_chat(e));
    } finally {
      if (mounted) setState(() => _chatActionBusy = false);
    }
  }

  Future<void> _openSecretChatFromActions({
    required String partnerId,
    required String displayTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final self = widget.selfProfile;
    final partner = widget.partnerProfile;
    if (self == null || partnerId.trim().isEmpty) {
      _toast(l10n.partner_profile_error_open_chat('missing self/partner'));
      return;
    }
    final secretId = buildSecretDirectConversationId(
      widget.currentUserId,
      partnerId,
    );
    final existing = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(secretId)
        .get();
    if (!mounted) return;
    final alreadyExists =
        existing.exists &&
        ((existing.data()?['secretChat'] as Map?)?['enabled'] == true);
    if (alreadyExists) {
      _toast(l10n.secret_chat_already_exists);
      return;
    }
    final peer =
        partner ??
        UserProfile(
          id: partnerId.trim(),
          name: displayTitle.trim().isNotEmpty
              ? displayTitle.trim()
              : l10n.new_chat_fallback_user_display_name,
        );
    context.push(
      '/chats/new/secret',
      extra: SecretChatComposeArgs(me: self, peer: peer),
    );
  }

  Future<void> _openCallFromActions({
    required String partnerId,
    required String displayTitle,
    required bool isVideo,
  }) async {
    if (_callScreenOpening) return;
    final l10n = AppLocalizations.of(context)!;
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
            : l10n.partner_profile_error_cannot_contact_user,
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
        : l10n.partner_profile_call_peer_fallback;
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
    final l10n = AppLocalizations.of(context)!;
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
      l10n.partner_profile_share_contact_header,
      displayTitle,
      if (username.isNotEmpty)
        username.startsWith('@') ? username : '@$username',
      if (phone.isNotEmpty) formatPhoneNumberForDisplay(phone),
      if (avatarUrl.isNotEmpty)
        l10n.partner_profile_share_avatar_line(avatarUrl),
      l10n.partner_profile_share_profile_line(profileUrl),
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: lines.join('\n'),
          subject: l10n.partner_profile_share_contact_subject(displayTitle),
          files: sharedFiles,
          sharePositionOrigin: shareRect,
        ),
      );
      if (!mounted) return;
      _toast(l10n.partner_profile_contact_sent);
    } catch (e) {
      if (!mounted) return;
      final fallback = lines.join('\n');
      await Clipboard.setData(ClipboardData(text: fallback));
      if (!mounted) return;
      _toast(l10n.partner_profile_share_failed_copied);
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
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(chatSettingsRepositoryProvider);
    if (repo == null) return;
    final convId = widget.conversationId.trim();
    if (convId.isEmpty) {
      _toast(l10n.partner_profile_chat_not_created);
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
      _toast(
        muted
            ? l10n.partner_profile_notifications_muted
            : l10n.partner_profile_notifications_unmuted,
      );
    } catch (e) {
      if (!mounted) return;
      _toast(l10n.partner_profile_notifications_change_failed);
    } finally {
      if (mounted) setState(() => _muteToggleBusy = false);
    }
  }

  Future<void> _onAddContact(String partnerId) async {
    if (!mounted) return;
    final url =
        ((widget.partnerProfile?.avatarThumb ??
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
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(userContactsRepositoryProvider);
    if (repo == null) return;
    setState(() => _addContactBusy = true);
    try {
      await repo.removeContactId(widget.currentUserId, partnerId);
      if (mounted) _toast(l10n.partner_profile_removed_from_contacts);
    } catch (e) {
      if (mounted) _toast(l10n.partner_profile_remove_contact_failed);
    } finally {
      if (mounted) setState(() => _addContactBusy = false);
    }
  }

  Future<void> _copyChatId() async {
    await Clipboard.setData(ClipboardData(text: widget.conversationId));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _toast(l10n.profile_chat_id_copied_toast);
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
    final l10n = AppLocalizations.of(context)!;
    if (currentlyBlocked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.blacklist_unblock_confirm_title),
          content: Text(l10n.blacklist_unblock_confirm_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.blacklist_action_unblock),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .set(<String, Object?>{
              'blockedUserIds': FieldValue.arrayRemove([partnerId]),
            }, SetOptions(merge: true));
        if (mounted) _toast(l10n.blacklist_unblock_success);
      } catch (e) {
        if (mounted) _toast(l10n.blacklist_unblock_error(e));
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.partner_profile_block_confirm_title),
        content: Text(l10n.partner_profile_block_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.partner_profile_block_action),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .set(<String, Object?>{
            'blockedUserIds': FieldValue.arrayUnion([partnerId]),
          }, SetOptions(merge: true));
      if (mounted) _toast(l10n.partner_profile_block_success);
    } catch (e) {
      if (mounted) _toast(l10n.partner_profile_block_error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final liveConversationAsync = ref.watch(
      conversationsProvider((
        key: conversationIdsCacheKey(<String>[widget.conversationId]),
      )),
    );
    final conversation =
        _findConversationById(
          liveConversationAsync.asData?.value,
          widget.conversationId,
        ) ??
        widget.conversation;
    final partnerId = _dmPartnerId;
    final fresh = widget.partnerProfile;
    final statusDm = partnerPresenceLine(fresh);
    final (subtitleLine1, subtitleLine2) = _profileHeaderSubtitles(
      l10n,
      statusDm,
    );

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
    final baseTitle = _displayTitleFor(l10n);
    final displayTitle = !_isGroup && !_isSaved && partnerId != null
        ? resolveContactDisplayName(
            contactProfiles: contactProfiles,
            contactUserId: partnerId,
            fallbackName: baseTitle,
          )
        : baseTitle;
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
    final mediaLabel = mediaCount == 0 ? l10n.common_none : '$mediaCount';
    final starredIdsAsync = ref.watch(
      starredMessageIdsInConversationProvider((
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
      )),
    );
    final starredCount = starredIdsAsync.value?.length ?? 0;
    final starredLabel = starredCount == 0 ? l10n.common_none : '$starredCount';

    final threadsCount = msgsAsync.when(
      data: (m) =>
          m.where((x) => !x.isDeleted && (x.threadCount ?? 0) > 0).length,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final threadsLabel = threadsCount == 0 ? l10n.common_none : '$threadsCount';

    final showEncryptionRow = !_isGroup && !_isSaved;
    final showDisappearingMessagesRow =
        !_isSaved && widget.conversation.secretChat?.enabled != true;
    final disappearingTrailing = formatDisappearingTtlSummaryForLocale(
      l10n,
      widget.conversation.disappearingMessageTtlSec,
    );
    final e2eeOn =
        conversation.e2eeEnabled == true &&
        (conversation.e2eeKeyEpoch ?? 0) > 0;
    final encryptionLabel = e2eeOn
        ? l10n.conversation_profile_e2ee_on
        : l10n.conversation_profile_e2ee_off;

    final roleLabel = fresh?.role;
    final roleDisplay = roleLabel == null || roleLabel.isEmpty
        ? null
        : (roleLabel == 'admin'
              ? l10n.group_member_role_admin
              : roleLabel == 'worker'
              ? l10n.group_member_role_worker
              : roleLabel);

    const hiPrimary = Color(0xFFF2F4FA);
    const hiMuted = Color(0xFFB4BDD1);
    const hiFaint = Color(0xFF8B95AD);

    final encryptionSubtitle = e2eeOn
        ? l10n.conversation_profile_e2ee_subtitle_on
        : l10n.conversation_profile_e2ee_subtitle_off;

    final myBlocked = myBlockedAsync.value ?? const <String>[];
    final partnerIsBlocked = partnerId != null && myBlocked.contains(partnerId);
    final selfPr = widget.selfProfile;
    final canDirectInteract =
        selfPr != null &&
        target != null &&
        canStartDirectChat(
          selfPr,
          target,
          partnerBlockedIdsSupplement: theirBlockedAsync?.asData?.value,
          partnerUserDocDenied: theirBlockedAsync?.hasError == true,
        );
    final secretIds =
        ref
            .watch(userSecretChatIndexProvider(widget.currentUserId))
            .asData
            ?.value
            ?.conversationIds ??
        const <String>[];
    final hasSecretWithPartner = (!_isGroup && !_isSaved && partnerId != null)
        ? secretIds.contains(
            buildSecretDirectConversationId(widget.currentUserId, partnerId),
          )
        : false;

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
                tooltip: widget.fullScreen
                    ? l10n.partner_profile_tooltip_back
                    : l10n.partner_profile_tooltip_close,
              ),
              const Spacer(),
              if (!_isGroup && !_isSaved && partnerId != null)
                TextButton(
                  onPressed: () => _onAddContact(partnerId),
                  child: Text(
                    l10n.partner_profile_edit_contact_short,
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
                  tooltip: l10n.partner_profile_tooltip_copy_chat_id,
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
                          label: l10n.partner_profile_action_chats,
                          busy: _chatActionBusy,
                          onTap: _chatActionBusy || !canDirectInteract
                              ? null
                              : () => _openChatFromActions(
                                  partnerId: partnerId,
                                  displayTitle: displayTitle,
                                ),
                        ),
                      _ProfileQuickAction(
                        icon: Icons.lock_rounded,
                        label: hasSecretWithPartner
                            ? '${l10n.secret_chat_title} · ${l10n.secret_chat_exists_badge}'
                            : l10n.secret_chat_title,
                        busy: _chatActionBusy,
                        onTap:
                            _chatActionBusy ||
                                !canDirectInteract ||
                                hasSecretWithPartner
                            ? null
                            : () => unawaited(
                                _openSecretChatFromActions(
                                  partnerId: partnerId,
                                  displayTitle: displayTitle,
                                ),
                              ),
                      ),
                      _ProfileQuickAction(
                        icon: Icons.call_rounded,
                        label: l10n.partner_profile_action_voice_call,
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
                        label: l10n.partner_profile_action_video,
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
                        label: l10n.partner_profile_action_share,
                        onTap: () => _shareProfileFromActions(
                          partnerId: partnerId,
                          displayTitle: displayTitle,
                        ),
                      ),
                      _ProfileQuickAction(
                        icon: muted
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_rounded,
                        label: l10n.partner_profile_action_notifications,
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
                  addToContactsLabel: l10n.partner_profile_add_to_contacts,
                  removeFromContactsLabel:
                      l10n.partner_profile_remove_from_contacts,
                  onPressed: _addContactBusy
                      ? null
                      : () => _onAddContact(partnerId),
                ),
              ],
              const SizedBox(height: 18),
              if (hasDetailRows && fresh != null && partnerId != null)
                _buildContactDataExpansion(
                  context,
                  l10n: l10n,
                  fresh: fresh,
                  roleDisplay: roleDisplay,
                ),
              if (_isGroup) ...[
                _menuButton(
                  context,
                  icon: Icons.group_rounded,
                  title: l10n.partner_profile_menu_members,
                  trailing: '${widget.conversation.participantIds.length}',
                  onTap: () => _toast(l10n.common_soon),
                ),
                if (_isGroupAdmin())
                  _menuButton(
                    context,
                    icon: Icons.edit_rounded,
                    title: l10n.partner_profile_menu_edit_group,
                    onTap: () {
                      context.push(
                        '/chats/edit/group/${widget.conversationId}',
                      );
                    },
                  ),
                _sectionDivider(),
              ],
              _menuButton(
                context,
                icon: Icons.perm_media_rounded,
                title: l10n.partner_profile_menu_media_links_files,
                trailing: mediaLabel,
                onTap: _openMediaLinksFiles,
              ),
              _menuButton(
                context,
                icon: Icons.star_rounded,
                title: l10n.partner_profile_menu_starred,
                trailing: starredLabel,
                onTap: _openStarredMessages,
              ),
              _menuButton(
                context,
                icon: Icons.forum_rounded,
                title: l10n.partner_profile_menu_threads,
                trailing: threadsLabel,
                onTap: () {
                  if (!widget.fullScreen) {
                    Navigator.of(context).pop();
                  }
                  context.push('/chats/${widget.conversationId}/threads');
                },
              ),
              _menuButton(
                context,
                icon: Icons.sports_esports_rounded,
                title: l10n.partner_profile_menu_games,
                onTap: () {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  if (!widget.fullScreen) {
                    Navigator.of(context).pop();
                  }
                  unawaited(
                    rootNav.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ConversationGamesScreen(
                          conversationId: widget.conversationId,
                          isGroup: _isGroup,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!_isGroup && !_isSaved && partnerId != null)
                _menuButton(
                  context,
                  icon: partnerIsBlocked
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  title: partnerIsBlocked
                      ? l10n.partner_profile_menu_unblock
                      : l10n.partner_profile_menu_block,
                  onTap: () => unawaited(
                    _toggleBlockPartner(partnerId, partnerIsBlocked),
                  ),
                ),
              _sectionDivider(),
              _menuButton(
                context,
                icon: Icons.notifications_rounded,
                title: l10n.partner_profile_menu_notifications,
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
                title: l10n.partner_profile_menu_chat_theme,
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
                  title: l10n.disappearing_messages_title,
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
              if (!_isGroup &&
                  !_isSaved &&
                  partnerId != null &&
                  widget.conversation.secretChat?.enabled != true &&
                  !hasSecretWithPartner)
                _menuButton(
                  context,
                  icon: Icons.lock_rounded,
                  title: l10n.secret_chat_title,
                  subtitle: l10n.secret_chat_settings_subtitle,
                  onTap: _chatActionBusy
                      ? null
                      : () => unawaited(
                          _openSecretChatFromActions(
                            partnerId: partnerId,
                            displayTitle: displayTitle,
                          ),
                        ),
                ),
              if (!_isGroup &&
                  !_isSaved &&
                  partnerId != null &&
                  widget.conversation.secretChat?.enabled != true &&
                  hasSecretWithPartner)
                _menuButton(
                  context,
                  icon: Icons.lock_rounded,
                  title: l10n.secret_chat_title,
                  subtitle: l10n.secret_chat_already_exists,
                  trailing: l10n.secret_chat_exists_badge,
                  onTap: null,
                ),
              if (widget.conversation.secretChat?.enabled == true)
                _menuButton(
                  context,
                  icon: Icons.lock_clock_rounded,
                  title: l10n.secret_chat_settings_title,
                  subtitle: l10n.secret_chat_settings_subtitle,
                  onTap: () {
                    if (!widget.fullScreen) {
                      Navigator.of(context).pop();
                    }
                    context.push(
                      '/chats/${widget.conversationId}/secret-settings',
                    );
                  },
                ),
              _menuButton(
                context,
                icon: Icons.shield_rounded,
                title: l10n.partner_profile_menu_advanced_privacy,
                trailing: l10n.partner_profile_privacy_trailing_default,
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
                  title: l10n.partner_profile_menu_encryption,
                  subtitle: encryptionSubtitle,
                  trailing: encryptionLabel,
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      CupertinoPageRoute<void>(
                        builder: (_) => ConversationEncryptionScreen(
                          conversationId: widget.conversationId,
                          currentUserId: widget.currentUserId,
                          conversation: conversation,
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
                    userLabel: fresh?.name ?? displayTitle,
                  ),
                ),
              ],
              if (!_isSaved && !_isGroup && partnerId != null) ...[
                const SizedBox(height: 18),
                Text(
                  l10n.partner_profile_no_common_groups,
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
                  title: l10n.partner_profile_create_group_with(
                    fresh?.name ?? displayTitle,
                  ),
                  onTap: () => _toast(l10n.common_soon),
                ),
              ],
              if (_isGroup) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: hiPrimary.withValues(alpha: 0.88),
                  ),
                  onPressed: () => _toast(l10n.common_soon),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.partner_profile_leave_group),
                ),
              ],
              if (partnerId != null && isContact && !_isGroup && !_isSaved) ...[
                const SizedBox(height: 18),
                _ContactPill(
                  isContact: true,
                  busy: _addContactBusy,
                  addToContactsLabel: l10n.partner_profile_add_to_contacts,
                  removeFromContactsLabel:
                      l10n.partner_profile_remove_from_contacts,
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
    required AppLocalizations l10n,
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
            title: Text(
              l10n.partner_profile_contacts_and_data,
              style: const TextStyle(
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
                  l10n.partner_profile_field_system_role,
                  roleDisplay,
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'email') &&
                  fresh.email != null &&
                  fresh.email!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.mail_rounded,
                  l10n.partner_profile_field_email,
                  fresh.email!,
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'phone') &&
                  fresh.phone != null &&
                  fresh.phone!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.smartphone_rounded,
                  l10n.partner_profile_field_phone,
                  formatPhoneNumberForDisplay(fresh.phone!),
                ),
              if (isProfileFieldVisibleToOthers(fresh, 'dateOfBirth') &&
                  fresh.dateOfBirth != null &&
                  fresh.dateOfBirth!.trim().isNotEmpty)
                _detailTile(
                  context,
                  Icons.cake_rounded,
                  l10n.partner_profile_field_birthday,
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
                          l10n.partner_profile_field_bio,
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
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
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
                  color: Colors.white.withValues(alpha: enabled ? 0.86 : 0.42),
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
                              color: Colors.white.withValues(
                                alpha: enabled ? 0.52 : 0.30,
                              ),
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
                      color: Colors.white.withValues(
                        alpha: enabled ? 0.45 : 0.28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: enabled ? 0.38 : 0.22),
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
    required this.addToContactsLabel,
    required this.removeFromContactsLabel,
    this.onPressed,
  });

  final bool isContact;
  final bool busy;
  final String addToContactsLabel;
  final String removeFromContactsLabel;
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
          isContact ? removeFromContactsLabel : addToContactsLabel,
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
