import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/device_contacts_suggestions.dart';
import '../data/contact_display_name.dart';
import '../data/new_chat_user_search.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';
import 'chat_shell_backdrop.dart';
import 'device_contact_invite_row.dart';
import 'group_chat_avatar_button.dart';
import 'new_chat_user_picker_row.dart';
import '../../../l10n/app_localizations.dart';

class NewGroupChatScreenArgs {
  const NewGroupChatScreenArgs({
    this.initialSelectedUserIds = const <String>[],
  });

  final List<String> initialSelectedUserIds;
}

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({
    super.key,
    this.initialSelectedUserIds = const <String>[],
  });

  final List<String> initialSelectedUserIds;

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
  Timer? _deviceDebounce;
  List<Contact> _deviceContacts = const <Contact>[];
  bool _deviceContactsLoaded = false;
  Map<String, String> _deviceContactIdToUserId = const <String, String>{};
  String _deviceResolveKey = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(
      widget.initialSelectedUserIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty),
    );
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _deviceDebounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _name.dispose();
    _description.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _deviceDebounce?.cancel();
    _deviceDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      unawaited(_refreshDeviceContactMatches());
    });
  }

  Future<void> _ensureDeviceContactsLoaded() async {
    if (_deviceContactsLoaded) return;
    _deviceContactsLoaded = true;
    final loaded = await loadDeviceContactsIfGranted();
    if (!mounted) return;
    setState(() {
      _deviceContacts = loaded;
    });
  }

  Future<void> _refreshDeviceContactMatches() async {
    final term = _search.text.trim();
    if (term.isEmpty) {
      if (_deviceResolveKey.isNotEmpty && mounted) {
        setState(() {
          _deviceResolveKey = '';
          _deviceContactIdToUserId = const <String, String>{};
        });
      }
      return;
    }
    await _ensureDeviceContactsLoaded();
    final repo = ref.read(userContactsRepositoryProvider);
    if (repo == null) return;

    final candidates = buildDeviceContactCandidates(
      contacts: _deviceContacts,
      term: term,
      l10n: AppLocalizations.of(context)!,
      limit: 24,
    );
    final key =
        '${term.toLowerCase()}|${candidates.map((c) => c.contactId).join('\u001f')}';
    if (key == _deviceResolveKey) return;
    _deviceResolveKey = key;
    final resolved = await resolveCandidatesToUserIds(
      repo: repo,
      candidates: candidates,
    );
    if (!mounted) return;
    if (_deviceResolveKey != key) return;
    setState(() => _deviceContactIdToUserId = resolved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ref.read(userProfilesRepositoryProvider);
    if (repo != null && _usersFuture == null) {
      _usersFuture = repo.listAllUsers();
    }
    unawaited(_ensureDeviceContactsLoaded());
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats/new');
    }
  }

  String? _roleChipText(AppLocalizations l10n, String? role) {
    final r = role?.trim().toLowerCase();
    if (r == null || r.isEmpty) return null;
    if (r == 'admin') return l10n.new_group_role_badge_admin;
    if (r == 'worker') return l10n.new_group_role_badge_worker;
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
        textCapitalization: TextCapitalization.sentences,
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
    final l10n = AppLocalizations.of(context)!;
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
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
              cursorColor: scheme.primary,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: l10n.new_group_search_hint,
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              l10n.new_group_title,
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final handle = (self.username ?? '').trim();
    final subtitle = handle.isNotEmpty ? '@$handle' : '';
    final chip = _roleChipText(l10n, self.role);
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barColor = dark
        ? const Color(0xFF04070C).withValues(alpha: 0.94)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.98);

    return DecoratedBox(
      decoration: BoxDecoration(color: barColor),
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
                  child: Text(
                    l10n.common_cancel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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
                      : Text(
                          l10n.new_group_action_create,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.new_group_error_name_required,
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.new_group_error_members_required,
      );
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
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.go('/auth'),
                    );
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (profilesRepo == null ||
                      repo == null ||
                      _usersFuture == null) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppLocalizations.of(context)!.auth_firebase_not_ready,
                      ),
                    );
                  }

                  final contactsAsync = ref.watch(
                    userContactsIndexProvider(u.uid),
                  );

                  return contactsAsync.when(
                    data: (contactsIdx) {
                      final l10n = AppLocalizations.of(context)!;
                      return FutureBuilder<List<UserProfile>>(
                        future: _usersFuture,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final all = snap.data ?? const <UserProfile>[];
                          UserProfile? me;
                          for (final p in all) {
                            if (p.id == u.uid) me = p;
                          }
                          if (me == null) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.new_chat_error_self_profile_not_found,
                              ),
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

                          final displayNameById = <String, String>{};
                          for (final p in pool) {
                            final fallback = p.name.trim().isNotEmpty
                                ? p.name.trim()
                                : l10n.new_chat_fallback_user_display_name;
                            displayNameById[p.id] = resolveContactDisplayName(
                              contactProfiles: contactsIdx.contactProfiles,
                              contactUserId: p.id,
                              fallbackName: fallback,
                            );
                          }

                          final term = _search.text;
                          final matched = pool
                              .where(
                                (p) => userMatchesChatSearchQuery(
                                  p,
                                  term,
                                  displayNameOverride: displayNameById[p.id],
                                ),
                              )
                              .toList(growable: false);

                          final split = splitUsersByContactsAndGlobalVisibility(
                            matched: matched,
                            viewer: self,
                            contactIds: contactsIdx.contactIds,
                            displayNameById: displayNameById,
                          );

                          final listChildren = <Widget>[];

                          final deviceCandidates = buildDeviceContactCandidates(
                            contacts: _deviceContacts,
                            term: term,
                            l10n: AppLocalizations.of(context)!,
                            limit: 12,
                          );
                          if (term.trim().isNotEmpty &&
                              deviceCandidates.isNotEmpty) {
                            listChildren.add(
                              _sectionHeader(
                                context,
                                l10n.new_chat_section_phone_contacts,
                              ),
                            );
                            for (final c in deviceCandidates) {
                              final uid = _deviceContactIdToUserId[c.contactId];
                              final registered =
                                  uid != null && uid.trim().isNotEmpty;
                              listChildren.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _hPad,
                                  ),
                                  child: DeviceContactInviteRow(
                                    candidate: c,
                                    registered: registered,
                                    enabled: !_busy,
                                    onOpenChat: registered
                                        ? () {
                                            final p = byId[uid];
                                            if (p == null) return;
                                            setState(() {
                                              _selectedIds.add(p.id);
                                              _error = null;
                                            });
                                          }
                                        : null,
                                    onInvite: registered
                                        ? null
                                        : () async {
                                            final origin =
                                                shareOriginForContext(context);
                                            await SharePlus.instance.share(
                                              ShareParams(
                                                text: l10n.invite_text,
                                                subject: l10n.invite_subject,
                                                sharePositionOrigin: origin,
                                              ),
                                            );
                                          },
                                  ),
                                ),
                              );
                            }
                          }

                          if (split.fromContacts.isNotEmpty) {
                            listChildren.add(
                              _sectionHeader(
                                context,
                                l10n.new_chat_section_contacts,
                              ),
                            );
                            for (final p in split.fromContacts) {
                              listChildren.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _hPad,
                                  ),
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
                            listChildren.add(
                              _sectionHeader(
                                context,
                                l10n.new_chat_section_all_users,
                              ),
                            );
                            for (final p in split.fromGlobal) {
                              listChildren.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _hPad,
                                  ),
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
                                      message: AppLocalizations.of(
                                        context,
                                      )!.new_group_pick_photo_tooltip,
                                      child: GroupChatAvatarButton(
                                        enabled: !_busy,
                                        diameter: 112,
                                        placeholderIcon:
                                            Icons.people_outline_rounded,
                                        showCaptionRow: false,
                                        onChanged: (v) =>
                                            setState(() => _groupPhotoJpeg = v),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    _fieldLabel(
                                      context,
                                      AppLocalizations.of(
                                        context,
                                      )!.new_group_name_label,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: _hPad,
                                      ),
                                      child: _filledInput(
                                        context: context,
                                        controller: _name,
                                        hint: AppLocalizations.of(
                                          context,
                                        )!.new_group_name_hint,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _fieldLabel(
                                      context,
                                      AppLocalizations.of(
                                        context,
                                      )!.new_group_description_label,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: _hPad,
                                      ),
                                      child: _filledInput(
                                        context: context,
                                        controller: _description,
                                        hint: AppLocalizations.of(
                                          context,
                                        )!.new_group_description_hint,
                                        maxLines: 3,
                                        action: TextInputAction.newline,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        _hPad,
                                        0,
                                        _hPad,
                                        10,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.new_group_members_count(
                                          1 + selectedProfiles.length,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.88,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _selfParticipantRow(context, self),
                                    ...selectedProfiles.map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          _hPad,
                                          10,
                                          4,
                                          0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: NewChatUserPickerRow(
                                                profile: p,
                                                style: NewChatUserPickerRowStyle
                                                    .list,
                                                enabled: true,
                                                onTap: null,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(
                                                      () => _selectedIds.remove(
                                                        p.id,
                                                      ),
                                                    ),
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    _sectionHeader(
                                      context,
                                      AppLocalizations.of(
                                        context,
                                      )!.new_group_add_members_section,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: _hPad,
                                      ),
                                      child: _searchField(context),
                                    ),
                                    const SizedBox(height: 6),
                                    if (listChildren.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          term.trim().isEmpty
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.new_group_empty_no_users
                                              : AppLocalizations.of(
                                                  context,
                                                )!.new_group_empty_not_found,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.55,
                                            ),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    _hPad,
                                    0,
                                    _hPad,
                                    6,
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: scheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              _bottomActions(
                                context,
                                onCreate: () =>
                                    _submit(repo: repo, uid: u.uid, me: self),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.new_chat_error_contacts(e),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.new_group_error_auth_session(e),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
