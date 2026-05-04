import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import '../../../l10n/app_localizations.dart';
import 'package:lighchat_firebase/src/registration/registration_keys.dart';
import 'package:lighchat_firebase/src/registration/registration_models.dart';

class ProfileUpdateData {
  const ProfileUpdateData({
    required this.name,
    required this.username,
    required this.email,
    required this.phoneE164,
    required this.dateOfBirth,
    required this.bio,
    required this.avatarFullJpeg,
    required this.avatarThumbPng,
  });

  final String name;
  final String username;
  final String email;
  final String phoneE164;
  final String? dateOfBirth;
  final String? bio;
  final List<int>? avatarFullJpeg;
  final List<int>? avatarThumbPng;
}

Future<void> updateUserProfile({
  required String uid,
  required ProfileUpdateData data,
  required ProfileUpdateData initial,
  FirebaseFirestore? firestore,
  FirebaseStorage? storage,
  AppLocalizations? l10n,
}) async {
  final fs = firestore ?? FirebaseFirestore.instance;
  final st = storage ?? FirebaseStorage.instance;

  final email = data.email.trim().toLowerCase();
  final username = data.username.trim();
  final phone = data.phoneE164.trim();

  final initialEmail = initial.email.trim().toLowerCase();
  final initialUsername = initial.username.trim();
  final initialPhone = initial.phoneE164.trim();

  final emailChanged = email != initialEmail;
  final usernameChanged = username != initialUsername;
  final phoneChanged = phone != initialPhone;

  Future<void> checkKeyAvailable({
    required String field,
    required String? key,
  }) async {
    if (key == null) return;
    final snap = await fs.collection('registrationIndex').doc(key).get();
    if (!snap.exists) return;
    final owner = snap.data()?['uid'] as String?;
    if (owner == uid) return;
    // If owner is null/empty or belongs to another uid, treat as taken.
    throw RegistrationConflict(
      field: field,
      message: field == 'phone'
          ? (l10n?.profile_conflict_phone ?? 'This phone number is already registered. Please use a different number.')
          : field == 'email'
          ? (l10n?.profile_conflict_email ?? 'This email is already taken. Please use a different address.')
          : (l10n?.profile_conflict_username ?? 'This username is already taken. Please choose a different one.'),
    );
  }

  if (emailChanged) {
    await checkKeyAvailable(field: 'email', key: registrationEmailKey(email));
  }
  if (phoneChanged) {
    await checkKeyAvailable(field: 'phone', key: registrationPhoneKey(phone));
  }
  if (usernameChanged) {
    await checkKeyAvailable(
      field: 'username',
      key: registrationUsernameKey(username),
    );
  }

  String? avatarUrl;
  String? avatarThumbUrl;

  if (data.avatarFullJpeg != null) {
    final fullRef = st.ref('users/$uid/avatar_full.jpg');
    await fullRef.putData(
      Uint8List.fromList(data.avatarFullJpeg!),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    avatarUrl = await fullRef.getDownloadURL();
  }

  if (data.avatarThumbPng != null) {
    final thumbRef = st.ref('users/$uid/avatar_thumb.png');
    await thumbRef.putData(
      Uint8List.fromList(data.avatarThumbPng!),
      SettableMetadata(contentType: 'image/png'),
    );
    avatarThumbUrl = await thumbRef.getDownloadURL();
  }

  final updates = <String, Object?>{
    'name': data.name.trim(),
    'username': username,
    if (emailChanged) 'email': email,
    if (phoneChanged) 'phone': phone,
    if (data.bio?.trim().isNotEmpty ?? false) 'bio': data.bio!.trim() else 'bio': null,
    if (data.dateOfBirth?.trim().isNotEmpty ?? false)
      'dateOfBirth': data.dateOfBirth!.trim()
    else
      'dateOfBirth': null,
    if (avatarUrl != null) 'avatar': avatarUrl,
    if (avatarThumbUrl != null) 'avatarThumb': avatarThumbUrl,
  };

  await fs.collection('users').doc(uid).set(updates, SetOptions(merge: true));

  // Best-effort registrationIndex updates for changed identity fields.
  try {
    final batch = fs.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    if (emailChanged) {
      final key = registrationEmailKey(email);
      if (key != null) {
        batch.set(
          fs.collection('registrationIndex').doc(key),
          <String, Object?>{
            'uid': uid,
            'type': 'email',
            'value': email,
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }
    }
    if (phoneChanged) {
      final key = registrationPhoneKey(phone);
      if (key != null) {
        batch.set(
          fs.collection('registrationIndex').doc(key),
          <String, Object?>{
            'uid': uid,
            'type': 'phone',
            'value': phone,
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }
    }
    if (usernameChanged) {
      final key = registrationUsernameKey(username);
      if (key != null) {
        batch.set(
          fs.collection('registrationIndex').doc(key),
          <String, Object?>{
            'uid': uid,
            'type': 'username',
            'value': username.replaceFirst(RegExp(r'^@'), '').toLowerCase(),
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
  } catch (e) {
    developer.log(
      'Profile update: failed to update registrationIndex (expected when rules deny client writes).',
      name: 'lighchat.profile',
      error: e,
    );
  }
}

