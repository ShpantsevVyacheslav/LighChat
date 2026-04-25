import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;

import '../auth_errors.dart';
import 'registration_availability.dart';
import 'registration_keys.dart';
import 'registration_models.dart';

class RegistrationService {
  RegistrationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> register(RegistrationData data) async {
    final email = data.email.trim().toLowerCase();
    final username = data.username.trim();
    final phone = data.phone;

    // 1) Pre-check availability via registrationIndex (mirrors web).
    final emailKey = registrationEmailKey(email);
    final phoneKey = registrationPhoneKey(phone);
    final usernameKey = registrationUsernameKey(username);

    if (await isRegistrationEmailTaken(firestore: _firestore, key: emailKey)) {
      throw RegistrationConflict(
        field: 'email',
        message: 'Этот email уже занят. Укажите другой адрес.',
      );
    }
    if (await isRegistrationPhoneTaken(firestore: _firestore, key: phoneKey)) {
      throw RegistrationConflict(
        field: 'phone',
        message: 'Этот номер телефона уже зарегистрирован. Укажите другой номер.',
      );
    }
    if (await isRegistrationUsernameTaken(
      firestore: _firestore,
      key: usernameKey,
    )) {
      throw RegistrationConflict(
        field: 'username',
        message: 'Этот логин уже занят. Выберите другой.',
      );
    }

    // 2) Create Firebase Auth user.
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: data.password,
      );
    } catch (e) {
      // Surface Firebase auth errors as user-friendly messages.
      throw Exception(friendlyAuthError(e));
    }

    final uid = cred.user?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Не удалось создать пользователя (uid отсутствует).');
    }

    // 3) Upload avatar (optional).
    String avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uid';
    String? avatarThumbUrl;

    if (data.avatarFullJpeg != null) {
      final fullRef = _storage.ref('users/$uid/avatar_full.jpg');
      await fullRef.putData(
        Uint8List.fromList(data.avatarFullJpeg!),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      avatarUrl = await fullRef.getDownloadURL();
    }

    if (data.avatarThumbPng != null) {
      final thumbRef = _storage.ref('users/$uid/avatar_thumb.png');
      await thumbRef.putData(
        Uint8List.fromList(data.avatarThumbPng!),
        SettableMetadata(contentType: 'image/png'),
      );
      avatarThumbUrl = await thumbRef.getDownloadURL();
    }

    // 4) Write users/{uid}.
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final userDoc = <String, Object?>{
      'id': uid,
      'name': data.name.trim(),
      'username': data.username.trim(),
      'email': email,
      'phone': phone,
      'avatar': avatarUrl,
      'avatarThumb': avatarThumbUrl,
      'deletedAt': null,
      'createdAt': nowIso,
      if (data.bio?.trim().isNotEmpty ?? false) 'bio': data.bio!.trim(),
      if (data.dateOfBirth?.trim().isNotEmpty ?? false) 'dateOfBirth': data.dateOfBirth!.trim(),
    };
    await _firestore.collection('users').doc(uid).set(userDoc, SetOptions(merge: true));

    // 5) Write registrationIndex docs (best-effort; if blocked by rules, surface clearly).
    try {
      final batch = _firestore.batch();
      if (emailKey != null) {
        batch.set(
          _firestore.collection('registrationIndex').doc(emailKey),
          <String, Object?>{'uid': uid, 'type': 'email', 'value': email, 'updatedAt': nowIso},
          SetOptions(merge: true),
        );
      }
      if (phoneKey != null) {
        batch.set(
          _firestore.collection('registrationIndex').doc(phoneKey),
          <String, Object?>{'uid': uid, 'type': 'phone', 'value': phone, 'updatedAt': nowIso},
          SetOptions(merge: true),
        );
      }
      if (usernameKey != null) {
        batch.set(
          _firestore.collection('registrationIndex').doc(usernameKey),
          <String, Object?>{
            'uid': uid,
            'type': 'username',
            'value': data.username.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase(),
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e) {
      // `registrationIndex/*` is server-write only (Admin SDK / Cloud Functions).
      // Do not fail the registration flow if client rules block this write.
      developer.log(
        'Registration: failed to write registrationIndex (expected when rules deny client writes).',
        name: 'lighchat.registration',
        error: e,
      );
    }
  }

  /// After Google sign-in, complete profile and ensure registrationIndex is consistent.
  Future<void> completeGoogleProfile({
    required String uid,
    required GoogleProfileCompletionData data,
  }) async {
    final email = data.email.trim().toLowerCase();
    final username = data.username.trim();
    final phone = data.phone;

    final emailKey = registrationEmailKey(email);
    final phoneKey = registrationPhoneKey(phone);
    final usernameKey = registrationUsernameKey(username);

    if (await isRegistrationEmailTaken(
      firestore: _firestore,
      key: emailKey,
      exceptUid: uid,
    )) {
      throw RegistrationConflict(
        field: 'email',
        message: 'Этот email уже занят. Укажите другой адрес.',
      );
    }
    if (await isRegistrationPhoneTaken(
      firestore: _firestore,
      key: phoneKey,
      exceptUid: uid,
    )) {
      throw RegistrationConflict(
        field: 'phone',
        message: 'Этот номер телефона уже зарегистрирован. Укажите другой номер.',
      );
    }
    if (await isRegistrationUsernameTaken(
      firestore: _firestore,
      key: usernameKey,
      exceptUid: uid,
    )) {
      throw RegistrationConflict(
        field: 'username',
        message: 'Этот логин уже занят. Выберите другой.',
      );
    }

    String avatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uid';
    String? avatarThumbUrl;

    if (data.avatarFullJpeg != null) {
      final fullRef = _storage.ref('users/$uid/avatar_full.jpg');
      await fullRef.putData(
        Uint8List.fromList(data.avatarFullJpeg!),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      avatarUrl = await fullRef.getDownloadURL();
    } else {
      // Keep existing avatar if present.
      final existing = await _firestore.collection('users').doc(uid).get();
      final v = existing.data()?['avatar'];
      if (v is String && v.trim().isNotEmpty) avatarUrl = v;
    }

    if (data.avatarThumbPng != null) {
      final thumbRef = _storage.ref('users/$uid/avatar_thumb.png');
      await thumbRef.putData(
        Uint8List.fromList(data.avatarThumbPng!),
        SettableMetadata(contentType: 'image/png'),
      );
      avatarThumbUrl = await thumbRef.getDownloadURL();
    } else {
      final existing = await _firestore.collection('users').doc(uid).get();
      final v = existing.data()?['avatarThumb'];
      if (v is String && v.trim().isNotEmpty) avatarThumbUrl = v;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final userDoc = <String, Object?>{
      'id': uid,
      'name': data.name.trim(),
      'username': data.username.trim(),
      'email': email,
      'phone': phone,
      'avatar': avatarUrl,
      'avatarThumb': avatarThumbUrl,
      if (data.bio?.trim().isNotEmpty ?? false) 'bio': data.bio!.trim(),
      if (data.dateOfBirth?.trim().isNotEmpty ?? false)
        'dateOfBirth': data.dateOfBirth!.trim(),
    };
    await _firestore.collection('users').doc(uid).set(userDoc, SetOptions(merge: true));

    final batch = _firestore.batch();
    if (emailKey != null) {
      batch.set(
        _firestore.collection('registrationIndex').doc(emailKey),
        <String, Object?>{'uid': uid, 'type': 'email', 'value': email, 'updatedAt': nowIso},
        SetOptions(merge: true),
      );
    }
    if (phoneKey != null) {
      batch.set(
        _firestore.collection('registrationIndex').doc(phoneKey),
        <String, Object?>{'uid': uid, 'type': 'phone', 'value': phone, 'updatedAt': nowIso},
        SetOptions(merge: true),
      );
    }
    if (usernameKey != null) {
      batch.set(
        _firestore.collection('registrationIndex').doc(usernameKey),
        <String, Object?>{
          'uid': uid,
          'type': 'username',
          'value': data.username.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase(),
          'updatedAt': nowIso,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}

