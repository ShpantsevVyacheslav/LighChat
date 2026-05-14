import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/chat/data/contact_display_name.dart';
import 'package:lighchat_mobile/features/chat/data/profile_field_visibility.dart';
import 'package:lighchat_mobile/features/chat/data/user_profile.dart';

import 'birthday_cache_storage.dart';
import 'birthday_date_utils.dart';
import 'contact_birthday.dart';

class BirthdayCacheState {
  const BirthdayCacheState({
    required this.entries,
    required this.profiles,
    required this.loaded,
  });

  final Map<String, BirthdayCacheEntry> entries;
  final Map<String, UserProfile> profiles;
  final bool loaded;

  BirthdayCacheState copyWith({
    Map<String, BirthdayCacheEntry>? entries,
    Map<String, UserProfile>? profiles,
    bool? loaded,
  }) =>
      BirthdayCacheState(
        entries: entries ?? this.entries,
        profiles: profiles ?? this.profiles,
        loaded: loaded ?? this.loaded,
      );

  static const empty = BirthdayCacheState(
    entries: <String, BirthdayCacheEntry>{},
    profiles: <String, UserProfile>{},
    loaded: false,
  );
}

class ContactBirthdaysNotifier extends Notifier<BirthdayCacheState> {
  ContactBirthdaysNotifier(this._ownerUserId);

  final String _ownerUserId;
  final BirthdayCacheStorage _storage = const BirthdayCacheStorage();
  bool _fetching = false;
  bool _bootstrapped = false;

  /// Один раз за время жизни провайдера (фактически — за cold-start) делаем
  /// force-refresh **всех** контактов: игнорируем `isFresh` и перечитываем
  /// users/{id}. Это закрывает сценарий «контакт только что поменял dob» —
  /// без него до конца TTL клиент держал бы старое значение в кэше.
  bool _coldStartRefreshDone = false;

  @override
  BirthdayCacheState build() {
    if (!_bootstrapped) {
      _bootstrapped = true;
      unawaited(_bootstrap());
    }
    return BirthdayCacheState.empty;
  }

  Future<void> _bootstrap() async {
    final entries = await _storage.load(_ownerUserId);
    state = state.copyWith(entries: entries, loaded: true);
  }

  /// Лениво подгружает `dateOfBirth + privacy` для контактов, у кого
  /// нет свежей записи в кэше. Безопасно вызывать многократно —
  /// дедупликация по `isFresh`.
  Future<void> ensureFreshFor(List<String> contactIds) async {
    if (!state.loaded || _fetching) return;
    final forceAll = !_coldStartRefreshDone;
    final stale = <String>[];
    for (final id in contactIds) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      final entry = state.entries[trimmed];
      // Refetch если: первый вызов после cold-start (force-all), либо запись
      // отсутствует/устарела/записана старой схемой (без денормализованного
      // name). Force-all нужен, чтобы оперативно подхватить смену dob у
      // контакта — иначе клиент держит старое значение до конца TTL.
      if (forceAll ||
          entry == null ||
          !entry.isFresh ||
          entry.name == null) {
        stale.add(trimmed);
      }
    }
    if (forceAll) {
      _coldStartRefreshDone = true;
    }
    if (stale.isEmpty) return;
    final repo = ref.read(userProfilesRepositoryProvider);
    if (repo == null) return;

    _fetching = true;
    try {
      const chunkSize = 24;
      for (var i = 0; i < stale.length; i += chunkSize) {
        final end =
            i + chunkSize > stale.length ? stale.length : i + chunkSize;
        final chunk = stale.sublist(i, end);
        final profiles = await repo.getUsersByIdsOnce(chunk);
        final nextEntries =
            Map<String, BirthdayCacheEntry>.from(state.entries);
        final nextProfiles = Map<String, UserProfile>.from(state.profiles);
        final now = DateTime.now().toUtc();
        for (final id in chunk) {
          final profile = profiles[id];
          String? dob;
          if (profile != null) {
            nextProfiles[id] = profile;
            final allowed =
                isProfileFieldVisibleToOthers(profile, 'dateOfBirth');
            if (allowed) dob = profile.dateOfBirth;
          }
          nextEntries[id] = BirthdayCacheEntry(
            dob: dob,
            fetchedAt: now,
            name: profile?.name,
            avatar: profile?.avatar,
            avatarThumb: profile?.avatarThumb,
          );
        }
        state = state.copyWith(
          entries: nextEntries,
          profiles: nextProfiles,
        );
        await _storage.save(_ownerUserId, nextEntries);
      }
    } finally {
      _fetching = false;
    }
  }
}

final contactBirthdaysCacheProvider = NotifierProvider.family<
    ContactBirthdaysNotifier, BirthdayCacheState, String>(
  ContactBirthdaysNotifier.new,
);

/// Список именинников среди контактов **сегодня** (в локальной TZ
/// пользователя). Лениво триггерит подгрузку Firestore-данных при первом
/// чтении — но возвращает корректный список сразу после того, как кэш
/// прогрелся (на следующий ребилд).
final todayBirthdaysProvider =
    Provider.family<List<ContactBirthday>, String>((ref, ownerUserId) {
  final owner = ownerUserId.trim();
  if (owner.isEmpty) return const [];
  final contactsAsync = ref.watch(userContactsIndexProvider(owner));
  final contacts = contactsAsync.value;
  if (contacts == null) return const [];

  final cache = ref.watch(contactBirthdaysCacheProvider(owner));
  if (cache.loaded) {
    // Запускаем фоновую подгрузку через notifier — он сам отфильтрует stale-id.
    Future.microtask(() async {
      await ref
          .read(contactBirthdaysCacheProvider(owner).notifier)
          .ensureFreshFor(contacts.contactIds);
    });
  }

  if (!cache.loaded) return const [];

  final now = DateTime.now();
  final out = <ContactBirthday>[];
  for (final id in contacts.contactIds) {
    final entry = cache.entries[id];
    if (entry == null) continue;
    final dob = parseDobString(entry.dob);
    if (dob == null) continue;
    if (!isBirthdayToday(dob, now)) continue;

    final profile = cache.profiles[id];
    final entryName = (entry.name ?? '').trim();
    final remoteName = (profile?.name ?? entryName).trim();
    final remoteUsername = (profile?.username ?? '').trim();
    final fallbackName = remoteName.isNotEmpty
        ? remoteName
        : (remoteUsername.isNotEmpty ? '@$remoteUsername' : id);
    final displayName = resolveContactDisplayName(
      contactProfiles: contacts.contactProfiles,
      contactUserId: id,
      fallbackName: fallbackName,
    );

    out.add(ContactBirthday(
      userId: id,
      displayName: displayName,
      birthDate: dob,
      avatarUrl: profile?.avatar ?? entry.avatar,
      avatarThumb: profile?.avatarThumb ?? entry.avatarThumb,
      username: profile?.username,
      profile: profile,
    ));
  }
  out.sort((a, b) =>
      a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return List.unmodifiable(out);
});
