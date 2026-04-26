import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../data/device_contact_lookup_keys.dart';
import '../data/bottom_nav_icon_settings.dart';
import '../data/user_chat_policy.dart';
import '../data/contact_display_name.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'add_contact_by_phone_sheet.dart';
import 'chat_avatar.dart';
import 'chat_bottom_nav.dart';

class ChatContactsScreen extends ConsumerStatefulWidget {
  const ChatContactsScreen({super.key});

  @override
  ConsumerState<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends ConsumerState<ChatContactsScreen> {
  static const List<String> _alphabet = <String>[
    'А',
    'Б',
    'В',
    'Г',
    'Д',
    'Е',
    'Ж',
    'З',
    'И',
    'Й',
    'К',
    'Л',
    'М',
    'Н',
    'О',
    'П',
    'Р',
    'С',
    'Т',
    'У',
    'Ф',
    'Х',
    'Ц',
    'Ч',
    'Ш',
    'Щ',
    'Э',
    'Ю',
    'Я',
  ];

  static const double _contactRowHeight = 80;
  static const double _titleFontSize = 24;
  static const double _searchFontSize = 16;
  static const double _searchIconSize = 24;
  static const double _contactNameFontSize = 16;
  static const double _contactStatusFontSize = 13;
  static const double _alphabetRailFontSize = 13;
  static const double _emptyStateFontSize = 14;
  static const double _topActionButtonSize = 43;
  static const double _topActionIconSize = 20;
  static const double _searchFieldHeight = 43;
  static const double _sectionHeaderHeight = 35;
  static const double _sectionHeaderFontSize = 16;
  static const double _avatarSize = 52;
  static const double _avatarRadius = 24;
  static const double _avatarOnlineSize = 14;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();

  bool _syncBusy = false;

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<bool> _syncDeviceContacts({
    required BuildContext context,
    required String ownerId,
    required UserProfile viewer,
    required UserContactsRepository repo,
  }) async {
    if (_syncBusy) return false;
    setState(() => _syncBusy = true);
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final granted =
          permission == PermissionStatus.granted ||
          permission == PermissionStatus.limited;
      if (!granted) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доступ к контактам не предоставлен.')),
        );
        return false;
      }

      final contacts = await FlutterContacts.getAll(
        properties: <ContactProperty>{
          ContactProperty.phone,
          ContactProperty.email,
        },
      );
      final lookups = collectLookupKeysFromDeviceContacts(contacts);
      await repo.saveDeviceContactsConsent(ownerId: ownerId, granted: true);
      await repo.syncDeviceLookupKeys(
        ownerId: ownerId,
        lookupKeyToField: lookups,
      );

      final matchedIds = await repo.resolveUserIdsByRegistrationLookupKeys(
        lookups.keys,
      );
      final existing = (await repo.getContacts(ownerId)).contactIds.toSet();
      final toAdd = matchedIds
          .where((id) => id != ownerId && !existing.contains(id))
          .toList(growable: false);

