import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/contact_display_name.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'chat_shell_backdrop.dart';
import '../../../l10n/app_localizations.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  static const double _hPad = 18.0;
  static const double _titleFontSize = 22;
  static const double _topActionButtonSize = 43;
  static const double _topActionIconSize = 20;
  static const double _avatarSize = 52;
  static const double _avatarRadius = 24;
  static const double _avatarOnlineSize = 14;
  static const double _contactRowHeight = 76;
  static const double _contactNameFontSize = 16;
  static const double _contactStatusFontSize = 13;

  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ChatShellBackdrop(),
            SafeArea(
              child: userAsync.when(
                data: (u) {
                  if (u == null) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.go('/auth'),
                    );
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snap.hasData || snap.data?.data() == null) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(AppLocalizations.of(context)!.group_not_found),
                        );
                      }

                      final conv = Conversation.fromJson(
                        snap.data!.data() ?? const <String, dynamic>{},
                      );

                      if (!conv.participantIds.contains(u.uid)) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(AppLocalizations.of(context)!.group_not_member),
                        );
                      }

                      final l10n = AppLocalizations.of(context)!;
                      final isCreator = conv.createdByUserId == u.uid;
                      final isAdmin =
                          isCreator || conv.adminIds.contains(u.uid);

                      return _buildContent(
                        context: context,
                        conv: conv,
                        currentUserId: u.uid,
                        isCreator: isCreator,
                        isAdmin: isAdmin,
                        l10n: l10n,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)!.generic_error(err.toString())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required Conversation conv,
    required String currentUserId,
    required bool isCreator,
    required bool isAdmin,
    required AppLocalizations l10n,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;

    final contactProfiles = ref
            .watch(userContactsIndexProvider(currentUserId))
            .asData
            ?.value
            .contactProfiles ??
        const <String, ContactLocalProfile>{};

    final profileRepo = ref.watch(userProfilesRepositoryProvider);
    final profilesStream =
        profileRepo?.watchUsersByIds(conv.participantIds.toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          context: context,
          conv: conv,
          isAdmin: isAdmin,
          l10n: l10n,
          baseFg: baseFg,
          dark: dark,
        ),
        Expanded(
          child: StreamBuilder<Map<String, UserProfile>>(
            stream: profilesStream,
            builder: (context, snap) {
              final byId = snap.data ?? const <String, UserProfile>{};
              return ListView.builder(
                padding: const EdgeInsets.only(top: 6, bottom: 16),
                itemCount: conv.participantIds.length + (_error != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_error != null && index == conv.participantIds.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }
                  final participantId = conv.participantIds[index];
                  final isCurrentUser = participantId == currentUserId;
                  final isMemberCreator =
                      conv.createdByUserId == participantId;
                  final isParticipantAdmin =
                      conv.adminIds.contains(participantId);
                  final isElevatedAdmin = isMemberCreator || isParticipantAdmin;
                  final participantInfo = conv.participantInfo?[participantId];
                  final liveProfile = byId[participantId];

                  final fallbackName =
                      participantInfo?.name ?? liveProfile?.name ?? l10n.group_members_subtitle_member;
                  final displayName = resolveContactDisplayName(
                    contactProfiles: contactProfiles,
                    contactUserId: participantId,
                    fallbackName: fallbackName,
                  );
                  final avatarUrl =
                      (liveProfile?.avatarThumb?.trim().isNotEmpty == true
                              ? liveProfile!.avatarThumb
                              : liveProfile?.avatar) ??
                          (participantInfo?.avatarThumb?.trim().isNotEmpty ==
                                  true
                              ? participantInfo!.avatarThumb
                              : participantInfo?.avatar);
                  final online = liveProfile?.online == true &&
                      liveProfile?.privacySettings?.showOnlineStatus != false;

                  return _MemberRow(
                    displayName: displayName,
                    subtitle: _subtitleForMember(
                      isMemberCreator: isMemberCreator,
                      isAdmin: isElevatedAdmin,
                      profile: liveProfile,
                      l10n: l10n,
                    ),
                    avatarUrl: avatarUrl,
                    online: online,
                    isElevatedAdmin: isElevatedAdmin,
                    isCreator: isMemberCreator,
                    badgeText: l10n.group_members_admin_badge,
                    canManageAdmin: isCreator && !isCurrentUser && !isMemberCreator,
                    canRemove: isAdmin && !isCurrentUser && !isMemberCreator,
                    onTap: () => _openProfile(context, participantId),
                    onAdminToggle: () => _confirmToggleAdmin(
                      context: context,
                      conv: conv,
                      participantId: participantId,
                      participantName: displayName,
                      isCurrentlyAdmin: isParticipantAdmin,
                      l10n: l10n,
                    ),
                    onRemove: () => _confirmRemoveMember(
                      context: context,
                      participantId: participantId,
                      participantName: displayName,
                      l10n: l10n,
                    ),
                    rowHeight: _contactRowHeight,
                    avatarSize: _avatarSize,
                    avatarRadius: _avatarRadius,
                    onlineSize: _avatarOnlineSize,
                    nameFontSize: _contactNameFontSize,
                    statusFontSize: _contactStatusFontSize,
                    horizontalPad: _hPad + 2,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _subtitleForMember({
    required bool isMemberCreator,
    required bool isAdmin,
    required UserProfile? profile,
    required AppLocalizations l10n,
  }) {
    if (isMemberCreator) return l10n.group_members_subtitle_creator;
    if (isAdmin) return l10n.group_members_subtitle_admin;
    final handle = (profile?.username ?? '').trim();
    if (handle.isNotEmpty) return '@$handle';
    return l10n.group_members_subtitle_member;
  }

  Widget _header({
    required BuildContext context,
    required Conversation conv,
    required bool isAdmin,
    required AppLocalizations l10n,
    required Color baseFg,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/chats'),
              style: IconButton.styleFrom(
                backgroundColor: baseFg.withValues(alpha: dark ? 0.08 : 0.06),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(9),
                minimumSize: const Size(36, 36),
              ),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: baseFg.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.group_members_title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      color: baseFg.withValues(alpha: dark ? 1 : 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.group_members_total_count(conv.participantIds.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: baseFg.withValues(alpha: dark ? 0.6 : 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              _TopCircleButton(
                icon: Icons.link_rounded,
                busy: false,
                onTap: _busy
                    ? null
                    : () => unawaited(_copyInviteLink(context, conv, l10n)),
                tooltip: l10n.group_members_copy_invite_tooltip,
              ),
              const SizedBox(width: 8),
              _TopCircleButton(
                icon: Icons.person_add_alt_1_rounded,
                busy: _busy,
                onTap: _busy
                    ? null
                    : () => unawaited(_openAddMembersSheet(context, conv, l10n)),
                tooltip: l10n.group_members_add_member_tooltip,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyInviteLink(
    BuildContext context,
    Conversation conv,
    AppLocalizations l10n,
  ) async {
    final inviteLink =
        'https://lighchat.online/join?group=${widget.conversationId}';
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final mq = MediaQuery.maybeOf(context);
    final origin = mq == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : Rect.fromCenter(
            center: Offset(mq.size.width / 2, mq.size.height / 2),
            width: 1,
            height: 1,
          );
    try {
      await Clipboard.setData(ClipboardData(text: inviteLink));
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.group_members_invite_copied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Fallback to share sheet if clipboard fails.
      final groupName = conv.name ?? 'Group';
      final text = l10n.group_members_invite_text(groupName, inviteLink);
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'Join $groupName on LighChat',
            sharePositionOrigin: origin,
          ),
        );
      } catch (e2) {
        if (!mounted) return;
        setState(() => _error = AppLocalizations.of(context)!.group_members_copy_link_error(e2.toString()));
      }
    }
  }

  Future<void> _openAddMembersSheet(
    BuildContext context,
    Conversation conv,
    AppLocalizations l10n,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final added = await _AddGroupMembersSheet.show(
      context,
      conversationId: widget.conversationId,
      currentParticipantIds: conv.participantIds.toSet(),
    );
    if (added != true || !mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.group_members_added),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProfile(BuildContext context, String participantId) {
    context.push('/contacts/user/${Uri.encodeComponent(participantId)}');
  }

  Future<void> _confirmToggleAdmin({
    required BuildContext context,
    required Conversation conv,
    required String participantId,
    required String participantName,
    required bool isCurrentlyAdmin,
    required AppLocalizations l10n,
  }) async {
    if (_busy) return;

    // Pre-validate: cannot demote creator; need at least 1 admin if revoking.
    if (isCurrentlyAdmin && conv.createdByUserId == participantId) {
      setState(() => _error = l10n.group_members_error_cannot_remove_creator);
      return;
    }
    final effectiveAdmins = <String>{
      ...conv.adminIds,
      if (conv.createdByUserId != null) conv.createdByUserId!,
    };
    if (isCurrentlyAdmin && effectiveAdmins.length <= 1) {
      setState(() => _error = l10n.group_members_error_min_admin);
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final ok = await _showAdminRoleConfirmDialog(
      context: context,
      isCurrentlyAdmin: isCurrentlyAdmin,
      participantName: participantName,
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final newAdminIds = List<String>.from(conv.adminIds);
      if (isCurrentlyAdmin) {
        newAdminIds.remove(participantId);
      } else {
        if (!newAdminIds.contains(participantId)) {
          newAdminIds.add(participantId);
        }
      }
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'adminIds': newAdminIds});
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyAdmin
                ? l10n.group_members_remove_admin
                : l10n.group_members_make_admin,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showAdminRoleConfirmDialog({
    required BuildContext context,
    required bool isCurrentlyAdmin,
    required String participantName,
  }) {
    final dl10n = AppLocalizations.of(context)!;
    final title = isCurrentlyAdmin
        ? dl10n.group_members_revoke_admin_title
        : dl10n.group_members_grant_admin_title;
    final body = isCurrentlyAdmin
        ? dl10n.group_members_revoke_admin_body(participantName)
        : dl10n.group_members_grant_admin_body(participantName);
    final actionText = isCurrentlyAdmin ? dl10n.group_members_revoke_admin_action : dl10n.group_members_grant_admin_action;
    final actionColor = isCurrentlyAdmin
        ? const Color(0xFFE0A23A)
        : const Color(0xFF3DB36B);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        final l10nDialog = AppLocalizations.of(ctx)!;
        return Dialog(
          backgroundColor: const Color(0xFF17191D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(actionText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10nDialog.common_cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveMember({
    required BuildContext context,
    required String participantId,
    required String participantName,
    required AppLocalizations l10n,
  }) async {
    if (_busy) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF17191D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.group_members_remove_title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.group_members_remove_body(participantName),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE24D59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.group_members_remove_action),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(<String, Object?>{
        'participantIds': FieldValue.arrayRemove(<String>[participantId]),
        'adminIds': FieldValue.arrayRemove(<String>[participantId]),
        'participantInfo.$participantId': FieldValue.delete(),
        'unreadCounts.$participantId': FieldValue.delete(),
        'unreadThreadCounts.$participantId': FieldValue.delete(),
      });
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.group_members_removed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.displayName,
    required this.subtitle,
    required this.avatarUrl,
    required this.online,
    required this.isElevatedAdmin,
    required this.isCreator,
    required this.badgeText,
    required this.canManageAdmin,
    required this.canRemove,
    required this.onTap,
    required this.onAdminToggle,
    required this.onRemove,
    required this.rowHeight,
    required this.avatarSize,
    required this.avatarRadius,
    required this.onlineSize,
    required this.nameFontSize,
    required this.statusFontSize,
    required this.horizontalPad,
  });

  final String displayName;
  final String subtitle;
  final String? avatarUrl;
  final bool online;
  final bool isElevatedAdmin;
  final bool isCreator;
  final String badgeText;
  final bool canManageAdmin;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onAdminToggle;
  final VoidCallback onRemove;
  final double rowHeight;
  final double avatarSize;
  final double avatarRadius;
  final double onlineSize;
  final double nameFontSize;
  final double statusFontSize;
  final double horizontalPad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;

    return SizedBox(
      height: rowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            child: Row(
              children: [
                _MemberAvatar(
                  title: displayName,
                  avatarUrl: avatarUrl,
                  online: online,
                  size: avatarSize,
                  radius: avatarRadius,
                  onlineSize: onlineSize,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    baseFg.withValues(alpha: dark ? 1 : 0.96),
                                fontSize: nameFontSize,
                                height: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isElevatedAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCreator
                                    ? const Color(0xFFE0A23A)
                                        .withValues(alpha: 0.18)
                                    : scheme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCreator ? AppLocalizations.of(context)!.group_members_creator_badge : badgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: isCreator
                                      ? const Color(0xFFE0A23A)
                                      : scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: baseFg.withValues(alpha: dark ? 0.56 : 0.58),
                          fontSize: statusFontSize,
                          height: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManageAdmin || canRemove)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: baseFg.withValues(alpha: dark ? 0.7 : 0.55),
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'admin':
                          onAdminToggle();
                          break;
                        case 'remove':
                          onRemove();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                      if (canManageAdmin)
                        PopupMenuItem<String>(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(
                                isElevatedAdmin
                                    ? Icons.shield_outlined
                                    : Icons.workspace_premium_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isElevatedAdmin
                                    ? AppLocalizations.of(context)!.group_members_menu_revoke_admin
                                    : AppLocalizations.of(context)!.group_members_menu_grant_admin,
                              ),
                            ],
                          ),
                        ),
                      if (canRemove)
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_remove_outlined,
                                size: 18,
                                color: Color(0xFFE24D59),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.group_members_menu_remove,
                                style: const TextStyle(color: Color(0xFFE24D59)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.title,
    required this.avatarUrl,
    required this.online,
    required this.size,
    required this.radius,
    required this.onlineSize,
  });

  final String title;
  final String? avatarUrl;
  final bool online;
  final double size;
  final double radius;
  final double onlineSize;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF5572FF).withValues(alpha: 0.32),
                const Color(0xFF7C4DFF).withValues(alpha: 0.24),
              ],
            ),
          ),
          child: ChatAvatar(
            title: title,
            radius: radius,
            avatarUrl: avatarUrl,
          ),
        ),
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: onlineSize,
              height: onlineSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D65C),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF05070C)
                      : const Color(0xFFF1F5F9),
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    required this.onTap,
    required this.busy,
    this.icon = Icons.person_add_alt_1_rounded,
    this.tooltip,
  });

  final VoidCallback? onTap;
  final bool busy;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    final btn = Container(
      width: _GroupMembersScreenState._topActionButtonSize,
      height: _GroupMembersScreenState._topActionButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (dark ? Colors.white : scheme.surface).withValues(
          alpha: dark ? 0.08 : 0.86,
        ),
        border: Border.all(color: baseFg.withValues(alpha: dark ? 0.14 : 0.14)),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon,
                color: baseFg.withValues(alpha: dark ? 1 : 0.9),
                size: _GroupMembersScreenState._topActionIconSize,
              ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Bottom sheet for adding members from contacts to an existing group.
class _AddGroupMembersSheet extends ConsumerStatefulWidget {
  const _AddGroupMembersSheet({
    required this.conversationId,
    required this.currentParticipantIds,
  });

  final String conversationId;
  final Set<String> currentParticipantIds;

  static Future<bool?> show(
    BuildContext context, {
    required String conversationId,
    required Set<String> currentParticipantIds,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17191D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _AddGroupMembersSheet(
        conversationId: conversationId,
        currentParticipantIds: currentParticipantIds,
      ),
    );
  }

  @override
  ConsumerState<_AddGroupMembersSheet> createState() =>
      _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends ConsumerState<_AddGroupMembersSheet> {
  final Set<String> _selectedIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final userAsync = ref.watch(authUserProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SizedBox(
        height: mediaQuery.size.height * 0.78,
        child: userAsync.when(
          data: (u) {
            if (u == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final ownerId = u.uid;
            final contactsAsync =
                ref.watch(userContactsIndexProvider(ownerId));
            return contactsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.group_members_contacts_load_error(e.toString()),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              data: (idx) {
                final candidateIds = idx.contactIds
                    .where((id) => !widget.currentParticipantIds.contains(id))
                    .toList(growable: false);
                final profilesRepo = ref.watch(userProfilesRepositoryProvider);
                final stream = profilesRepo?.watchUsersByIds(candidateIds);
                return StreamBuilder<Map<String, UserProfile>>(
                  stream: stream,
                  builder: (context, snap) {
                    final byId = snap.data ?? const <String, UserProfile>{};
                    final query =
                        _searchController.text.trim().toLowerCase();
                    final rows = candidateIds
                        .map((id) => byId[id])
                        .whereType<UserProfile>()
                        .where((p) {
                      if (query.isEmpty) return true;
                      final name = p.name.toLowerCase();
                      final username = (p.username ?? '').toLowerCase();
                      return name.contains(query) ||
                          username.contains(query);
                    }).toList(growable: false)
                      ..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            ),
                      );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            AppLocalizations.of(context)!.group_members_add_title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: AppLocalizations.of(context)!.group_members_search_contacts,
                                hintStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white54,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: rows.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      candidateIds.isEmpty
                                          ? AppLocalizations.of(context)!.group_members_all_in_group
                                          : AppLocalizations.of(context)!.group_members_nobody_found,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.62),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: rows.length,
                                  itemBuilder: (context, index) {
                                    final p = rows[index];
                                    final selected =
                                        _selectedIds.contains(p.id);
                                    final fallback = p.name.trim().isNotEmpty
                                        ? p.name.trim()
                                        : AppLocalizations.of(context)!.group_members_user_fallback;
                                    final displayName =
                                        resolveContactDisplayName(
                                      contactProfiles: idx.contactProfiles,
                                      contactUserId: p.id,
                                      fallbackName: fallback,
                                    );
                                    final handle =
                                        (p.username ?? '').trim();
                                    return InkWell(
                                      onTap: _busy
                                          ? null
                                          : () => setState(() {
                                                if (selected) {
                                                  _selectedIds.remove(p.id);
                                                } else {
                                                  _selectedIds.add(p.id);
                                                }
                                              }),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            ChatAvatar(
                                              title: displayName,
                                              radius: 20,
                                              avatarUrl: p.avatarThumb ??
                                                  p.avatar,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (handle.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '@$handle',
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.55),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 160),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selected
                                                    ? const Color(0xFF3DB36B)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: selected
                                                      ? const Color(
                                                          0xFF3DB36B)
                                                      : Colors.white
                                                          .withValues(
                                                              alpha: 0.32),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: selected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 14),
                            child: SizedBox(
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3DB36B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed:
                                    _busy || _selectedIds.isEmpty
                                        ? null
                                        : () => unawaited(_addSelected(
                                              candidates: byId,
                                            )),
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _selectedIds.isEmpty
                                            ? AppLocalizations.of(context)!.group_members_select_members
                                            : AppLocalizations.of(context)!.group_members_add_count(_selectedIds.length),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.group_members_auth_error(e.toString()),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSelected({
    required Map<String, UserProfile> candidates,
  }) async {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ids = _selectedIds.toList(growable: false);
      final infoUpdates = <String, Object?>{};
      for (final id in ids) {
        final p = candidates[id];
        if (p == null) continue;
        final entry = <String, Object?>{
          'name': p.name.trim().isEmpty ? AppLocalizations.of(context)!.group_members_subtitle_member : p.name.trim(),
        };
        final thumb = p.avatarThumb?.trim();
        final avatar = p.avatar?.trim();
        if (thumb != null && thumb.isNotEmpty) entry['avatarThumb'] = thumb;
        if (avatar != null && avatar.isNotEmpty) entry['avatar'] = avatar;
        infoUpdates['participantInfo.$id'] = entry;
        infoUpdates['unreadCounts.$id'] = 0;
        infoUpdates['unreadThreadCounts.$id'] = 0;
      }

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(<String, Object?>{
        'participantIds': FieldValue.arrayUnion(ids),
        ...infoUpdates,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.group_members_add_failed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
