/// E2EE v2 device-identity layer для мобильного клиента.
///
/// Зеркалит `src/lib/e2ee/v2/device-identity-v2.ts`. Главные отличия:
///  - приватник хранится в **Keychain/Keystore** через `flutter_secure_storage`,
///    а не в IndexedDB (потому что на мобильных системах это единственное
///    защищённое хранилище);
///  - deviceId тоже лежит в secure-storage — мы используем его как стабильный
///    идентификатор устройства (логины/логауты его не сбрасывают);
///  - web→v1 миграции нет: на мобайле v1 никогда не использовался, так что мы
///    сразу стартуем с v2 (и свежим ключом).
///
/// Отдельный файл / отдельный модуль (user rule #1: isolation): этот код
/// ничего не знает про Firestore — публикация девайса вынесена в
/// `device_firestore.dart`, чтобы юнит-тестировать генерацию идентичности
/// без сетевого мока.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'webcrypto_compat.dart';

/// Единственный экземпляр secure-storage. Опции опционально ужесточают
/// требования к keychain: `first_unlock_this_device` гарантирует, что ключ
/// существует только на этом устройстве (Apple iCloud Keychain его не
/// синхронизирует) — важно, чтобы по device-id можно было уверенно
/// идентифицировать физический девайс.
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  // macOS: data-protection keychain требует keychain-access-groups
  // entitlement, который выдаётся только paid Apple Developer Program
  // (см. SecItemAdd -34018 ошибка в логах при ad-hoc / Personal Team
  // подписи). Переключаемся на legacy macOS keychain — он доступен
  // unsandboxed-приложениям без entitlement.
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    useDataProtectionKeyChain: false,
  ),
);

const String _kDeviceIdKey = 'lighchat.e2ee.v2.deviceId';
const String _kPrivateKeyPkcs8B64Key = 'lighchat.e2ee.v2.privateKeyPkcs8';
const String _kPublicKeySpkiB64Key = 'lighchat.e2ee.v2.publicKeySpki';
const String _kCreatedAtKey = 'lighchat.e2ee.v2.createdAt';

/// Материализованная identity после чтения / генерации.
///
/// `deviceId` стабилен между запусками. `keyPair` содержит и публичник, и
/// приватник в in-memory `cryptography` виде — прямо передаётся в
/// `webcrypto_compat` функции.
class MobileDeviceIdentityV2 {
  MobileDeviceIdentityV2({
    required this.deviceId,
    required this.keyPair,
    required this.publicKeySpkiB64,
  });

  final String deviceId;
  final EcdhP256KeyPair keyPair;
  final String publicKeySpkiB64;
}

/// Генерирует / читает identity для этого устройства. Идемпотентно: повторные
/// вызовы возвращают один и тот же `deviceId` и ключ.
///
/// Обработка edge-cases:
///  - если deviceId есть, но ключей нет (пользователь разлогинивался и
///    очистил KeyStore) — считаем identity «потерянной» и генерим новую.
///    Старые сообщения под прежним deviceId больше не расшифруются — это
///    ожидаемое поведение; восстановить их можно только через pairing/backup
///    (Phase 6).
///  - если ключи есть, но deviceId нет — тоже регенерим, т.к. рассогласованное
///    состояние потенциально опасно (могут существовать обёртки под device_X,
///    но мы не знаем, какой это X).
Future<MobileDeviceIdentityV2> getOrCreateMobileDeviceIdentity({
  FlutterSecureStorage storage = _secureStorage,
}) async {
  final deviceId = await storage.read(key: _kDeviceIdKey);
  final privB64 = await storage.read(key: _kPrivateKeyPkcs8B64Key);
  final pubB64 = await storage.read(key: _kPublicKeySpkiB64Key);

  final allPresent = deviceId != null &&
      deviceId.isNotEmpty &&
      privB64 != null &&
      privB64.isNotEmpty &&
      pubB64 != null &&
      pubB64.isNotEmpty;

  if (allPresent) {
    final pkcs8 = Uint8List.fromList(base64.decode(privB64));
    final keyPair = await importPkcs8P256(pkcs8: pkcs8);
    final expectedPub = base64.encode(await keyPair.exportSpkiPublic());
    if (expectedPub != pubB64) {
      // Мы поломаны (разошлись pub и priv) — это индикатор повреждения KeyStore.
      // Создаём новые ключи, но deviceId меняем тоже, чтобы не путать серверные
      // обёртки.
      return _freshIdentity(storage);
    }
    return MobileDeviceIdentityV2(
      deviceId: deviceId,
      keyPair: keyPair,
      publicKeySpkiB64: pubB64,
    );
  }

  // Частичное состояние → сброс + свежая identity.
  if ((deviceId != null && deviceId.isNotEmpty) ||
      (privB64 != null && privB64.isNotEmpty) ||
      (pubB64 != null && pubB64.isNotEmpty)) {
    await storage.delete(key: _kDeviceIdKey);
    await storage.delete(key: _kPrivateKeyPkcs8B64Key);
    await storage.delete(key: _kPublicKeySpkiB64Key);
    await storage.delete(key: _kCreatedAtKey);
  }
  return _freshIdentity(storage);
}

