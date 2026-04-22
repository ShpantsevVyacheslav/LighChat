import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:lighchat_firebase/lighchat_firebase.dart';

/// Таймаут одного чтения `users/{uid}` — без него при «зависшей» сети UI остаётся на [CircularProgressIndicator].
const Duration kFirestoreRegistrationGetTimeout = Duration(seconds: 15);

enum RegistrationProfileStatus { complete, incomplete, unknown }

String? googleRouteFromProfileStatus(RegistrationProfileStatus status) {
  switch (status) {
    case RegistrationProfileStatus.complete:
      return '/chats';
    case RegistrationProfileStatus.incomplete:
      return '/auth/google-complete';
    case RegistrationProfileStatus.unknown:
      return null;
  }
}

String googleRouteFromProfileComplete(bool complete) {
  return complete ? '/chats' : '/auth/google-complete';
}

Future<RegistrationProfileStatus>
getFirestoreRegistrationProfileStatusWithDeadline(
  auth.User firebaseUser, {
  Duration deadline = const Duration(seconds: 10),
}) {
  return Future.any<RegistrationProfileStatus>([
    () async {
      try {
        return await getFirestoreRegistrationProfileStatus(firebaseUser);
      } catch (e, st) {
        log(
          'getFirestoreRegistrationProfileStatus failed',
          name: 'registration_profile_gate',
          error: e,
          stackTrace: st,
        );
        return RegistrationProfileStatus.unknown;
      }
    }(),
    Future<RegistrationProfileStatus>.delayed(deadline, () {
      log(
        'registration profile status deadline ($deadline)',
        name: 'registration_profile_gate',
      );
      return RegistrationProfileStatus.unknown;
    }),
  ]);
}

/// Проверка «регистрация завершена» по `users/{uid}` с учётом кэша Firestore (паритет с web `use-auth`).
///
/// 1) Обычный [DocumentReference.get] (кэш → сервер).
/// 2) Если неполно и вход через Google или Apple — повтор с [Source.server], как web `getDocFromServer`.
/// 3) Email из документа, иначе из Firebase Auth (часто актуально сразу после OAuth Sign-In).
/// Жёсткий предел ожидания проверки профиля (нативный Firestore иногда не завершает [get],
/// и тогда даже [Future.timeout] на Dart-стороне не срабатывает как ожидается).
Future<bool> isFirestoreRegistrationProfileCompleteWithDeadline(
  auth.User firebaseUser, {
  Duration deadline = const Duration(seconds: 10),
}) {
  return getFirestoreRegistrationProfileStatusWithDeadline(
    firebaseUser,
    deadline: deadline,
  ).then((s) => s == RegistrationProfileStatus.complete);
}

Future<bool> isFirestoreRegistrationProfileComplete(
  auth.User firebaseUser,
) async {
  final status = await getFirestoreRegistrationProfileStatus(firebaseUser);
  return status == RegistrationProfileStatus.complete;
}

