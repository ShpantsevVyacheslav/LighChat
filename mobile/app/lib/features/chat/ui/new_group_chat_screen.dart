import 'dart:typed_data';

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
import 'group_chat_avatar_button.dart';
import 'new_chat_user_picker_row.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _search = TextEditingController();
  final Set<String> _selectedIds = {};
  Uint8List? _groupPhotoJpeg;
  Future<List<UserProfile>>? _usersFuture;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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

  Widget _roundedField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputAction action = TextInputAction.next,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        maxLines: maxLines,
        textInputAction: action,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
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
                hintText: 'Поиск пользователей…',
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

  Future<void> _submit({
    required ChatRepository repo,
    required String uid,
    required UserProfile me,
  }) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите название группы.');
      return;
    }
    if (_selectedIds.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одного участника.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final all = await _usersFuture!;
      final byId = {for (final p in all) p.id: p};
      final additional = _selectedIds
          .map((id) => byId[id])
          .whereType<UserProfile>()
          .map((p) => (id: p.id, name: p.name))
          .toList();

      final convId = await repo.createGroupChat(
        currentUserId: uid,
        currentUserName: me.name,
        name: name,
        description: _description.text.trim(),
        additionalParticipants: additional,
        groupPhotoJpeg: _groupPhotoJpeg,
      );
      if (!mounted) return;
      context.go('/chats/$convId');
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final repo = ref.watch(chatRepositoryProvider);
    final profilesRepo = ref.watch(userProfilesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/chats/new'),
        title: const Text('Создать группу'),
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

                      final byId = {for (final p in all) p.id: p};
                      final scheme = Theme.of(context).colorScheme;

                      final pool = all
                          .where((p) => p.id != u.uid)
                          .where(isEligibleRegisteredChatUser)
                          .where((p) => canStartDirectChat(self, p))
                          .where((p) => !_selectedIds.contains(p.id))
                          .toList(growable: false);

                      final term = _search.text;
                      final matched = pool
                          .where((p) => userMatchesChatSearchQuery(p, term))
                          .toList(growable: false);

                      final split = splitUsersByContactsAndGlobalVisibility(
                        matched: matched,
                        viewer: self,
                        contactIds: contactsIdx.contactIds,
                      );

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
                                selected: false,
                                selectionTrailing: true,
                                onTap: () {
                                  setState(() {
                                    _selectedIds.add(p.id);
                                    _error = null;
                                  });
                                },
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
                                selected: false,
                                selectionTrailing: true,
                                onTap: () {
                                  setState(() {
                                    _selectedIds.add(p.id);
                                    _error = null;
                                  });
                                },
                              ),
                            ),
                          );
                        }
                      }

                      final selectedProfiles = _selectedIds
                          .map((id) => byId[id])
                          .whereType<UserProfile>()
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 8),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                                  child: GroupChatAvatarButton(
                                    enabled: !_busy,
                                    onChanged: (v) => setState(() => _groupPhotoJpeg = v),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                                  child: Text(
                                    'Название группы',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: _roundedField(
                                    context: context,
                                    controller: _name,
                                    hint: 'Название',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                                  child: Text(
                                    'Описание',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: _roundedField(
                                    context: context,
                                    controller: _description,
                                    hint: 'Необязательно',
                                    maxLines: 3,
                                    action: TextInputAction.newline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                                  child: Text(
                                    'Участники (${1 + selectedProfiles.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: NewChatUserPickerRow(
                                    profile: self,
                                    enabled: false,
                                  ),
                                ),
                                ...selectedProfiles.map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: NewChatUserPickerRow(
                                            profile: p,
                                            enabled: !_busy,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _busy
                                              ? null
                                              : () => setState(() => _selectedIds.remove(p.id)),
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _sectionHeader(context, 'ДОБАВИТЬ УЧАСТНИКОВ'),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: _searchField(context),
                                ),
                                if (listChildren.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      term.trim().isEmpty
                                          ? 'Нет пользователей для добавления.'
                                          : 'Никого не найдено.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: scheme.onSurface.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  )
                                else
                                  ...listChildren,
                              ],
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                _error!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: _busy ? null : () => context.pop(),
                                  child: const Text('Отмена'),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _submit(repo: repo, uid: u.uid, me: self),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Создать'),
                                ),
                              ],
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
}
