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
import 'chat_shell_backdrop.dart';
import 'profile_subpage_header.dart';
import '../../../l10n/app_localizations.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  static const _hPad = 18.0;

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
                          child: Text('Group not found.'),
                        );
                      }

                      final conv = Conversation.fromJson(
                        snap.data!.data() ?? const <String, dynamic>{},
                      );

                      // Check if user is participant
                      if (!conv.participantIds.contains(u.uid)) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('You are not a member of this group.'),
                        );
                      }

                      final l10n = AppLocalizations.of(context)!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(context, l10n),
                          Expanded(
                            child: _membersList(context, conv, u.uid, l10n),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return ChatProfileSubpageHeader(
      title: l10n.group_members_title,
      onBack: () => context.canPop() ? context.pop() : context.go('/chats'),
    );
  }

  Widget _membersList(
    BuildContext context,
    Conversation conv,
    String currentUserId,
    AppLocalizations l10n,
  ) {
    final isCreator = conv.createdByUserId == currentUserId;
    final contactProfiles = ref
            .watch(userContactsIndexProvider(currentUserId))
            .asData
            ?.value
            .contactProfiles ??
        const <String, ContactLocalProfile>{};

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const SizedBox(height: 16),
        // Invite link button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : () => _shareInviteLink(context, conv, l10n),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.group_members_invite_link),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Members list
        ...conv.participantIds.map((participantId) {
          final isCurrentUser = participantId == currentUserId;
          final isParticipantAdmin = conv.adminIds.contains(participantId);
          final participantInfo = conv.participantInfo?[participantId];

          return _memberTile(
            context: context,
            participantId: participantId,
            participantInfo: participantInfo,
            contactProfiles: contactProfiles,
            isAdmin: isParticipantAdmin,
            isCreator: conv.createdByUserId == participantId,
            canManageAdmin: isCreator && !isCurrentUser,
            l10n: l10n,
            onTap: () => _openProfile(context, participantId),
            onAdminToggle: isCreator && !isCurrentUser
                ? () => _toggleAdmin(
                    context,
                    conv,
                    participantId,
                    isParticipantAdmin,
                    l10n,
                  )
                : null,
          );
        }),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _memberTile({
    required BuildContext context,
    required String participantId,
    required ConversationParticipantInfo? participantInfo,
    required Map<String, ContactLocalProfile> contactProfiles,
    required bool isAdmin,
    required bool isCreator,
    required bool canManageAdmin,
    required AppLocalizations l10n,
    required VoidCallback onTap,
    required VoidCallback? onAdminToggle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = resolveContactDisplayName(
      contactProfiles: contactProfiles,
      contactUserId: participantId,
      fallbackName: participantInfo?.name ?? 'Unknown',
    );
    final avatarUrl = (participantInfo?.avatarThumb?.trim().isNotEmpty == true
            ? participantInfo!.avatarThumb
            : participantInfo?.avatar)
        ?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 4),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.group_members_admin_badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isCreator) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Creator',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Admin toggle button
                if (canManageAdmin) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: onAdminToggle,
                      icon: Icon(
                        isAdmin
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 20,
                        color: scheme.primary,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareInviteLink(
    BuildContext context,
    Conversation conv,
    AppLocalizations l10n,
  ) async {
    final inviteLink =
        'https://lighchat.online/join?group=${widget.conversationId}';
    final groupName = conv.name ?? 'Group';
    final text = l10n.group_members_invite_text(groupName, inviteLink);
    final mq = MediaQuery.maybeOf(context);
    final origin = mq == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : Rect.fromCenter(
            center: Offset(mq.size.width / 2, mq.size.height / 2),
            width: 1,
            height: 1,
          );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Join $groupName on LighChat',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to share invite link: $e');
    }
  }

  void _openProfile(BuildContext context, String participantId) {
    context.push('/contacts/user/${Uri.encodeComponent(participantId)}');
  }

  Future<void> _toggleAdmin(
    BuildContext context,
    Conversation conv,
    String participantId,
    bool isCurrentlyAdmin,
    AppLocalizations l10n,
  ) async {
    if (_busy) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Validate admin count
    final currentAdminCount =
        conv.adminIds.length + (conv.createdByUserId != null ? 1 : 0);
    if (isCurrentlyAdmin && currentAdminCount <= 1) {
      setState(() => _error = l10n.group_members_error_min_admin);
      return;
    }

    // Creator cannot be demoted
    if (isCurrentlyAdmin && conv.createdByUserId == participantId) {
      setState(() => _error = l10n.group_members_error_cannot_remove_creator);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final newAdminIds = List<String>.from(conv.adminIds);
      if (isCurrentlyAdmin) {
        newAdminIds.remove(participantId);
      } else {
        newAdminIds.add(participantId);
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
}
