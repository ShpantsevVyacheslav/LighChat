import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'chat_shell_backdrop.dart';

/// Профиль участника группы (открывается по тапу на @упоминание).
///
/// Отличие от профиля из личного чата: есть пункт меню «Написать лично».
class GroupMemberProfileSheet extends ConsumerStatefulWidget {
  const GroupMemberProfileSheet({
    super.key,
    required this.conversationId,
    required this.conversation,
    required this.currentUserId,
    required this.memberId,
    required this.selfProfile,
    required this.memberProfile,
  });

  final String conversationId;
  final Conversation conversation;
  final String currentUserId;
  final String memberId;
  final UserProfile? selfProfile;
  final UserProfile? memberProfile;

  @override
  ConsumerState<GroupMemberProfileSheet> createState() =>
      _GroupMemberProfileSheetState();
}

class _GroupMemberProfileSheetState extends ConsumerState<GroupMemberProfileSheet> {
  bool _busy = false;

  String get _title {
    final p = widget.memberProfile;
    if (p != null && p.name.trim().isNotEmpty) return p.name.trim();
    final fromConv = widget.conversation.participantInfo?[widget.memberId]?.name;
    final fallback = AppLocalizations.of(context)!.group_member_profile_default_name;
    return (fromConv ?? fallback).trim().isEmpty ? fallback : fromConv!.trim();
  }

  String? get _avatarUrl {
    final p = widget.memberProfile;
    final thumb = (p?.avatarThumb ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    final full = (p?.avatar ?? '').trim();
    if (full.isNotEmpty) return full;
    final info = widget.conversation.participantInfo?[widget.memberId];
    final it = (info?.avatarThumb ?? '').trim();
    if (it.isNotEmpty) return it;
    final iff = (info?.avatar ?? '').trim();
    return iff.isEmpty ? null : iff;
  }

  String? get _usernameLine {
    final u = (widget.memberProfile?.username ?? '').trim();
    if (u.isEmpty) return null;
    return u.startsWith('@') ? u : '@$u';
  }

  Future<void> _openDirectChat() async {
    if (_busy) return;
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    if (widget.memberId == widget.currentUserId) return;
    final me = widget.selfProfile;
    final peer = widget.memberProfile;
    if (me == null || peer == null) {
      // Минимальный safe-fallback: без профилей не создаём чат, чтобы не
      // послать некорректные данные в Firestore.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.group_member_profile_not_loaded)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final convId = await repo.createOrOpenDirectChat(
        currentUserId: widget.currentUserId,
        otherUserId: widget.memberId,
        currentUserInfo: (
          name: me.name,
          avatar: me.avatar,
          avatarThumb: me.avatarThumb,
        ),
        otherUserInfo: (
          name: peer.name,
          avatar: peer.avatar,
          avatarThumb: peer.avatarThumb,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/chats/$convId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.group_member_open_dm_error(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = Colors.white.withValues(alpha: 0.94);
    final muted = Colors.white.withValues(alpha: 0.68);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ChatShellBackdrop(),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                              color: fg,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                          child: Column(
                            children: [
                              ChatAvatar(
                                title: _title,
                                radius: 54,
                                avatarUrl: _avatarUrl,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                  height: 1.15,
                                ),
                              ),
                              if (_usernameLine != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _usernameLine!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              _menuButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: AppLocalizations.of(context)!.group_member_profile_dm,
                                onTap: _busy ? null : () => unawaited(_openDirectChat()),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.group_member_profile_dm_hint,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: muted.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

