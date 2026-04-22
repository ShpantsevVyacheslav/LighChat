import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/new_chat_user_search.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'chat_shell_backdrop.dart';
import 'group_chat_avatar_button.dart';
import 'new_chat_user_picker_row.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  static const _hPad = 18.0;

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

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats/new');
    }
  }

  String? _roleChipText(String? role) {
    final r = role?.trim().toLowerCase();
    if (r == null || r.isEmpty) return null;
    if (r == 'admin') return 'АДМИН';
    if (r == 'worker') return 'СОТРУДНИК';
    return null;
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.85,
          color: scheme.onSurface.withValues(alpha: 0.48),
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _filledInput({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputAction action = TextInputAction.next,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fill = dark
        ? Colors.white.withValues(alpha: 0.09)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: fill,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: maxLines > 1 ? 12 : 4,
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        maxLines: maxLines,
        textInputAction: action,
        style: TextStyle(fontSize: 15, color: scheme.onSurface),
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.42),
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fill = dark
        ? Colors.white.withValues(alpha: 0.09)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: fill,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
              cursorColor: scheme.primary,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Поиск пользователей...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface.withValues(alpha: 0.42),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_search.text.trim().isNotEmpty)
            IconButton(
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
              onPressed: () {
                _search.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.18,
      ),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _closeScreen,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close_rounded,
            size: 22,
            color: scheme.onSurface.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Создать группу',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _closeButton(context),
          ),
        ],
      ),
    );
  }

  Widget _selfParticipantRow(BuildContext context, UserProfile self) {
    final scheme = Theme.of(context).colorScheme;
    final handle = (self.username ?? '').trim();
    final subtitle = handle.isNotEmpty ? '@$handle' : '';
    final chip = _roleChipText(self.role);
    final avatarUrl = self.avatarThumb ?? self.avatar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChatAvatar(title: self.name, radius: 22, avatarUrl: avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  self.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.52),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF34C759).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                chip,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFF5FE086),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomActions(
    BuildContext context, {
    required VoidCallback onCreate,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barColor = dark
        ? const Color(0xFF04070C).withValues(alpha: 0.94)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.98);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(_hPad, 12, _hPad, 12 + bottomInset),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _busy ? null : _closeScreen,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: scheme.onSurface.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _busy ? null : onCreate,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Text(
                          'Создать',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
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
      // Важно: после создания группы "назад" (и iOS swipe-back) должно вести
      // в список диалогов, а не на форму создания группы.
      context.go('/chats');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push('/chats/$convId');
      });
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
                                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                                  child: NewChatUserPickerRow(
                                    profile: p,
                                    style: NewChatUserPickerRowStyle.list,
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
                                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                                  child: NewChatUserPickerRow(
                                    profile: p,
                                    style: NewChatUserPickerRowStyle.list,
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
                              _header(context),
                              Expanded(
                                child: ListView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.only(bottom: 16),
                                  children: [
                                    const SizedBox(height: 16),
                                    Tooltip(
                                      message:
                                          'Нажмите, чтобы выбрать фото группы. Удерживайте, чтобы убрать.',
                                      child: GroupChatAvatarButton(
                                        enabled: !_busy,
                                        diameter: 112,
                                        placeholderIcon: Icons.people_outline_rounded,
                                        showCaptionRow: false,
                                        onChanged: (v) => setState(() => _groupPhotoJpeg = v),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    _fieldLabel(context, 'Название группы'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                                      child: _filledInput(
                                        context: context,
                                        controller: _name,
                                        hint: 'Название',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _fieldLabel(context, 'Описание'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                                      child: _filledInput(
                                        context: context,
                                        controller: _description,
                                        hint: 'Необязательно',
                                        maxLines: 3,
                                        action: TextInputAction.newline,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 10),
                                      child: Text(
                                        'Участники (${1 + selectedProfiles.length})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface.withValues(alpha: 0.88),
                                        ),
                                      ),
                                    ),
                                    _selfParticipantRow(context, self),
                                    ...selectedProfiles.map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.fromLTRB(_hPad, 10, 4, 0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: NewChatUserPickerRow(
                                                profile: p,
                                                style: NewChatUserPickerRowStyle.list,
                                                enabled: true,
                                                onTap: null,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(() => _selectedIds.remove(p.id)),
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: scheme.onSurface.withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    _sectionHeader(context, 'ДОБАВИТЬ УЧАСТНИКОВ'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                                      child: _searchField(context),
                                    ),
                                    const SizedBox(height: 6),
                                    if (listChildren.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          term.trim().isEmpty
                                              ? 'Нет пользователей для добавления.'
                                              : 'Никого не найдено.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheme.onSurface.withValues(alpha: 0.55),
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
                                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 6),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: scheme.error, fontSize: 13),
                                  ),
                                ),
                              _bottomActions(
                                context,
                                onCreate: () => _submit(repo: repo, uid: u.uid, me: self),
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
          ],
        ),
      ),
    );
  }
}
