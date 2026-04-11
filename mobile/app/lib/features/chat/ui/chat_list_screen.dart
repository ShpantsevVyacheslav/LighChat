import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../data/user_profile.dart';
import '../data/saved_messages_chat.dart';

import '../../auth/ui/auth_glass.dart';
import 'chat_account_menu_sheet.dart';
import 'chat_folder_bar.dart';
import 'chat_list_item.dart';
import 'chat_bottom_nav.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  void _retryBoot({String? uid}) {
    ref.invalidate(authUserProvider);
    if (uid != null && uid.isNotEmpty) {
      ref.invalidate(registrationProfileCompleteProvider(uid));
      ref.invalidate(registrationProfileStatusProvider(uid));
      ref.invalidate(userChatIndexProvider(uid));
    }
  }

  Widget _bootLoading(String message, {String? uid}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _retryBoot(uid: uid),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: !firebaseReady
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Firebase is not configured yet.'),
                )
              : userAsync.when(
                  data: (user) {
                    if (user == null) {
                      // Hard-redirect away from chats when signed out.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) context.go('/auth');
                      });
                      return _bootLoading('Выход…', uid: null);
                    }

                    final indexAsync = ref.watch(
                      userChatIndexProvider(user.uid),
                    );
                    return indexAsync.when(
                      data: (idx) {
                        final ids = idx?.conversationIds ?? const <String>[];
                        final convAsync = ref.watch(
                          conversationsProvider((
                            key: conversationIdsCacheKey(ids),
                          )),
                        );
                        return convAsync.when(
                          data: (convs) {
                            final visibleConversations = convs
                                .where(
                                  (c) => _isVisibleConversationForUser(
                                    user.uid,
                                    c.data,
                                  ),
                                )
                                .toList(growable: false);
                            final folders = _buildFolders(
                              currentUserId: user.uid,
                              idx: idx,
                              conversations: visibleConversations,
                            );
                            return _ChatListBody(
                              currentUserId: user.uid,
                              folders: folders,
                              conversations: visibleConversations,
                            );
                          },
                          loading: () =>
                              _bootLoading('Загрузка бесед…', uid: user.uid),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Conversations error: $e'),
                          ),
                        );
                      },
                      loading: () =>
                          _bootLoading('Загрузка списка чатов…', uid: user.uid),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('userChats error: $e'),
                      ),
                    );
                  },
                  loading: () =>
                      _bootLoading('Подключение к аккаунту…', uid: null),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Auth error: $e'),
                  ),
                ),
        ),
      ),
    );
  }

  List<ChatFolder> _buildFolders({
    required String currentUserId,
    required UserChatIndex? idx,
    required List<ConversationWithId> conversations,
  }) {
    final saved = ChatFolder(
      id: 'favorites',
      name: 'Избранное',
      conversationIds: const <String>[],
    );

    final all = ChatFolder(
      id: 'all',
      name: 'Все',
      conversationIds: conversations.map((c) => c.id).toList(growable: false),
    );

    final unread = ChatFolder(
      id: 'unread',
      name: 'Новые',
      conversationIds: conversations
          .where((c) {
            final u =
                (c.data.unreadCounts?[currentUserId] ?? 0) +
                (c.data.unreadThreadCounts?[currentUserId] ?? 0);
            return u > 0;
          })
          .map((c) => c.id)
          .toList(growable: false),
    );

    final personal = ChatFolder(
      id: 'personal',
      name: 'Личные',
      conversationIds: conversations
          .where((c) => !c.data.isGroup)
          .map((c) => c.id)
          .toList(growable: false),
    );

    final groups = ChatFolder(
      id: 'groups',
      name: 'Группы',
      conversationIds: conversations
          .where((c) => c.data.isGroup)
          .map((c) => c.id)
          .toList(growable: false),
    );

    final custom = (idx?.folders ?? const <ChatFolder>[]);
    return <ChatFolder>[saved, all, unread, personal, groups, ...custom];
  }

  bool _isVisibleConversationForUser(String userId, Conversation conversation) {
    final participants = conversation.participantIds
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
    if (participants.isEmpty) return false;
    if (!participants.contains(userId)) return false;
    if (!conversation.isGroup && participants.length == 1) {
      return participants.first == userId;
    }
    return true;
  }
}

class _ChatListBody extends ConsumerStatefulWidget {
  const _ChatListBody({
    required this.currentUserId,
    required this.folders,
    required this.conversations,
  });

  final String currentUserId;
  final List<ChatFolder> folders;
  final List<ConversationWithId> conversations;

  @override
  ConsumerState<_ChatListBody> createState() => _ChatListBodyState();
}

