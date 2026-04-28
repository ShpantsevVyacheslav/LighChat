import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../chat/data/user_block_providers.dart';
import '../../chat/data/user_profile.dart';
import '../../chat/ui/chat_avatar.dart';
import '../../chat/ui/chat_shell_backdrop.dart';
import '../../../app_providers.dart';

class BlacklistScreen extends ConsumerWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.forward_error_not_authorized)));
    }

    final blockedAsync = ref.watch(userBlockedUserIdsProvider(uid));
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      Material(
                        color: fg.withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/account');
                            }
                          },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                              color: fg.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.account_menu_blacklist,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: fg.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: blockedAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.chat_list_error_generic(e),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (ids) {
                      final blockedIds = ids
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(growable: false);
                      if (blockedIds.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.blacklist_empty,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.55),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final repo = ref.watch(userProfilesRepositoryProvider);
                      final stream = repo != null
                          ? repo.watchUsersByIds(
                              blockedIds,
                            )
                          : Stream.value(const <String, UserProfile>{});

                      return StreamBuilder<Map<String, UserProfile>>(
                        stream: stream,
                        builder: (context, snap) {
                          final map = snap.data ?? const <String, UserProfile>{};
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                            itemCount: blockedIds.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: fg.withValues(alpha: dark ? 0.10 : 0.10),
                            ),
                            itemBuilder: (context, i) {
                              final id = blockedIds[i];
                              final p = map[id];
                              return _BlacklistTile(
                                viewerId: uid,
                                userId: id,
                                profile: p,
                              );
                            },
                          );
                        },
                      );
                    },
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

class _BlacklistTile extends ConsumerStatefulWidget {
  const _BlacklistTile({
    required this.viewerId,
    required this.userId,
    required this.profile,
  });

  final String viewerId;
  final String userId;
  final UserProfile? profile;

  @override
  ConsumerState<_BlacklistTile> createState() => _BlacklistTileState();
}

class _BlacklistTileState extends ConsumerState<_BlacklistTile> {
  bool _busy = false;

  Future<void> _unblock() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
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
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.viewerId).set(
        <String, Object?>{
          'blockedUserIds': FieldValue.arrayRemove([widget.userId]),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      // Success SnackBars are intentionally suppressed (errors only).
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.blacklist_unblock_error(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;

    final rawName = (widget.profile?.name ?? '').trim();
    final l10n = AppLocalizations.of(context)!;
    final title =
        rawName.isNotEmpty ? rawName : l10n.new_chat_fallback_user_display_name;
    final rawUsername = (widget.profile?.username ?? '').trim();
    final username = rawUsername.isNotEmpty
        ? '@${rawUsername.replaceFirst(RegExp(r'^@'), '')}'
        : '';
    final avatarUrl = widget.profile?.avatarThumb ?? widget.profile?.avatar;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ChatAvatar(title: title, radius: 22, avatarUrl: avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg.withValues(alpha: 0.95),
                  ),
                ),
                if (username.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _busy
              ? SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                )
              : Material(
                  color: fg.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _unblock,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.lock_open_rounded,
                        size: 18,
                        color: fg.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

