import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretChatPinDeviceStorage {
  const SecretChatPinDeviceStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  final FlutterSecureStorage _storage;

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    // macOS Debug без paid Apple Developer ID не имеет
    // keychain-access-groups entitlement; data-protection keychain
    // вернёт SecItemAdd -34018. Падаем на legacy keychain.
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      useDataProtectionKeyChain: false,
    ),
  );

  static String _keyForConversation(String conversationId) =>
      'lighchat.secretChat.pin.v1.$conversationId';

  static const _vaultKey = 'lighchat.secretVault.pin.v1';

  Future<void> saveVaultPin(String pin) async {
    await _storage.write(key: _vaultKey, value: pin);
  }

  Future<String?> readVaultPin() async {
    final v = await _storage.read(key: _vaultKey);
    final t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<void> clearVaultPin() async {
    await _storage.delete(key: _vaultKey);
  }

  Future<void> savePin({
    required String conversationId,
    required String pin,
  }) async {
    await _storage.write(key: _keyForConversation(conversationId), value: pin);
  }

  Future<String?> readPin({required String conversationId}) async {
    final v = await _storage.read(key: _keyForConversation(conversationId));
    final t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<void> clearPin({required String conversationId}) async {
    await _storage.delete(key: _keyForConversation(conversationId));
  }
}