Future<RegistrationProfileStatus> getFirestoreRegistrationProfileStatus(
  auth.User firebaseUser,
) async {
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid);
  final isTelegramUid = RegExp(r'^tg_\d+$').hasMatch(firebaseUser.uid);
  final isOauthSocial = firebaseUser.providerData.any(
        (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
      ) ||
      isTelegramUid;

  String asTrimmedString(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is num || raw is bool) return raw.toString().trim();
    return '';
  }

  RegistrationProfileStatus evaluate(Map<String, dynamic>? data) {
    try {
      if (data == null) return RegistrationProfileStatus.incomplete;
      final docEmail = asTrimmedString(data['email']);
      final authEmail = firebaseUser.email?.trim();
      final email = docEmail.isNotEmpty ? docEmail : (authEmail ?? '');
      final name = asTrimmedString(data['name']);
      final username = asTrimmedString(data['username']);
      final phone = asTrimmedString(data['phone']);
      final complete = isRegistrationProfileComplete(
        name: name,
        username: username,
        phone: phone,
        email: email,
      );
      if (complete) return RegistrationProfileStatus.complete;
      {
        final normalizedUsername = username
            .trim()
            .replaceFirst(RegExp(r'^@'), '')
            .toLowerCase();
        final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
        log(
          'profile incomplete (missing_required_field): nameLen=${name.trim().length}, '
          'usernameLen=${normalizedUsername.length}, '
          'phoneDigits=${phoneDigits.length}, '
          'hasEmail=${email.trim().isNotEmpty}, '
          'emailSource=${docEmail.isNotEmpty ? 'doc' : 'auth'}',
          name: 'registration_profile_gate',
        );
      }
      return RegistrationProfileStatus.incomplete;
    } catch (e, st) {
      log(
        'evaluate(users doc) failed',
        name: 'registration_profile_gate',
        error: e,
        stackTrace: st,
      );
      return RegistrationProfileStatus.unknown;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> timedGet([
    GetOptions? options,
  ]) {
    final future = options == null ? docRef.get() : docRef.get(options);
    return future.timeout(kFirestoreRegistrationGetTimeout);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> timedGetWithOauthAuthRefresh([
    GetOptions? options,
  ]) async {
    try {
      return await timedGet(options);
    } on FirebaseException catch (e, st) {
      if (!isOauthSocial || e.code != 'permission-denied') rethrow;
      log(
        'users/${firebaseUser.uid} get() permission-denied, refreshing token and retrying',
        name: 'registration_profile_gate',
        error: e,
        stackTrace: st,
      );
      try {
        await firebaseUser.reload();
      } catch (_) {
        // no-op: token refresh below is still useful.
      }
      await firebaseUser.getIdToken(true);
      return timedGet(options);
    }
  }

  var hasDeterministicIncomplete = false;

  try {
    final snap = await timedGetWithOauthAuthRefresh();
    final status = evaluate(snap.data());
    if (status == RegistrationProfileStatus.complete) return status;
    if (status == RegistrationProfileStatus.incomplete) {
      hasDeterministicIncomplete = true;
    }
  } on TimeoutException catch (e, st) {
    log(
      'users/${firebaseUser.uid} get() timed out (cache/default, firestore_timeout)',
      name: 'registration_profile_gate',
      error: e,
      stackTrace: st,
    );
  } on FirebaseException catch (e, st) {
    log(
      'users/${firebaseUser.uid} get() firebase error (${e.code})',
      name: 'registration_profile_gate',
      error: e,
      stackTrace: st,
    );
  } catch (e, st) {
    log(
      'users/${firebaseUser.uid} get() unknown error',
      name: 'registration_profile_gate',
      error: e,
      stackTrace: st,
    );
  }

  if (isOauthSocial) {
    try {
      final snap = await timedGetWithOauthAuthRefresh(
        const GetOptions(source: Source.server),
      );
      final status = evaluate(snap.data());
      if (status == RegistrationProfileStatus.complete) return status;
      if (status == RegistrationProfileStatus.incomplete) {
        hasDeterministicIncomplete = true;
      }
    } on TimeoutException catch (e, st) {
      log(
        'users/${firebaseUser.uid} get(server) timed out (firestore_timeout)',
        name: 'registration_profile_gate',
        error: e,
        stackTrace: st,
      );
    } on FirebaseException catch (e, st) {
      log(
        'users/${firebaseUser.uid} get(server) firebase error (${e.code})',
        name: 'registration_profile_gate',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      log(
        'users/${firebaseUser.uid} get(server) unknown error',
        name: 'registration_profile_gate',
        error: e,
        stackTrace: st,
      );
    }
  }

  if (hasDeterministicIncomplete) {
    log(
      'registration profile status=incomplete for uid=${firebaseUser.uid}',
      name: 'registration_profile_gate',
    );
    return RegistrationProfileStatus.incomplete;
  }

  log(
    'registration profile status=unknown for uid=${firebaseUser.uid}',
    name: 'registration_profile_gate',
  );

  return RegistrationProfileStatus.unknown;
}
