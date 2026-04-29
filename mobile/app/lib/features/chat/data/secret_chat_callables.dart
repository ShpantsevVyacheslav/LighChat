import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

class SecretChatCallables {
  SecretChatCallables({String region = 'us-central1'})
    : _region = region,
      _functions = Platform.isIOS
          ? null
          : FirebaseFunctions.instanceFor(app: Firebase.app(), region: region);

  final String _region;
  final FirebaseFunctions? _functions;

  Future<Object?> _call(
    String name,
    Map<String, dynamic> data, {
    required Duration timeout,
  }) async {
    if (Platform.isIOS) {
      return callFirebaseCallableHttp(
        name: name,
        region: _region,
        data: data,
        timeout: timeout,
      );
    }

    final functions = _functions;
    if (functions == null) {
      throw StateError('FirebaseFunctions is not available on this platform');
    }
    final callable = functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: timeout),
    );
    final res = await callable.call<dynamic>(data);
    return res.data;
  }

  Future<void> setPin({required String pin}) async {
    await _call('setSecretChatPin', <String, dynamic>{
      'pin': pin,
    }, timeout: const Duration(seconds: 30));
  }

  Future<DateTime> unlock({
    required String conversationId,
    required String pin,
    String? deviceId,
    String method = 'pin',
  }) async {
    final data = await _call('unlockSecretChat', <String, dynamic>{
      'conversationId': conversationId,
      'pin': pin,
      if (deviceId != null && deviceId.trim().isNotEmpty)
        'deviceId': deviceId.trim(),
      'method': method,
    }, timeout: const Duration(seconds: 30));
    final m = data is Map ? data : const <Object?, Object?>{};
    final exp = m['expiresAt'];
    final iso = exp is String ? exp.trim() : '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) {
      throw StateError('unlockSecretChat bad response');
    }
    return dt.toUtc();
  }

  Future<void> updateSecretChatSettings({
    required String conversationId,
    int? ttlPresetSec,
    Map<String, Object?>? restrictions,
    Map<String, Object?>? mediaViewPolicy,
  }) async {
    final data = <String, dynamic>{'conversationId': conversationId};
    if (ttlPresetSec != null) data['ttlPresetSec'] = ttlPresetSec;
    if (restrictions != null) data['restrictions'] = restrictions;
    if (mediaViewPolicy != null) data['mediaViewPolicy'] = mediaViewPolicy;
    await _call(
      'updateSecretChatSettings',
      data,
      timeout: const Duration(seconds: 30),
    );
  }

  Future<bool> hasVaultPin() async {
    final data = await _call(
      'hasSecretVaultPin',
      <String, dynamic>{},
      timeout: const Duration(seconds: 15),
    );
    final m = data is Map ? data : const <Object?, Object?>{};
    final h = m['hasPin'];
    return h == true;
  }

  Future<void> verifyVaultPin({required String pin}) async {
    await _call('verifySecretVaultPin', <String, dynamic>{
      'pin': pin,
    }, timeout: const Duration(seconds: 30));
  }

  Future<void> deleteSecretChat({required String conversationId}) async {
    await _call('deleteSecretChat', <String, dynamic>{
      'conversationId': conversationId,
    }, timeout: const Duration(seconds: 120));
  }

  Future<void> requestSecretMediaView({
    required String conversationId,
    required String messageId,
    required String fileId,
    required String recipientDeviceId,
  }) async {
    await _call('requestSecretMediaView', <String, dynamic>{
      'conversationId': conversationId,
      'messageId': messageId,
      'fileId': fileId,
      'recipientDeviceId': recipientDeviceId,
    }, timeout: const Duration(seconds: 30));
  }

  Future<void> consumeSecretMediaKeyGrant({
    required String conversationId,
    required String messageId,
    required String fileId,
  }) async {
    await _call('consumeSecretMediaKeyGrant', <String, dynamic>{
      'conversationId': conversationId,
      'messageId': messageId,
      'fileId': fileId,
    }, timeout: const Duration(seconds: 30));
  }

  Future<void> fulfillSecretMediaViewRequest({
    required String conversationId,
    required String requestId,
    required String wrappedFileKeyForDevice,
  }) async {
    await _call('fulfillSecretMediaViewRequest', <String, dynamic>{
      'conversationId': conversationId,
      'requestId': requestId,
      'wrappedFileKeyForDevice': wrappedFileKeyForDevice,
    }, timeout: const Duration(seconds: 30));
  }
}
