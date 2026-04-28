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
  );

  static String _keyForConversation(String conversationId) =>
      'lighchat.secretChat.pin.v1.$conversationId';

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

