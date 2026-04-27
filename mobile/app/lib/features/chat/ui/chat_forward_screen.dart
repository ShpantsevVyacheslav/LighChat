import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/e2ee_auto_enable_helper.dart';
import '../data/forward_recipients.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';

/// Экран пересылки: только контакты + группы, без «Избранного».
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

    if (widget.messages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Переслать')),
        body: const Center(child: Text('Нет сообщений для пересылки')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              final allowedPeers = contacts.contactIds
                  .where((id) => id.isNotEmpty && id != uid)
                  .toSet();

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
                  final convAsync = ref.watch(
                    conversationsProvider((key: conversationIdsCacheKey(ids))),
                  );
                  return convAsync.when(
                    skipLoadingOnReload: true,
                    data: (convs) {
                      final senderIds = widget.messages
                          .map((m) => m.senderId)
                          .where((s) => s.isNotEmpty)
                          .toSet()
                          .toList();
                      final profileIds = <String>{
                        uid,
                        ...allowedPeers,
                        ...senderIds,
                      };
                      for (final c in convs) {
                        for (final p in c.data.participantIds) {
                          if (p.isNotEmpty) profileIds.add(p);
                        }
                      }
                      final profilesRepo = ref.watch(
                        userProfilesRepositoryProvider,
                      );
                      final stream =
                          profilesRepo?.watchUsersByIds(profileIds.toList()) ??
                          Stream.value(const <String, UserProfile>{});

                      return StreamBuilder<Map<String, UserProfile>>(
                        stream: stream,
                        builder: (context, snap) {
                          final profiles =
                              snap.data ?? const <String, UserProfile>{};
                          final rows = buildForwardRecipientRows(
                            currentUserId: uid,
                            convs: convs,
                            allowedPeerIds: allowedPeers,
                            profiles: profiles,
                            contactProfiles: contacts.contactProfiles,
                          );
                          final q = _search.text.trim().toLowerCase();
                          var filtered = rows;
                          if (q.isNotEmpty) {
                            filtered = rows
                                .where(
                                  (r) =>
                                      r.displayName.toLowerCase().contains(q) ||
                                      r.subtitle.toLowerCase().contains(q) ||
                                      ((r.username ?? '')
                                          .toLowerCase()
                                          .contains(q)),
                                )
                                .toList();
                          }

                          return SafeArea(
                            bottom: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _topBar(),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: _glassPanel(
                                    child: SizedBox(
                                      height: 52,
                                      child: TextField(
                                        controller: _search,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        minLines: 1,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.96,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                          ),
                                          hintText: 'Поиск контактов…',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            height: 1.2,
                                          ),
                                          isDense: false,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Text(
                                              rows.isEmpty
                                                  ? 'Доступных получателей нет.\nМожно пересылать только контактам и в ваши активные чаты.'
                                                  : 'Ничего не найдено',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.78,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            0,
                                            12,
                                            8,
                                          ),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final r = filtered[i];
                                            final sel = _selectedKeys.contains(
                                              r.selectionKey,
                                            );
                                            return _recipientTile(
                                              row: r,
                                              selected: sel,
                                              onTap: _busy
                                                  ? null
                                                  : () => setState(() {
                                                      if (sel) {
                                                        _selectedKeys.remove(
                                                          r.selectionKey,
                                                        );
                                                      } else {
                                                        _selectedKeys.add(
                                                          r.selectionKey,
                                                        );
                                                      }
                                                    }),
                                            );
                                          },
                                        ),
                                ),
                                SafeArea(
                                  top: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors:
                                                _busy || _selectedKeys.isEmpty
                                                ? [
                                                    Colors.white.withValues(
                                                      alpha: 0.18,
                                                    ),
                                                    Colors.white.withValues(
                                                      alpha: 0.18,
                                                    ),
                                                  ]
                                                : const [
                                                    Color(0xFF2E86FF),
                                                    Color(0xFF5F90FF),
                                                    Color(0xFF9A18FF),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 46,
                                          child: TextButton(
                                            onPressed:
                                                _busy || _selectedKeys.isEmpty
                                                ? null
                                                : () => _send(
                                                    uid,
                                                    profiles,
                                                    rows
                                                        .map(
                                                          (r) => r.selectionKey,
                                                        )
                                                        .toSet(),
                                                  ),
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: _busy
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.send_rounded,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 7),
                                                      Text(
                                                        _selectedKeys.isEmpty
                                                            ? 'Выберите получателей'
                                                            : 'Отправить',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: _glassPanel(
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                onPressed: _busy ? null : () => context.pop(),
              ),
              Expanded(
                child: Text(
                  'Переслать',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipientTile({
    required ForwardRecipientRow row,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final subtitleText = row.subtitle.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              ChatAvatar(
                title: row.displayName,
                radius: 22,
                avatarUrl: row.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                    if (subtitleText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? scheme.primary.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.42),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12),
    double radius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _send(
    String uid,
    Map<String, UserProfile> profiles,
    Set<String> allowedSelectionKeys,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    setState(() => _busy = true);
    final nameMap = <String, String>{
      for (final e in profiles.entries) e.key: e.value.name,
    };
    for (final m in widget.messages) {
      nameMap.putIfAbsent(m.senderId, () => 'Участник');
    }
    try {
      final targetIds = <String>[];
      for (final key in _selectedKeys) {
        if (!allowedSelectionKeys.contains(key)) continue;
        final peer = peerUserIdFromContactSelectionKey(key);
        if (peer != null) {
          final me = profiles[uid];
          final other = profiles[peer];
          if (me == null || other == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Не удалось загрузить профили для открытия чата',
                  ),
                ),
              );
            }
            return;
          }
          final convId = await repo.createOrOpenDirectChat(
            currentUserId: uid,
            otherUserId: peer,
            currentUserInfo: (
              name: me.name,
              avatar: me.avatar,
              avatarThumb: me.avatarThumb,
            ),
            otherUserInfo: (
              name: other.name,
              avatar: other.avatar,
              avatarThumb: other.avatarThumb,
            ),
          );
          // Phase 9 gap #4: auto-enable E2EE если пользователь/платформа
          // требует шифровать новые DM. Для уже существующего DM не пересоздаёт
          // эпоху (см. `tryAutoEnableE2eeNewDirectChatMobile` идемпотентность).
          // Best-effort: ошибка не ломает форвард.
          await tryAutoEnableE2eeForMobileDm(
            firestore: FirebaseFirestore.instance,
            conversationId: convId,
            currentUserId: uid,
          );
          targetIds.add(convId);
        } else {
          targetIds.add(key);
        }
      }
      if (targetIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Нет доступных получателей. Можно пересылать только контактам и в ваши активные чаты.',
              ),
            ),
          );
        }
        return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сообщения пересланы')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final friendly = msg.contains('forward_failed_permission_or_membership')
          ? 'Не удалось переслать: нет прав на выбранные чаты или чат больше недоступен.'
          : (msg.contains('permission-denied')
                ? 'Не удалось переслать: доступ к одному из чатов запрещён.'
                : 'Ошибка: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