class _ChatListBodyState extends ConsumerState<_ChatListBody> {
  String _activeFolderId = 'all';
  final _search = TextEditingController();

  Future<void> _openFavoritesChat({
    required String name,
    required String? avatar,
    required String? avatarThumb,
  }) async {
    final existing = widget.conversations
        .where((c) => isSavedMessagesConversation(c.data, widget.currentUserId))
        .toList(growable: false);
    if (existing.isNotEmpty) {
      existing.sort((a, b) {
        final ta =
            DateTime.tryParse(
              a.data.lastMessageTimestamp ?? '',
            )?.millisecondsSinceEpoch ??
            0;
        final tb =
            DateTime.tryParse(
              b.data.lastMessageTimestamp ?? '',
            )?.millisecondsSinceEpoch ??
            0;
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      context.go('/chats/${existing.first.id}');
      return;
    }

    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    try {
      final id = await repo.ensureSavedMessagesChat(
        currentUserId: widget.currentUserId,
        currentUserInfo: (name: name, avatar: avatar, avatarThumb: avatarThumb),
      );
      if (!mounted) return;
      context.go('/chats/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть Избранное: $e')),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _formatTimeLabel(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);
    final diffDays = d0.difference(d1).inDays;
    if (diffDays == 0) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (diffDays == 1) return 'Вчера';
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    return '$dd.$mo.$yy';
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folders.firstWhere(
      (f) => f.id == _activeFolderId,
      orElse: () => widget.folders.first,
    );
    final allowed = folder.conversationIds.toSet();
    final term = _search.text.trim().toLowerCase();
    final convs =
        widget.conversations
            .where((c) => allowed.contains(c.id))
            .where((c) {
              if (term.isEmpty) return true;
              final name = (c.data.name ?? '').toLowerCase();
              final last = (c.data.lastMessageText ?? '').toLowerCase();
              return name.contains(term) || last.contains(term);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final ta =
                DateTime.tryParse(
                  a.data.lastMessageTimestamp ?? '',
                )?.millisecondsSinceEpoch ??
                0;
            final tb =
                DateTime.tryParse(
                  b.data.lastMessageTimestamp ?? '',
                )?.millisecondsSinceEpoch ??
                0;
            return tb.compareTo(ta);
          });

    final otherIds = <String>{};
    for (final c in widget.conversations) {
      if (c.data.isGroup) continue;
      final p = c.data.participantIds;
      if (p.length != 2) continue;
      final other = p.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );
      if (other.isNotEmpty) otherIds.add(other);
    }
    otherIds.add(widget.currentUserId);

    final unreadByFolder = <String, int>{};
    for (final f in widget.folders) {
      int sum = 0;
      final set = f.conversationIds.toSet();
      for (final c in widget.conversations) {
        if (!set.contains(c.id)) continue;
        sum +=
            (c.data.unreadCounts?[widget.currentUserId] ?? 0) +
            (c.data.unreadThreadCounts?[widget.currentUserId] ?? 0);
      }
      unreadByFolder[f.id] = sum;
    }

    // Fetch profiles for DM naming + avatars.
    final profilesRepoProvider = ref.watch(userProfilesRepositoryProvider);
    final profilesStream = profilesRepoProvider?.watchUsersByIds(
      otherIds.toList(growable: false),
    );

    return StreamBuilder<Map<String, UserProfile>>(
      stream: profilesStream,
      builder: (context, snapProfiles) {
        final profiles = snapProfiles.data ?? const <String, UserProfile>{};
        final selfProfile = profiles[widget.currentUserId];
        final rawSelfName = selfProfile?.name ?? '';
        final rawSelfUsername = selfProfile?.username ?? '';
        final selfName = rawSelfName.trim().isNotEmpty
            ? rawSelfName.trim()
            : 'Профиль';
        final selfUsername = rawSelfUsername.trim().isNotEmpty
            ? rawSelfUsername.trim().replaceFirst(RegExp(r'^@'), '')
            : 'user';
        final selfAvatar = selfProfile?.avatarThumb ?? selfProfile?.avatar;

        final isEmptyList = convs.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatFolderBar(
              folders: widget.folders,
              activeFolderId: _activeFolderId,
              onSelectFolder: (id) async {
                if (id == 'favorites') {
                  await _openFavoritesChat(
                    name: selfName,
                    avatar: selfProfile?.avatar,
                    avatarThumb: selfProfile?.avatarThumb,
                  );
                  return;
                }
                if (!mounted) return;
                setState(() => _activeFolderId = id);
              },
              unreadByFolderId: unreadByFolder,
              onNewPressed: () {
                _openNewSheet(context);
              },
            ),
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withValues(
                          alpha:
                              Theme.of(context).colorScheme.brightness ==
                                  Brightness.dark
                              ? 0.06
                              : 0.22,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha:
                                Theme.of(context).colorScheme.brightness ==
                                    Brightness.dark
                                ? 0.12
                                : 0.35,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 16),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                hintText: 'Поиск...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          if (_search.text.trim().isNotEmpty)
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(
                        alpha:
                            Theme.of(context).colorScheme.brightness ==
                                Brightness.dark
                            ? 0.06
                            : 0.22,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha:
                              Theme.of(context).colorScheme.brightness ==
                                  Brightness.dark
                              ? 0.12
                              : 0.35,
                        ),
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'Новый чат',
                      onPressed: () => context.go('/chats/new'),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: isEmptyList
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Пока нет чатов',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Создайте новый чат, чтобы начать переписку.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () => context.go('/chats/new'),
                              child: const Text('Новая'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      itemCount: convs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = convs[index];
                        String title;
                        String? avatarUrl;
                        if (isSavedMessagesConversation(
                          c.data,
                          widget.currentUserId,
                        )) {
                          title = 'Избранное';
                          avatarUrl =
                              selfProfile?.avatarThumb ??
                              selfProfile?.avatar ??
                              c
                                  .data
                                  .participantInfo?[widget.currentUserId]
                                  ?.avatarThumb ??
                              c
                                  .data
                                  .participantInfo?[widget.currentUserId]
                                  ?.avatar;
                        } else if (c.data.isGroup) {
                          title = (c.data.name?.trim().isNotEmpty ?? false)
                              ? c.data.name!.trim()
                              : c.id;
                          avatarUrl = c.data.photoUrl;
                        } else {
                          final other = c.data.participantIds.firstWhere(
                            (id) => id != widget.currentUserId,
                            orElse: () => '',
                          );
                          final p = profiles[other];
                          avatarUrl =
                              p?.avatarThumb ??
                              p?.avatar ??
                              c.data.participantInfo?[other]?.avatarThumb ??
                              c.data.participantInfo?[other]?.avatar;
                          title =
                              p?.name ??
                              (c.data.name?.trim().isNotEmpty ?? false
                                  ? c.data.name!.trim()
                                  : other);
                          if (title.trim().isEmpty) title = c.id;
                        }
                        final subtitle = (c.data.lastMessageText ?? '').trim();
                        final unreadCount =
                            (c.data.unreadCounts?[widget.currentUserId] ?? 0) +
                            (c.data.unreadThreadCounts?[widget.currentUserId] ??
                                0);
                        final timeLabel = _formatTimeLabel(
                          c.data.lastMessageTimestamp,
                        );
                        return ChatListItem(
                          conversation: c,
                          title: title,
                          subtitle: subtitle,
                          unreadCount: unreadCount,
                          trailingTimeLabel: timeLabel,
                          avatarUrl: avatarUrl,
                          onTap: () => context.go('/chats/${c.id}'),
                        );
                      },
                    ),
            ),
            ChatBottomNav(
              onProfileTap: () => _openAccountMenu(
                context,
                name: selfName,
                username: selfUsername,
                avatarUrl: selfAvatar,
              ),
              avatarUrl: selfAvatar,
              userTitle: selfName,
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAccountMenu(
    BuildContext context, {
    required String name,
    required String username,
    required String? avatarUrl,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ChatAccountMenuSheet(
          name: name,
          username: username,
          avatarUrl: avatarUrl,
          onProfileTap: () {
            Navigator.of(ctx).pop();
            context.go('/profile');
          },
          onChatSettingsTap: () {
            Navigator.of(ctx).pop();
            context.go('/settings/chats');
          },
          onSignOutTap: () async {
            Navigator.of(ctx).pop();
            final repo = ref.read(authRepositoryProvider);
            try {
              if (repo != null) {
                await repo.signOut();
              }
              if (context.mounted) context.go('/auth');
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Не удалось выйти: $e')));
            }
          },
        );
      },
    );
  }

  Future<void> _openNewSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: dark ? 0.08 : 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder_rounded),
                    title: const Text('Новая папка'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final name = await _promptFolderName(context);
                      if (name == null) return;
                      final repo = ref.read(chatFoldersRepositoryProvider);
                      if (repo == null) return;
                      try {
                        await repo.createFolder(
                          userId: widget.currentUserId,
                          name: name,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_rounded),
                    title: const Text('Новый чат'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.go('/chats/new');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptFolderName(BuildContext context) async {
    final c = TextEditingController();
    try {
      return await showDialog<String?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Новая папка'),
            content: TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Название папки',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(c.text),
                child: const Text('Создать'),
              ),
            ],
          );
        },
      );
    } finally {
      c.dispose();
    }
  }
}
