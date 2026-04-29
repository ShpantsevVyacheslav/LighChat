import 'dart:async' show Timer, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/e2ee_auto_enable_helper.dart';
import '../data/contact_display_name.dart';
import '../data/device_contacts_suggestions.dart';
import '../data/new_chat_user_search.dart';
import '../data/secret_chat_create.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'chat_shell_backdrop.dart';
import 'device_contact_invite_row.dart';
import 'new_chat_user_picker_row.dart';
import 'secret_chat_compose_screen.dart';
import '../../../l10n/app_localizations.dart';

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
  Timer? _deviceDebounce;
  List<Contact> _deviceContacts = const <Contact>[];
  bool _deviceContactsLoaded = false;
  Map<String, String> _deviceContactIdToUserId = const <String, String>{};
  String _deviceResolveKey = '';

  static const _horizontalPad = 18.0;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _deviceDebounce?.cancel();
    _search.removeListener(_onSearchChanged);
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
      context.go('/chats');
    }
  }

  UserProfile _withDisplayName(UserProfile p, String displayName) {
    return UserProfile(
      id: p.id,
      name: displayName,
      username: p.username,
      avatar: p.avatar,
      avatarThumb: p.avatarThumb,
      email: p.email,
      phone: p.phone,
      bio: p.bio,
      role: p.role,
      online: p.online,
      lastSeenAt: p.lastSeenAt,
      dateOfBirth: p.dateOfBirth,
      deletedAt: p.deletedAt,
      privacySettings: p.privacySettings,
      blockedUserIds: p.blockedUserIds,
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPad,
        20,
        _horizontalPad,
        10,
      ),
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
                hintText: l10n.new_chat_search_hint,
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

  Widget _createGroupButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fill = dark
        ? Colors.white.withValues(alpha: 0.09)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : () => context.push('/chats/new/group'),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 22,
                color: scheme.onSurface.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.new_chat_create_group,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
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

  Widget _headerBlock(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_horizontalPad, 6, _horizontalPad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.new_chat_title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.new_chat_subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final repo = ref.watch(chatRepositoryProvider);
    final profilesRepo = ref.watch(userProfilesRepositoryProvider);

    return Scaffold(
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
                    child: Text(AppLocalizations.of(context)!.auth_firebase_not_ready),
                  );
                }

                final contactsAsync = ref.watch(
                  userContactsIndexProvider(u.uid),
                );

                return contactsAsync.when(
                  data: (contactsIdx) {
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
                        final l10n = AppLocalizations.of(context)!;

                        final others = all
                            .where((p) => p.id != u.uid)
                            .where(isEligibleRegisteredChatUser)
                            .where((p) => canStartDirectChat(self, p))
                            .toList(growable: false);
                        final othersById = {for (final p in others) p.id: p};
                        final displayNameById = <String, String>{};
                        for (final p in others) {
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
                        final matched = others
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
                        final secretIds = ref
                                .watch(userSecretChatIndexProvider(u.uid))
                                .asData
                                ?.value
                                ?.conversationIds ??
                            const <String>[];

                        final scheme = Theme.of(context).colorScheme;
                        final listChildren = <Widget>[];

                        final deviceCandidates = buildDeviceContactCandidates(
                          contacts: _deviceContacts,
                          term: term,
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
                                  horizontal: _horizontalPad,
                                ),
                                child: DeviceContactInviteRow(
                                  candidate: c,
                                  registered: registered,
                                  enabled: !_busy,
                                  onOpenChat: registered
                                      ? () {
                                          final p = othersById[uid];
                                          if (p == null) return;
                                          _openDirect(
                                            repo: repo,
                                            uid: u.uid,
                                            me: self,
                                            peer: p,
                                            allProfiles: all,
                                          );
                                        }
                                      : null,
                                  onInvite: registered
                                      ? null
                                      : () async {
                                          final origin = shareOriginForContext(
                                            context,
                                          );
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
                            final hasSecretWithUser = secretIds.contains(
                              buildSecretDirectConversationId(u.uid, p.id),
                            );
                            final viewProfile = _withDisplayName(
                              p,
                              (displayNameById[p.id] ?? p.name).trim(),
                            );
                            listChildren.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _horizontalPad,
                                ),
                                child: GestureDetector(
                                  onLongPress: (_busy || hasSecretWithUser)
                                      ? null
                                      : () => _openSecretDirect(
                                            me: self,
                                            peer: p,
                                          ),
                                  child: NewChatUserPickerRow(
                                    profile: viewProfile,
                                    style: NewChatUserPickerRowStyle.list,
                                    enabled: !_busy,
                                    badgeText: hasSecretWithUser
                                        ? AppLocalizations.of(
                                            context,
                                          )!.secret_chat_exists_badge
                                        : null,
                                    onTap: () => _openDirect(
                                      repo: repo,
                                      uid: u.uid,
                                      me: self,
                                      peer: p,
                                      allProfiles: all,
                                    ),
                                  ),
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
                            final hasSecretWithUser = secretIds.contains(
                              buildSecretDirectConversationId(u.uid, p.id),
                            );
                            final viewProfile = _withDisplayName(
                              p,
                              (displayNameById[p.id] ?? p.name).trim(),
                            );
                            listChildren.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _horizontalPad,
                                ),
                                child: GestureDetector(
                                  onLongPress: (_busy || hasSecretWithUser)
                                      ? null
                                      : () => _openSecretDirect(
                                            me: self,
                                            peer: p,
                                          ),
                                  child: NewChatUserPickerRow(
                                    profile: viewProfile,
                                    style: NewChatUserPickerRowStyle.list,
                                    enabled: !_busy,
                                    badgeText: hasSecretWithUser
                                        ? AppLocalizations.of(
                                            context,
                                          )!.secret_chat_exists_badge
                                        : null,
                                    onTap: () => _openDirect(
                                      repo: repo,
                                      uid: u.uid,
                                      me: self,
                                      peer: p,
                                      allProfiles: all,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _headerBlock(context),
                            const SizedBox(height: 22),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _horizontalPad,
                              ),
                              child: _searchField(context),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _horizontalPad,
                              ),
                              child: _createGroupButton(context),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  _horizontalPad,
                                  12,
                                  _horizontalPad,
                                  0,
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: listChildren.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          term.trim().isEmpty
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.new_chat_empty_no_users
                                              : AppLocalizations.of(
                                                  context,
                                                )!.new_chat_empty_not_found,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.55,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      children: listChildren,
                                    ),
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
                      )!.new_chat_error_contacts(e.toString()),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.chat_auth_error(e.toString()),
                ),
              ),
            ),
          ),
        ],
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
      // Phase 4: auto-enable E2EE, если это требует политика платформы или
      // пользователя. Ошибки молча игнорируются (паритет web), не блокируют
      // навигацию.
      await tryAutoEnableE2eeForMobileDm(
        firestore: FirebaseFirestore.instance,
        conversationId: convId,
        currentUserId: uid,
      );
      if (!mounted) return;
      context.push('/chats/$convId');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSecretDirect({
    required UserProfile me,
    required UserProfile peer,
  }) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    final secretId = buildSecretDirectConversationId(uid, peer.id);
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(secretId)
        .get();
    if (!mounted) return;
    final isActiveSecret = snap.exists &&
        ((snap.data()?['secretChat'] as Map?)?['enabled'] == true);
    if (isActiveSecret) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_already_exists);
      return;
    }
    context.push(
      '/chats/new/secret',
      extra: SecretChatComposeArgs(me: me, peer: peer),
    );
  }
}
