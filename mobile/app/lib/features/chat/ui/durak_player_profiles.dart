import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import '../data/user_profiles_repository.dart';

class DurakPlayerProfiles extends StatelessWidget {
  const DurakPlayerProfiles({
    super.key,
    required this.uids,
    required this.builder,
  });

  final List<String> uids;
  final Widget Function(BuildContext context, Map<String, UserProfile> byUid) builder;

  @override
  Widget build(BuildContext context) {
    final ids = uids.where((s) => s.trim().isNotEmpty).toSet().toList()..sort();
    return StreamBuilder<Map<String, UserProfile>>(
      stream: UserProfilesRepository().watchUsersByIds(ids),
      builder: (context, snap) {
        return builder(context, snap.data ?? const <String, UserProfile>{});
      },
    );
  }
}

