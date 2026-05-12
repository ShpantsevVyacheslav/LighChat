import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/platform_capabilities.dart';

/// Включён ли master-detail layout на десктопе.
///
/// Источник правды — `platformSettings/main.featureFlags.desktopWorkspaceLayout.enabled`
/// (управляется через [AdminFeatureFlagsScreen]). На mobile и web всегда
/// `false` — этот флаг ничего там не значит.
final Provider<bool> desktopWorkspaceFlagProvider = Provider<bool>((ref) {
  final caps = ref.watch(platformCapabilitiesProvider);
  if (!caps.isDesktop) return false;
  final snap = ref.watch(_platformSettingsSnapshotProvider).asData?.value;
  final data = snap?.data();
  if (data == null) return false;
  final flags = (data['featureFlags'] as Map?)?.cast<String, dynamic>();
  final flag = (flags?['desktopWorkspaceLayout'] as Map?)?.cast<String, dynamic>();
  return flag?['enabled'] == true;
});

final StreamProvider<DocumentSnapshot<Map<String, dynamic>>>
    _platformSettingsSnapshotProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance.doc('platformSettings/main').snapshots();
});
