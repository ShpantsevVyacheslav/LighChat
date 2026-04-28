import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import '../data/user_profiles_repository.dart';

class DurakPlayerNames extends StatelessWidget {
  const DurakPlayerNames({
    super.key,
    required this.uids,
    required this.builder,
  });

  final List<String> uids;
  final Widget Function(BuildContext context, Map<String, String> nameByUid) builder;

  String _fallback(String uid) {
    if (uid.isEmpty) return '—';
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 4)}…${uid.substring(uid.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final ids = uids.where((s) => s.trim().isNotEmpty).toSet().toList();
    ids.sort();

    return StreamBuilder<Map<String, UserProfile>>(
      stream: UserProfilesRepository().watchUsersByIds(ids),
      builder: (context, snap) {
        final profiles = snap.data ?? const <String, UserProfile>{};
        final names = <String, String>{};
        for (final uid in ids) {
          final p = profiles[uid];
          names[uid] = p?.name ?? _fallback(uid);
        }
        return builder(context, Map.unmodifiable(names));
      },
    );
  }
}

