import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'user_profile.dart';

/// Stable [StreamProvider] for matched user ids on the add-contact sheet.
/// Do not instantiate [StreamProvider] inside [build] — each rebuild would be a
/// new provider and [AsyncValue] could stay stuck in loading.
final addContactMatchedProfilesStreamProvider = StreamProvider.family
    .autoDispose<Map<String, UserProfile>, String>((ref, idsKey) {
      if (idsKey.isEmpty) {
        return Stream.value(const <String, UserProfile>{});
      }
      final repo = ref.watch(userProfilesRepositoryProvider);
      if (repo == null) {
        return Stream.value(const <String, UserProfile>{});
      }
      final ids = idsKey.split(',').where((s) => s.trim().isNotEmpty).toList();
      if (ids.isEmpty) {
        return Stream.value(const <String, UserProfile>{});
      }
      return repo.watchUsersByIds(ids);
    });

/// Normalized key for [addContactMatchedProfilesStreamProvider] (sorted, comma-separated).
String addContactMatchedProfilesProviderKey(Iterable<String> userIds) {
  final list = userIds.map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
    ..sort();
  return list.join(',');
}