      final profilesRepo = ref.read(userProfilesRepositoryProvider);
      if (profilesRepo != null && toAdd.isNotEmpty) {
        final all = await profilesRepo.listAllUsers();
        final byId = <String, UserProfile>{for (final p in all) p.id: p};
        final eligible = toAdd
            .where((id) {
              final p = byId[id];
              if (p == null) return false;
              return canStartDirectChat(viewer, p);
            })
            .toList(growable: false);
        await repo.addContactIds(ownerId, eligible);
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              eligible.isEmpty
                  ? 'Совпадений не найдено.'
                  : 'Добавлено контактов: ${eligible.length}.',
            ),
          ),
        );
        return true;
      }

      await repo.addContactIds(ownerId, toAdd);
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toAdd.isEmpty
                ? 'Совпадений не найдено.'
                : 'Добавлено контактов: ${toAdd.length}.',
          ),
        ),
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка синхронизации контактов: $e')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _syncBusy = false);
    }
  }

  String _letterForName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '#';
    final letter = trimmed.characters.first.toUpperCase();
    final isCyr = RegExp(r'^[А-ЯЁ]$').hasMatch(letter);
    final isLat = RegExp(r'^[A-Z]$').hasMatch(letter);
    if (isCyr || isLat) return letter;
    return '#';
  }

  String _statusLabel(UserProfile profile) {
    final privacy = profile.privacySettings;
    final canShowOnline = privacy?.showOnlineStatus != false;
    final canShowLastSeen = privacy?.showLastSeen != false;
    if (canShowOnline && profile.online == true) return 'онлайн';
    if (!canShowLastSeen) return 'Был (а) недавно';
    final lastSeen = profile.lastSeenAt;
    if (lastSeen == null) return 'Был (а) недавно';
    final now = DateTime.now();
    final local = lastSeen.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return 'Был (а) в $hh:$mm';
    }
    if (diffDays == 1) return 'Был (а) вчера';

    final years =
        now.year -
        local.year -
        ((now.month < local.month ||
                (now.month == local.month && now.day < local.day))
            ? 1
            : 0);
    if (years == 1) return 'Был (а) год назад';
    if (years > 1) return 'Был (а) ${_ruYearsLabel(years)} назад';

    const months = <String>[
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return 'Был (а) ${local.day} ${months[local.month - 1]}';
  }

  String _ruYearsLabel(int years) {
    final mod10 = years % 10;
    final mod100 = years % 100;
    if (mod10 == 1 && mod100 != 11) return '$years год';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$years года';
    }
    return '$years лет';
  }

  List<_ContactListEntry> _buildEntries(List<_ContactRowData> rows) {
    final grouped = <String, List<_ContactRowData>>{};
    for (final row in rows) {
      final letter = _letterForName(row.displayName);
      grouped.putIfAbsent(letter, () => <_ContactRowData>[]).add(row);
    }

    final orderedLetters = grouped.keys.toList(growable: false)
      ..sort((a, b) {
        final ai = _alphabet.indexOf(a);
        final bi = _alphabet.indexOf(b);
        if (ai == -1 && bi == -1) return a.compareTo(b);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });

    final entries = <_ContactListEntry>[];
    for (final letter in orderedLetters) {
      entries.add(_ContactListEntry.header(letter));
      final section = grouped[letter]!
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
      for (final row in section) {
        entries.add(
          _ContactListEntry.row(
            profile: row.profile,
            displayName: row.displayName,
          ),
        );
      }
    }
    return entries;
  }

  Map<String, double> _buildLetterOffsets(List<_ContactListEntry> entries) {
    var offset = 0.0;
    final offsets = <String, double>{};
    for (final entry in entries) {
      if (entry.isHeader) {
        offsets.putIfAbsent(entry.letter!, () => offset);
        offset += _sectionHeaderHeight;
      } else {
        offset += _contactRowHeight;
      }
    }
    return offsets;
  }

  double? _resolveLetterOffset(String letter, Map<String, double> offsets) {
    if (offsets.containsKey(letter)) return offsets[letter];
    final index = _alphabet.indexOf(letter);
    if (index == -1) return null;

    for (var i = index + 1; i < _alphabet.length; i++) {
      final v = offsets[_alphabet[i]];
      if (v != null) return v;
    }
    for (var i = index - 1; i >= 0; i--) {
      final v = offsets[_alphabet[i]];
      if (v != null) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final userAsync = ref.watch(authUserProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ContactsScreenBackdrop(),
          SafeArea(
            child: userAsync.when(
              data: (authUser) {
                if (authUser == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.go('/auth');
                  });
                  return const Center(child: CircularProgressIndicator());
                }
                final ownerId = authUser.uid;
                final userDoc =
                    ref
                        .watch(userChatSettingsDocProvider(ownerId))
                        .asData
                        ?.value ??
                    const <String, dynamic>{};
                final chatSettings = Map<String, dynamic>.from(
                  userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
                );
                final bottomNavAppearance =
                    (chatSettings['bottomNavAppearance'] as String?) ??
                    'colorful';
                final bottomNavIconNames = parseBottomNavIconNames(
                  chatSettings['bottomNavIconNames'],
                );
                final bottomNavGlobalStyle = BottomNavIconVisualStyle.fromJson(
                  chatSettings['bottomNavIconGlobalStyle'],
                );
                final bottomNavIconStyles = parseBottomNavIconStyles(
                  chatSettings['bottomNavIconStyles'],
                );
                final contactsAsync = ref.watch(
                  userContactsIndexProvider(ownerId),
                );
                return contactsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ошибка загрузки контактов: $e'),
                    ),
                  ),
                  data: (idx) {
                    final ids = idx.contactIds.toSet().toList(growable: false);
                    final profileRepo = ref.watch(
                      userProfilesRepositoryProvider,
                    );
                    final stream = profileRepo?.watchUsersByIds(<String>[
                      ownerId,
                      ...ids,
                    ]);
                    return StreamBuilder<Map<String, UserProfile>>(
                      stream: stream,
                      builder: (context, snap) {
                        final byId = snap.data ?? const <String, UserProfile>{};
                        final me = byId[ownerId];
                        final selfName = (me?.name ?? 'Профиль').trim().isEmpty
                            ? 'Профиль'
                            : (me?.name ?? 'Профиль').trim();
                        final selfAvatar = me?.avatarThumb ?? me?.avatar;

                        final query = _searchController.text
                            .trim()
                            .toLowerCase();
                        final contactRows =
                            ids
                                .map((id) => byId[id])
                                .whereType<UserProfile>()
                                .map((p) {
                                  final fallback = p.name.trim().isNotEmpty
                                      ? p.name.trim()
                                      : 'Пользователь';
                                  final displayName = resolveContactDisplayName(
                                    contactProfiles: idx.contactProfiles,
                                    contactUserId: p.id,
                                    fallbackName: fallback,
                                  );
                                  return _ContactRowData(
                                    profile: p,
                                    displayName: displayName,
                                  );
                                })
                                .where((row) {
                                  if (query.isEmpty) return true;
                                  final name = row.displayName.toLowerCase();
                                  final originalName = row.profile.name
                                      .toLowerCase();
                                  final username = (row.profile.username ?? '')
                                      .toLowerCase();
                                  return name.contains(query) ||
                                      originalName.contains(query) ||
                                      username.contains(query);
                                })
                                .toList(growable: false)
                              ..sort((a, b) {
                                final byName = a.displayName
                                    .toLowerCase()
                                    .compareTo(b.displayName.toLowerCase());
                                if (byName != 0) return byName;
                                return a.profile.id.compareTo(b.profile.id);
                              });

                        final entries = _buildEntries(contactRows);
                        final letterOffsets = _buildLetterOffsets(entries);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                18,
                                10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Контакты',
                                      style: TextStyle(
                                        fontSize: _titleFontSize,
                                        height: 0.95,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1.2,
                                        color: dark
                                            ? Colors.white
                                            : scheme.onSurface.withValues(
                                                alpha: 0.94,
                                              ),
                                      ),
                                    ),
                                  ),
                                  _TopCircleButton(
                                    busy: _syncBusy,
                                    onTap: (_syncBusy || me == null)
                                        ? null
                                        : () {
                                            final myPhone = (me.phone ?? '')
                                                .trim();
                                            if (myPhone.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Добавьте телефон в профиле, чтобы искать контакты по номеру.',
                                                  ),
                                                ),
                                              );
                                              if (!context.mounted) return;
                                              context.push('/profile');
                                              return;
                                            }
                                            final repo = ref.read(
                                              userContactsRepositoryProvider,
                                            );
                                            if (repo == null) return;
                                            unawaited(
                                              AddContactByPhoneSheet.show(
                                                context,
                                                ownerId: ownerId,
                                                viewer: me,
                                                contactsRepo: repo,
                                                existingContactIds: idx
                                                    .contactIds
                                                    .toSet(),
                                                onSyncDeviceContacts: () =>
                                                    _syncDeviceContacts(
                                                      context: context,
                                                      ownerId: ownerId,
                                                      viewer: me,
                                                      repo: repo,
                                                    ),
                                              ).then((selectedUserId) {
                                                if (selectedUserId == null ||
                                                    selectedUserId
                                                        .trim()
                                                        .isEmpty) {
                                                  return;
                                                }
                                                if (!context.mounted) return;
                                                context.push(
                                                  '/contacts/user/${Uri.encodeComponent(selectedUserId)}'
                                                  '/edit',
                                                );
                                              }),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                              child: _ContactsSearchField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            Expanded(
                              child: contactRows.isEmpty
                                  ? const _EmptyContactsState()
                                  : Stack(
                                      children: [
                                        ListView.builder(
                                          controller: _listController,
                                          padding: const EdgeInsets.only(
                                            left: 0,
                                            right: 34,
                                            bottom: 8,
                                          ),
                                          itemCount: entries.length,
                                          itemBuilder: (context, index) {
                                            final entry = entries[index];
                                            if (entry.isHeader) {
                                              return _LetterHeaderRow(
                                                letter: entry.letter!,
                                              );
                                            }
                                            final profile = entry.profile!;
                                            final displayName =
                                                entry.displayName ??
                                                profile.name;
                                            return _ContactRow(
                                              profile: profile,
                                              displayName: displayName,
                                              statusText: _statusLabel(profile),
                                              onTap: () => context.push(
                                                '/contacts/user/${Uri.encodeComponent(profile.id)}',
                                              ),
                                            );
                                          },
                                        ),
                                        Positioned(
                                          right: 6,
                                          top: 12,
                                          bottom: 18,
                                          child: _AlphabetRail(
                                            alphabet: _alphabet,
                                            visibleLetters: letterOffsets.keys
                                                .toSet(),
                                            onLetterTap: (letter) {
                                              final target =
                                                  _resolveLetterOffset(
                                                    letter,
                                                    letterOffsets,
                                                  );
                                              if (target == null ||
                                                  !_listController.hasClients) {
                                                return;
                                              }
                                              _listController.animateTo(
                                                target,
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                curve: Curves.easeOut,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            Container(
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
                                activeTab: ChatBottomNavTab.contacts,
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
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Auth error: $e'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsSearchField extends StatelessWidget {
  const _ContactsSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    return Container(
      height: _ChatContactsScreenState._searchFieldHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (dark ? Colors.white : scheme.surface).withValues(
          alpha: dark ? 0.07 : 0.82,
        ),
        border: Border.all(color: baseFg.withValues(alpha: dark ? 0.16 : 0.16)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: baseFg.withValues(alpha: dark ? 1 : 0.92),
          fontSize: _ChatContactsScreenState._searchFontSize,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Поиск контактов...',
          hintStyle: TextStyle(
            color: baseFg.withValues(alpha: dark ? 0.42 : 0.42),
            fontSize: _ChatContactsScreenState._searchFontSize,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: baseFg.withValues(alpha: dark ? 0.5 : 0.48),
            size: _ChatContactsScreenState._searchIconSize,
          ),
          // Keep hint and input vertically centered inside the fixed-height field.
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({required this.onTap, required this.busy});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    return Container(
      width: _ChatContactsScreenState._topActionButtonSize,
      height: _ChatContactsScreenState._topActionButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (dark ? Colors.white : scheme.surface).withValues(
          alpha: dark ? 0.08 : 0.86,
        ),
        border: Border.all(color: baseFg.withValues(alpha: dark ? 0.14 : 0.14)),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.person_add_alt_1_rounded,
                color: baseFg.withValues(alpha: dark ? 1 : 0.9),
                size: _ChatContactsScreenState._topActionIconSize,
              ),
      ),
    );
  }
}

class _LetterHeaderRow extends StatelessWidget {
  const _LetterHeaderRow({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    return Container(
      height: _ChatContactsScreenState._sectionHeaderHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseFg.withValues(alpha: dark ? 0.12 : 0.10),
            baseFg.withValues(alpha: dark ? 0.03 : 0.02),
          ],
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: baseFg.withValues(alpha: dark ? 0.72 : 0.68),
          fontSize: _ChatContactsScreenState._sectionHeaderFontSize,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.profile,
    required this.displayName,
    required this.statusText,
    required this.onTap,
  });

  final UserProfile profile;
  final String displayName;
  final String statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    return SizedBox(
      height: _ChatContactsScreenState._contactRowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _ContactAvatar(
                  title: displayName,
                  avatarUrl: profile.avatarThumb ?? profile.avatar,
                  online:
                      profile.online == true &&
                      profile.privacySettings?.showOnlineStatus != false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: baseFg.withValues(alpha: dark ? 1 : 0.96),
                          fontSize:
                              _ChatContactsScreenState._contactNameFontSize,
                          height: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: baseFg.withValues(alpha: dark ? 0.56 : 0.58),
                          fontSize:
                              _ChatContactsScreenState._contactStatusFontSize,
                          height: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.title,
    required this.avatarUrl,
    required this.online,
  });

  final String title;
  final String? avatarUrl;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _ChatContactsScreenState._avatarSize,
          height: _ChatContactsScreenState._avatarSize,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF5572FF).withValues(alpha: 0.32),
                const Color(0xFF7C4DFF).withValues(alpha: 0.24),
              ],
            ),
          ),
          child: ChatAvatar(
            title: title,
            radius: _ChatContactsScreenState._avatarRadius,
            avatarUrl: avatarUrl,
          ),
        ),
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: _ChatContactsScreenState._avatarOnlineSize,
              height: _ChatContactsScreenState._avatarOnlineSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D65C),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF05070C)
                      : const Color(0xFFF1F5F9),
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({
    required this.alphabet,
    required this.visibleLetters,
    required this.onLetterTap,
  });

  final List<String> alphabet;
  final Set<String> visibleLetters;
  final ValueChanged<String> onLetterTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final baseFg = dark ? Colors.white : scheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: alphabet
          .map(
            (letter) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onLetterTap(letter),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: visibleLetters.contains(letter)
                        ? baseFg.withValues(alpha: dark ? 0.78 : 0.72)
                        : baseFg.withValues(alpha: dark ? 0.34 : 0.28),
                    fontSize: _ChatContactsScreenState._alphabetRailFontSize,
                    height: 1,
                    fontWeight: visibleLetters.contains(letter)
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  const _EmptyContactsState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Контакты не найдены.\nНажмите кнопку справа, чтобы синхронизировать телефонную книгу.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (dark ? Colors.white : scheme.onSurface).withValues(
              alpha: dark ? 0.78 : 0.74,
            ),
            fontSize: _ChatContactsScreenState._emptyStateFontSize,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ContactRowData {
  const _ContactRowData({required this.profile, required this.displayName});

  final UserProfile profile;
  final String displayName;
}

class _ContactListEntry {
  const _ContactListEntry._({this.letter, this.profile, this.displayName});

  factory _ContactListEntry.header(String letter) {
    return _ContactListEntry._(letter: letter);
  }

  factory _ContactListEntry.row({
    required UserProfile profile,
    required String displayName,
  }) {
    return _ContactListEntry._(profile: profile, displayName: displayName);
  }

  final String? letter;
  final UserProfile? profile;
  final String? displayName;

  bool get isHeader => profile == null;
}

class _ContactsScreenBackdrop extends StatelessWidget {
  const _ContactsScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final glowA = dark ? scheme.primary : const Color(0xFF4B7FFF);
    final glowB = dark ? scheme.tertiary : const Color(0xFF9C74FF);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF04070D) : const Color(0xFFF3F6FC),
          ),
        ),
        Positioned(
          left: -220,
          top: -180,
          child: IgnorePointer(
            child: Container(
              width: 620,
              height: 620,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowA.withValues(alpha: dark ? 0.34 : 0.18),
                    glowA.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -170,
          bottom: -190,
          child: IgnorePointer(
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowB.withValues(alpha: dark ? 0.26 : 0.14),
                    glowB.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (dark ? Colors.black : const Color(0xFF6B7280)).withValues(
                    alpha: dark ? 0.18 : 0.06,
                  ),
                  (dark ? Colors.black : const Color(0xFF6B7280)).withValues(
                    alpha: dark ? 0.34 : 0.10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
