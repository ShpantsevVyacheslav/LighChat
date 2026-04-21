/// Password-based backup приватного E2EE-ключа (mobile).
///
/// Зеркалит `src/lib/e2ee/v2/password-backup.ts`. Одинаковый формат документа
/// `users/{uid}/e2eeBackups/{backupId}`: любое устройство (веб или мобайл),
/// зная пароль, может расшифровать резерв.
///
/// KDF:
///  - Целевой Argon2id по RFC §5.2 требует native-dep (`argon2_ffi_base`),
///    который сейчас не установлен. Чтобы не блокировать рассыл фичи и не
///    расходиться по форматам с web, используем **PBKDF2-SHA256 / 600 000
///    итераций** через `pointycastle`. Совместимо с web fallback'ом.
///  - Поддержка `argon2id` будет добавлена отдельно — код уже ветвится по
///    `kdf.algorithm`, и оба формата сосуществуют в Firestore.
///
/// AAD: `lighchat/v2/backup|{userId}|{backupId}` — привязывает шифртекст к
/// владельцу и конкретному backupId, чтобы нельзя было скопировать backup-doc
/// из чужого аккаунта и подменить `userId`.
///
/// Модуль self-contained: не зависит от decryption-runtime, ничего не
/// импортирует из `mobile/app`. Юнит-тестируется с Firestore-моком.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pointycastle/export.dart';

import 'webcrypto_compat.dart';

/// Минимальная длина пароля. Совпадает с web (`E2EE_BACKUP_MIN_PASSWORD_LENGTH`).
const int e2eeBackupMinPasswordLength = 10;

const int _pbkdf2DefaultIterations = 600000;
const int _saltBytes = 16;
const int _ivBytes = 12;

/// Результат попытки восстановить backup. PKCS#8 — это ровно тот же формат,
/// что хранит в себе `device_identity.dart`, так что после восстановления
/// его можно перезаписать обратно через `replaceStoredIdentityFromBackup`
/// (вызывающий слой).
class RestoredMobileBackup {
  const RestoredMobileBackup({
    required this.backupId,
    required this.privateKeyPkcs8,
    required this.createdAt,
  });

  final String backupId;
  final Uint8List privateKeyPkcs8;
  final String createdAt;
}

/// KDF-параметры — синхронизированы с `E2eeBackupKdfParams` в TS.
class BackupKdfParams {
  const BackupKdfParams.pbkdf2Sha256({
    required this.saltB64,
    required this.iterations,
  })  : algorithm = 'pbkdf2-sha256',
        memKiB = null,
        parallelism = null;

  const BackupKdfParams.argon2id({
    required this.saltB64,
    required this.iterations,
    required int this.memKiB,
    required int this.parallelism,
  }) : algorithm = 'argon2id';

  final String algorithm;
  final String saltB64;
  final int iterations;
  final int? memKiB;
  final int? parallelism;

  Map<String, Object?> toJson() {
    if (algorithm == 'argon2id') {
      return <String, Object?>{
        'algorithm': algorithm,
        'saltB64': saltB64,
        'iterations': iterations,
        'memKiB': memKiB,
        'parallelism': parallelism,
      };
    }
    return <String, Object?>{
      'algorithm': algorithm,
      'saltB64': saltB64,
      'iterations': iterations,
    };
  }

  static BackupKdfParams fromJson(Map<String, Object?> json) {
    final algorithm = (json['algorithm'] as String?) ?? 'pbkdf2-sha256';
    if (algorithm == 'argon2id') {
      return BackupKdfParams.argon2id(
        saltB64: (json['saltB64'] as String?) ?? '',
        iterations: (json['iterations'] as num?)?.toInt() ?? 0,
        memKiB: (json['memKiB'] as num?)?.toInt() ?? 0,
        parallelism: (json['parallelism'] as num?)?.toInt() ?? 1,
      );
    }
    return BackupKdfParams.pbkdf2Sha256(
      saltB64: (json['saltB64'] as String?) ?? '',
      iterations: (json['iterations'] as num?)?.toInt() ?? _pbkdf2DefaultIterations,
    );
  }
}

/// Выводит 32-байтный ключ AES-256 из пароля.
Future<Uint8List> _deriveKdfKey(String password, BackupKdfParams kdf) async {
  if (kdf.algorithm == 'pbkdf2-sha256') {
    final salt = Uint8List.fromList(base64.decode(kdf.saltB64));
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, kdf.iterations, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }
  throw StateError('E2EE_BACKUP_ARGON2_NOT_AVAILABLE');
}

