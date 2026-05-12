import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Роль пользователя в системе.
enum AppUserRole {
  /// Обычный пользователь — не имеет доступа к admin/moderation.
  user,

  /// Модератор — доступ к moderation queue + announcements (без user mgmt).
  worker,

  /// Полный админ — все секции включая user management.
  admin;

  static AppUserRole fromRaw(Object? raw) {
    if (raw is! String) return AppUserRole.user;
    switch (raw.toLowerCase()) {
      case 'admin':
        return AppUserRole.admin;
      case 'worker':
      case 'moderator':
        return AppUserRole.worker;
      default:
        return AppUserRole.user;
    }
  }

  bool get canAccessAdmin =>
      this == AppUserRole.admin || this == AppUserRole.worker;

  bool get canManageUsers => this == AppUserRole.admin;

  bool get canModerateContent =>
      this == AppUserRole.admin || this == AppUserRole.worker;
}

/// Поток ролей текущего авторизованного пользователя. Меняется при логине,
/// логауте или обновлении документа `users/{uid}` (поле `role`).
final StreamProvider<AppUserRole> userRoleProvider =
    StreamProvider<AppUserRole>((ref) async* {
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    if (user == null) {
      yield AppUserRole.user;
      continue;
    }
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    yield* docRef.snapshots().map(
          (snap) => AppUserRole.fromRaw(snap.data()?['role']),
        );
  }
});
