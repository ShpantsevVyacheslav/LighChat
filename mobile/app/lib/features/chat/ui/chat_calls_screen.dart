import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../data/bottom_nav_icon_settings.dart';
import '../data/chat_call_formatting.dart';
import '../data/chat_call_status.dart';
import '../data/chat_calls_providers.dart';
import '../data/contact_display_name.dart';
import '../data/new_chat_user_search.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'chat_bottom_nav.dart';
import 'chat_shell_backdrop.dart';

/// Экран «Звонки»: список завершённых/отменённых/пропущенных вызовов
/// (как веб `CallsHistoryPage`).
class ChatCallsScreen extends ConsumerStatefulWidget {
  const ChatCallsScreen({super.key});

  @override
  ConsumerState<ChatCallsScreen> createState() => _ChatCallsScreenState();
}

class _ChatCallsScreenState extends ConsumerState<ChatCallsScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);
    final l10n = AppLocalizations.of(context)!;

    if (!firebaseReady) {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text(l10n.chat_list_firebase_not_configured),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/auth');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userDoc =
            ref.watch(userChatSettingsDocProvider(user.uid)).asData?.value ??
            const <String, dynamic>{};
        final chatSettings = Map<String, dynamic>.from(
          userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
        );
        final bottomNavAppearance =
            (chatSettings['bottomNavAppearance'] as String?) ?? 'colorful';
        final bottomNavIconNames = parseBottomNavIconNames(
          chatSettings['bottomNavIconNames'],
        );
        final bottomNavGlobalStyle = BottomNavIconVisualStyle.fromJson(
          chatSettings['bottomNavIconGlobalStyle'],
        );
        final bottomNavIconStyles = parseBottomNavIconStyles(
          chatSettings['bottomNavIconStyles'],
        );

        final historyAsync = ref.watch(chatCallsHistoryProvider);
        final contactsAsync = ref.watch(userContactsIndexProvider(user.uid));
        final contactProfiles =
            contactsAsync.asData?.value.contactProfiles ??
            const <String, ContactLocalProfile>{};

        return historyAsync.when(
          data: (snap) {
            if (snap.error != null) {
              return Scaffold(
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ChatShellBackdrop(),
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.chat_calls_error_load(snap.error.toString()),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final calls = snap.calls;
            final ids = <String>{user.uid};
            for (final c in calls) {
              ids.add(c.callerId);
              ids.add(c.receiverId);
            }
            final profilesRepo = ref.watch(userProfilesRepositoryProvider);
            final profilesStream = profilesRepo != null
                ? profilesRepo.watchUsersByIds(ids.toList(growable: false))
                : Stream.value(const <String, UserProfile>{});

            return StreamBuilder<Map<String, UserProfile>>(
              stream: profilesStream,
              builder: (context, profileSnap) {
                final profiles =
                    profileSnap.data ?? const <String, UserProfile>{};
                final selfProfile = profiles[user.uid];
                final rawSelfName = selfProfile?.name ?? '';
                final selfName = rawSelfName.trim().isNotEmpty
                    ? rawSelfName.trim()
                    : l10n.profile_title;
                final selfAvatar =
                    selfProfile?.avatarThumb ?? selfProfile?.avatar;

                final term = _search.text.trim();
                final filtered = calls
                    .where((call) {
                      if (term.isEmpty) return true;
                      final isOutgoing = call.callerId == user.uid;
                      final otherId = isOutgoing
                          ? call.receiverId
                          : call.callerId;
                      final found = profiles[otherId];
                      final fallbackName =
                          (isOutgoing
                                  ? (call.receiverName ?? '')
                                  : call.callerName)
                              .trim();
                      final name = resolveContactDisplayName(
                        contactProfiles: contactProfiles,
                        contactUserId: otherId,
                        fallbackName: found?.name.trim().isNotEmpty == true
                            ? found!.name.trim()
                            : (fallbackName.isEmpty
                                  ? l10n.new_chat_fallback_user_display_name
                                  : fallbackName),
                      );
                      return ruEnSubstringMatch(
                        name.trim().isEmpty
                            ? l10n.new_chat_fallback_user_display_name
                            : name.trim(),
                        term,
                      );
                    })
                    .toList(growable: false);

                final scheme = Theme.of(context).colorScheme;
                final dark = scheme.brightness == Brightness.dark;
                final fg = dark ? Colors.white : scheme.onSurface;
                final meta = fg.withValues(alpha: dark ? 0.55 : 0.55);

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ChatShellBackdrop(),
                      Column(
                        children: [
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.chat_calls_title,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: fg,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => context.push('/contacts'),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: fg.withValues(alpha: 0.12),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: fg.withValues(alpha: 0.92),
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(color: fg, fontSize: 15),
                              cursorColor: scheme.primary,
                              decoration: InputDecoration(
                                hintText: l10n.chat_calls_search_hint,
                                hintStyle: TextStyle(
                                  color: fg.withValues(alpha: 0.42),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: fg.withValues(alpha: 0.45),
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: fg.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide(
                                    color: fg.withValues(
                                      alpha: dark ? 0.1 : 0.12,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide(
                                    color: fg.withValues(
                                      alpha: dark ? 0.1 : 0.12,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide(
                                    color: scheme.primary.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 4,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          Expanded(
                            child: snap.loading && calls.isEmpty
                                ? const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      term.isEmpty
                                          ? l10n.chat_calls_empty
                                          : l10n.chat_calls_nothing_found,
                                      style: TextStyle(
                                        color: meta,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      8,
                                      12,
                                    ),
                                    itemCount: filtered.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 2),
                                    itemBuilder: (context, index) {
                                      final call = filtered[index];
                                      final isOutgoing =
                                          call.callerId == user.uid;
                                      final otherId = isOutgoing
                                          ? call.receiverId
                                          : call.callerId;
                                      final found = profiles[otherId];
                                      final fallbackName =
                                          (isOutgoing
                                                  ? (call.receiverName ?? '')
                                                  : call.callerName)
                                              .trim();
                                      final displayName =
                                          resolveContactDisplayName(
                                            contactProfiles: contactProfiles,
                                            contactUserId: otherId,
                                            fallbackName:
                                                found?.name.trim().isNotEmpty ==
                                                    true
                                                ? found!.name.trim()
                                                : (fallbackName.isEmpty
                                                      ? l10n
                                                          .new_chat_fallback_user_display_name
                                                      : fallbackName),
                                          );
                                      final avatarUrl =
                                          found?.avatarThumb ?? found?.avatar;
                                      final resolvedStatus =
                                          resolveCallTerminalStatusForViewer(
                                            rawStatus: call.status,
                                            viewerIsReceiver: !isOutgoing,
                                            callerId: call.callerId,
                                            receiverId: call.receiverId,
                                            endedBy: call.endedBy,
                                          );
                                      final missed = resolvedStatus == 'missed';
                                      final cancelled =
                                          resolvedStatus == 'cancelled';
                                      final createdLocal = call.createdAt
                                          .toLocal();
                                      final subtitle = formatCallListSubtitle(
                                      l10n: AppLocalizations.of(context)!,
                                        createdLocal: createdLocal,
                                        startedAt: call.startedAt?.toLocal(),
                                        endedAt: call.endedAt?.toLocal(),
                                      );

                                      IconData dirIcon;
                                      Color dirColor;
                                      if (missed) {
                                        dirIcon = Icons.call_missed_rounded;
                                        dirColor = scheme.error;
                                      } else if (cancelled) {
                                        dirIcon = isOutgoing
                                            ? Icons.call_made_rounded
                                            : Icons.call_received_rounded;
                                        dirColor = meta;
                                      } else if (isOutgoing) {
                                        dirIcon = Icons.call_made_rounded;
                                        dirColor = const Color(0xFF3B82F6);
                                      } else {
                                        dirIcon = Icons.call_received_rounded;
                                        dirColor = const Color(0xFF22C55E);
                                      }

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          onTap: () =>
                                              context.push('/calls/${call.id}'),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                ChatAvatar(
                                                  title: displayName,
                                                  radius: 26,
                                                  avatarUrl: avatarUrl,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        displayName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: missed
                                                              ? scheme.error
                                                              : fg,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            dirIcon,
                                                            size: 16,
                                                            color: dirColor,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              subtitle,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: meta,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: fg.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    call.isVideo
                                                        ? Icons.videocam_rounded
                                                        : Icons.call_rounded,
                                                    size: 22,
                                                    color: fg.withValues(
                                                      alpha: 0.88,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  (dark
                                          ? Colors.black
                                          : scheme.surfaceContainerLow)
                                      .withValues(alpha: dark ? 0.62 : 0.78),
                              border: Border(
                                top: BorderSide(
                                  color:
                                      (dark ? Colors.white : scheme.onSurface)
                                          .withValues(
                                            alpha: dark ? 0.08 : 0.12,
                                          ),
                                ),
                              ),
                            ),
                            child: ChatBottomNav(
                              activeTab: ChatBottomNavTab.calls,
                              onChatsTap: () => context.go('/chats'),
                              onContactsTap: () => context.go('/contacts'),
                              onCallsTap: () => context.go('/calls'),
                              onMeetingsTap: () => context.go('/meetings'),
                              onProfileTap: () => context.push('/account'),
                              avatarUrl: selfAvatar,
                              userTitle: selfName,
                              bottomNavAppearance: bottomNavAppearance,
                              bottomNavIconNames: bottomNavIconNames,
                              bottomNavIconGlobalStyle: bottomNavGlobalStyle,
                              bottomNavIconStyles: bottomNavIconStyles,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              Scaffold(body: Center(child: Text(l10n.chat_list_error_generic(e)))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.chat_auth_error(e.toString())))),
    );
  }
}