Uint8List _buildAad(String userId, String backupId) {
  return Uint8List.fromList(
    utf8.encode('lighchat/v2/backup|$userId|$backupId'),
  );
}

BackupKdfParams _defaultKdfParams() {
  return BackupKdfParams.pbkdf2Sha256(
    saltB64: base64.encode(randomBytes(_saltBytes)),
    iterations: _pbkdf2DefaultIterations,
  );
}

/// Шифрует приватник паролем и пишет backup-документ в Firestore.
/// Возвращает `backupId` (= переданному параметру, чтобы вызывающий мог
/// закэшировать ссылку).
Future<String> createMobilePasswordBackup({
  required FirebaseFirestore firestore,
  required String userId,
  required String backupId,
  required String password,
  required Uint8List privateKeyPkcs8,
  List<String>? allowedDeviceLabels,
  BackupKdfParams? kdf,
}) async {
  if (password.length < e2eeBackupMinPasswordLength) {
    throw StateError('E2EE_BACKUP_PASSWORD_TOO_SHORT');
  }
  final kdfParams = kdf ?? _defaultKdfParams();
  final keyBytes = await _deriveKdfKey(password, kdfParams);
  final iv = randomBytes(_ivBytes);
  final aad = _buildAad(userId, backupId);
  final ct = await aesGcmEncryptV2(
    key: keyBytes,
    iv: iv,
    plaintext: privateKeyPkcs8,
    aad: aad,
  );

  final payload = <String, Object?>{
    'backupId': backupId,
    'backupVersion': 1,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'kdf': kdfParams.toJson(),
    'aead': <String, Object?>{
      'algorithm': 'AES-GCM',
      'ivB64': base64.encode(iv),
      'ciphertextB64': base64.encode(ct),
    },
    'allowedDeviceLabels': ?allowedDeviceLabels,
  };

  await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeBackups')
      .doc(backupId)
      .set(payload);
  return backupId;
}

/// Пытается расшифровать любой backup пользователя данным паролем.
///
/// Обход всех документов сделан специально: у пользователя может быть
/// несколько backups (от разных устройств) и мы не знаем, под каким паролем
/// какой. Пробуем по очереди; первая успешная расшифровка возвращается.
///
/// Если ни один не подошёл — бросаем `E2EE_BACKUP_WRONG_PASSWORD` (либо
/// `E2EE_BACKUP_NOT_FOUND` если коллекция пуста).
Future<RestoredMobileBackup> restoreMobilePasswordBackup({
  required FirebaseFirestore firestore,
  required String userId,
  required String password,
}) async {
  final snap = await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeBackups')
      .get();
  if (snap.docs.isEmpty) {
    throw StateError('E2EE_BACKUP_NOT_FOUND');
  }
  for (final d in snap.docs) {
    final data = d.data();
    try {
      final kdfRaw = data['kdf'];
      if (kdfRaw is! Map) continue;
      final kdf = BackupKdfParams.fromJson(Map<String, Object?>.from(kdfRaw));
      final keyBytes = await _deriveKdfKey(password, kdf);
      final aead = data['aead'];
      if (aead is! Map) continue;
      final iv = Uint8List.fromList(base64.decode(aead['ivB64'] as String));
      final ct = Uint8List.fromList(base64.decode(aead['ciphertextB64'] as String));
      final backupId = (data['backupId'] as String?) ?? d.id;
      final aad = _buildAad(userId, backupId);
      final pt = await aesGcmDecryptV2(
        key: keyBytes,
        iv: iv,
        ciphertextPlusTag: ct,
        aad: aad,
      );
      final createdAt = (data['createdAt'] as String?) ?? '';
      return RestoredMobileBackup(
        backupId: backupId,
        privateKeyPkcs8: pt,
        createdAt: createdAt,
      );
    } catch (_) {
      continue;
    }
  }
  throw StateError('E2EE_BACKUP_WRONG_PASSWORD');
}

/// `true`, если у пользователя есть хотя бы один backup. UI использует для
/// UX-развилки "восстановить по паролю vs pairing QR".
Future<bool> hasAnyMobilePasswordBackup({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  final snap = await firestore
      .collection('users')
      .doc(userId)
      .collection('e2eeBackups')
      .limit(1)
      .get();
  return snap.docs.isNotEmpty;
}
