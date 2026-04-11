import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/forward_recipients.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'forward_message_preview.dart';

/// Как web [ChatForwardSheet]: предпросмотр, только контакты + группы, без «Избранного».
class ChatForwardScreen extends ConsumerStatefulWidget {
  const ChatForwardScreen({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  ConsumerState<ChatForwardScreen> createState() => _ChatForwardScreenState();
}

class _ChatForwardScreenState extends ConsumerState<ChatForwardScreen> {
  final _selectedKeys = <String>{};
  final _search = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final scheme = Theme.of(context).colorScheme;

    if (widget.messages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Переслать')),
        body: const Center(child: Text('Нет сообщений для пересылки')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
        title: const Text('Переслать'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Не авторизован'));
          }
          final uid = user.uid;
          final contactsAsync = ref.watch(userContactsIndexProvider(uid));
          final indexAsync = ref.watch(userChatIndexProvider(uid));

          return contactsAsync.when(
            skipLoadingOnReload: true,
            data: (contacts) {
              final allowedPeers =
                  contacts.contactIds.where((id) => id.isNotEmpty && id != uid).toSet();

              return indexAsync.when(
                skipLoadingOnReload: true,
                data: (idx) {
                  final ids = idx?.conversationIds ?? const <String>[];
                  if (ids.isEmpty && allowedPeers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Нет контактов и чатов для пересылки'),
                      ),
                    );
                  }
                  final convAsync = ref.watch(conversationsProvider((key: conversationIdsCacheKey(ids))));
                  return convAsync.when(
                    skipLoadingOnReload: true,
                    data: (convs) {
                      final senderIds = widget.messages
                          .map((m) => m.senderId)
                          .where((s) => s.isNotEmpty)
                          .toSet()
                          .toList();
                      final profileIds = <String>{uid, ...allowedPeers, ...senderIds};
                      for (final c in convs) {
                        for (final p in c.data.participantIds) {
                          if (p.isNotEmpty) profileIds.add(p);
                        }
                      }
                      final profilesRepo = ref.watch(userProfilesRepositoryProvider);
                      final stream = profilesRepo?.watchUsersByIds(profileIds.toList()) ??
                          Stream.value(const <String, UserProfile>{});

                      return StreamBuilder<Map<String, UserProfile>>(
                        stream: stream,
                        builder: (context, snap) {
                          final profiles = snap.data ?? const <String, UserProfile>{};
                          final rows = buildForwardRecipientRows(
                            currentUserId: uid,
                            convs: convs,
                            allowedPeerIds: allowedPeers,
                            profiles: profiles,
                          );
                          final q = _search.text.trim().toLowerCase();
                          var filtered = rows;
                          if (q.isNotEmpty) {
                            filtered = rows
                                .where((r) =>
                                    r.displayName.toLowerCase().contains(q) ||
                                    r.subtitle.toLowerCase().contains(q))
                                .toList();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Сообщений: ${widget.messages.length} · получатели из контактов',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Text(
                                  'Предпросмотр',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: scheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  child: SingleChildScrollView(
                                    child: ForwardMessagePreview(
                                      messages: widget.messages,
                                      profilesById: profiles,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: TextField(
                                  controller: _search,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search_rounded),
                                    hintText: 'Поиск контактов и групп…',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          allowedPeers.isEmpty
                                              ? 'Добавьте контактов, чтобы переслать личным сообщением'
                                              : 'Ничего не найдено',
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, i) {
                                          final r = filtered[i];
                                          final sel = _selectedKeys.contains(r.selectionKey);
                                          return ListTile(
                                            leading: ChatAvatar(
                                              title: r.displayName,
                                              radius: 22,
                                              avatarUrl: r.avatarUrl,
                                            ),
                                            title: Text(
                                              r.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: r.subtitle.isEmpty
                                                ? null
                                                : Text(
                                                    r.subtitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                            trailing: sel
                                                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                                                : null,
                                            onTap: _busy
                                                ? null
                                                : () => setState(() {
                                                      if (sel) {
                                                        _selectedKeys.remove(r.selectionKey);
                                                      } else {
                                                        _selectedKeys.add(r.selectionKey);
                                                      }
                                                    }),
                                          );
                                        },
                                      ),
                              ),
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: FilledButton.icon(
                                    onPressed: _busy || _selectedKeys.isEmpty
                                        ? null
                                        : () => _send(uid, profiles),
                                    icon: _busy
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: scheme.onPrimary,
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                    label: Text(_selectedKeys.isEmpty
                                        ? 'Выберите получателей'
                                        : 'Отправить в ${_selectedKeys.length} чат(ов)'),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Ошибка: $e')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  Future<void> _send(String uid, Map<String, UserProfile> profiles) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    setState(() => _busy = true);
    final nameMap = <String, String>{for (final e in profiles.entries) e.key: e.value.name};
    for (final m in widget.messages) {
      nameMap.putIfAbsent(m.senderId, () => 'Участник');
    }
    try {
      final targetIds = <String>[];
      for (final key in _selectedKeys) {
        final peer = peerUserIdFromContactSelectionKey(key);
        if (peer != null) {
          final me = profiles[uid];
          final other = profiles[peer];
          if (me == null || other == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось загрузить профили для открытия чата')),
              );
            }
            return;
          }
          final convId = await repo.createOrOpenDirectChat(
            currentUserId: uid,
            otherUserId: peer,
            currentUserInfo: (name: me.name, avatar: me.avatar, avatarThumb: me.avatarThumb),
            otherUserInfo: (name: other.name, avatar: other.avatar, avatarThumb: other.avatarThumb),
          );
          targetIds.add(convId);
        } else {
          targetIds.add(key);
        }
      }
      final unique = targetIds.toSet().toList();
      await repo.forwardMessagesToChats(
        currentUserId: uid,
        targetConversationIds: unique,
        sourceMessages: widget.messages,
        senderIdToDisplayName: nameMap,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сообщения пересланы')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
