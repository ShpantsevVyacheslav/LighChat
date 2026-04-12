import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';
import '../data/new_chat_user_search.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'new_chat_user_picker_row.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _search = TextEditingController();
  Future<List<UserProfile>>? _usersFuture;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ref.read(userProfilesRepositoryProvider);
    if (repo != null && _usersFuture == null) {
      _usersFuture = repo.listAllUsers();
    }
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: scheme.onSurface.withValues(alpha: 0.50),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 16),
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: 'Имя, ник или @username…',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_search.text.trim().isNotEmpty)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _search.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final repo = ref.watch(chatRepositoryProvider);
    final profilesRepo = ref.watch(userProfilesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/chats'),
        title: const Text('Новый чат'),
      ),
      body: AuthBackground(
        child: SafeArea(
          child: userAsync.when(
            data: (u) {
              if (u == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth'));
                return const Center(child: CircularProgressIndicator());
              }

              if (profilesRepo == null || repo == null || _usersFuture == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Firebase не готов.'),
                );
              }

              final contactsAsync = ref.watch(userContactsIndexProvider(u.uid));

              return contactsAsync.when(
                data: (contactsIdx) {
                  return FutureBuilder<List<UserProfile>>(
                    future: _usersFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final all = snap.data ?? const <UserProfile>[];
                      UserProfile? me;
                      for (final p in all) {
                        if (p.id == u.uid) me = p;
                      }
                      if (me == null) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Не найден профиль в users/{uid}.'),
                        );
                      }
                      final self = me;

                      final others = all
                          .where((p) => p.id != u.uid)
                          .where(isEligibleRegisteredChatUser)
                          .where((p) => canStartDirectChat(self, p))
                          .toList(growable: false);

                      final term = _search.text;
                      final matched = others
                          .where((p) => userMatchesChatSearchQuery(p, term))
                          .toList(growable: false);

                      final split = splitUsersByContactsAndGlobalVisibility(
                        matched: matched,
                        viewer: self,
                        contactIds: contactsIdx.contactIds,
                      );

                      final scheme = Theme.of(context).colorScheme;
                      final listChildren = <Widget>[];

                      if (split.fromContacts.isNotEmpty) {
                        listChildren.add(_sectionHeader(context, 'КОНТАКТЫ'));
                        for (final p in split.fromContacts) {
                          listChildren.add(
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                              child: NewChatUserPickerRow(
                                profile: p,
                                enabled: !_busy,
                                onTap: () => _openDirect(
                                  repo: repo,
                                  uid: u.uid,
                                  me: self,
                                  peer: p,
                                  allProfiles: all,
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      if (split.fromGlobal.isNotEmpty) {
                        listChildren.add(_sectionHeader(context, 'ВСЕ ПОЛЬЗОВАТЕЛИ'));
                        for (final p in split.fromGlobal) {
                          listChildren.add(
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                              child: NewChatUserPickerRow(
                                profile: p,
                                enabled: !_busy,
                                onTap: () => _openDirect(
                                  repo: repo,
                                  uid: u.uid,
                                  me: self,
                                  peer: p,
                                  allProfiles: all,
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              'Выберите пользователя, чтобы начать диалог, или создайте группу.',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface.withValues(alpha: 0.62),
                                height: 1.35,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: _searchField(context),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: _busy ? null : () => context.push('/chats/new/group'),
                                icon: const Icon(Icons.group_add_rounded),
                                label: const Text('Создать группу'),
                              ),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Text(
                                _error!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          Expanded(
                            child: listChildren.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        term.trim().isEmpty
                                            ? 'Нет пользователей, с которыми можно начать чат.'
                                            : 'Никого не найдено.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: scheme.onSurface.withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    children: listChildren,
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Контакты: $e'),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Auth error: $e'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDirect({
    required ChatRepository repo,
    required String uid,
    required UserProfile me,
    required UserProfile peer,
    required List<UserProfile> allProfiles,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final convId = await repo.createOrOpenDirectChat(
        currentUserId: uid,
        otherUserId: peer.id,
        currentUserInfo: (name: me.name, avatar: me.avatar, avatarThumb: me.avatarThumb),
        otherUserInfo: (name: peer.name, avatar: peer.avatar, avatarThumb: peer.avatarThumb),
      );
      if (!mounted) return;
      context.go('/chats/$convId');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