/// Полностью сбрасывает identity. Используется на logout / revoke-myself.
/// После вызова следующий `getOrCreateMobileDeviceIdentity` создаст
/// **новый** deviceId и новый keypair.
Future<void> clearMobileDeviceIdentity({
  FlutterSecureStorage storage = _secureStorage,
}) async {
  await storage.delete(key: _kDeviceIdKey);
  await storage.delete(key: _kPrivateKeyPkcs8B64Key);
  await storage.delete(key: _kPublicKeySpkiB64Key);
  await storage.delete(key: _kCreatedAtKey);
}

/// Перезаписывает identity на ту, что восстановлена из password-backup
/// или QR-pairing (см. Phase 6).
///
/// Важно: принимает и `privateKeyPkcs8`, и `publicKeySpki` отдельно,
/// потому что вызывающему (`e2ee_recovery_screen`) уже приходится
/// импортировать ключ из backup. Мы здесь не перепроверяем консистентность —
/// предполагаем, что вызывающий уже сделал это (`importPkcs8P256`
/// внутри проверяет, что публичник получается из приватника).
///
/// После вызова `getOrCreateMobileDeviceIdentity` вернёт этот же deviceId
/// с восстановленным ключом.
Future<void> replaceMobileDeviceIdentityFromBackup({
  required String deviceId,
  required Uint8List privateKeyPkcs8,
  required Uint8List publicKeySpki,
  FlutterSecureStorage storage = _secureStorage,
}) async {
  await storage.write(key: _kDeviceIdKey, value: deviceId);
  await storage.write(
    key: _kPrivateKeyPkcs8B64Key,
    value: base64.encode(privateKeyPkcs8),
  );
  await storage.write(
    key: _kPublicKeySpkiB64Key,
    value: base64.encode(publicKeySpki),
  );
  await storage.write(
    key: _kCreatedAtKey,
    value: DateTime.now().toUtc().toIso8601String(),
  );
}

Future<MobileDeviceIdentityV2> _freshIdentity(
  FlutterSecureStorage storage,
) async {
  final keyPair = await generateEcdhP256KeyPair();
  final privBytes = await keyPair.exportPkcs8Private();
  final pubBytes = await keyPair.exportSpkiPublic();
  final privB64 = base64.encode(privBytes);
  final pubB64 = base64.encode(pubBytes);
  final deviceId = _mobileUlid();
  await storage.write(key: _kDeviceIdKey, value: deviceId);
  await storage.write(key: _kPrivateKeyPkcs8B64Key, value: privB64);
  await storage.write(key: _kPublicKeySpkiB64Key, value: pubB64);
  await storage.write(
    key: _kCreatedAtKey,
    value: DateTime.now().toUtc().toIso8601String(),
  );
  return MobileDeviceIdentityV2(
    deviceId: deviceId,
    keyPair: keyPair,
    publicKeySpkiB64: pubB64,
  );
}

/// Лёгкий ULID-style идентификатор. 10 временных + 16 случайных символов в
/// base32-подобном алфавите. Не претендует на пересечение с Crockford-ULID,
/// но достаточно уникален для device-id и легко читается в логах.
String _mobileUlid() {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  final now = DateTime.now().millisecondsSinceEpoch;
  final timePart = StringBuffer();
  var t = now;
  for (var i = 0; i < 10; i++) {
    timePart.write(alphabet[t % 32]);
    t ~/= 32;
  }
  final reversedTime = timePart.toString().split('').reversed.join();
  final rnd = randomBytes(16);
  final randPart = StringBuffer();
  for (final b in rnd) {
    randPart.write(alphabet[b % 32]);
  }
  return '$reversedTime$randPart';
}

/// Вспомогательная структура для публикации. Мы избегаем зависимости от
/// `cloud_firestore` здесь, чтобы модуль оставался pure Dart.
class MobileDeviceBundle {
  MobileDeviceBundle({
    required this.deviceId,
    required this.publicKeySpkiB64,
    required this.platform,
  });

  final String deviceId;
  final String publicKeySpkiB64;
  final String platform;
}

/// Вытаскивает public-части для публикации наружу.
MobileDeviceBundle toPublishableBundle(
  MobileDeviceIdentityV2 identity, {
  required String platform,
}) {
  return MobileDeviceBundle(
    deviceId: identity.deviceId,
    publicKeySpkiB64: identity.publicKeySpkiB64,
    platform: platform,
  );
}
