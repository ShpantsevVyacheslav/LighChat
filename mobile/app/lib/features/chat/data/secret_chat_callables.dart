import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class SecretChatCallables {
  SecretChatCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  Future<void> setPin({required String pin}) async {
    final callable = _functions.httpsCallable(
      'setSecretChatPin',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>(<String, Object?>{'pin': pin});
  }

  Future<DateTime> unlock({
    required String conversationId,
    required String pin,
    String? deviceId,
    String method = 'pin',
  }) async {
    final callable = _functions.httpsCallable(
      'unlockSecretChat',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final res = await callable.call<Map<Object?, Object?>>(<String, Object?>{
      'conversationId': conversationId,
      'pin': pin,
      if (deviceId != null && deviceId.trim().isNotEmpty) 'deviceId': deviceId.trim(),
      'method': method,
    });
    final data = res.data;
    final exp = data['expiresAt'];
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
    int? grantTtlSec,
    Map<String, Object?>? restrictions,
    Map<String, Object?>? mediaViewPolicy,
  }) async {
    final callable = _functions.httpsCallable(
      'updateSecretChatSettings',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>(<String, Object?>{
      'conversationId': conversationId,
      if (ttlPresetSec != null) 'ttlPresetSec': ttlPresetSec,
      if (grantTtlSec != null) 'grantTtlSec': grantTtlSec,
      if (restrictions != null) 'restrictions': restrictions,
      if (mediaViewPolicy != null) 'mediaViewPolicy': mediaViewPolicy,
    });
  }

  Future<void> requestSecretMediaView({
    required String conversationId,
    required String messageId,
    required String fileId,
    required String recipientDeviceId,
  }) async {
    final callable = _functions.httpsCallable(
      'requestSecretMediaView',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>(<String, Object?>{
      'conversationId': conversationId,
      'messageId': messageId,
      'fileId': fileId,
      'recipientDeviceId': recipientDeviceId,
    });
  }

  Future<void> consumeSecretMediaKeyGrant({
    required String conversationId,
    required String messageId,
    required String fileId,
  }) async {
    final callable = _functions.httpsCallable(
      'consumeSecretMediaKeyGrant',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>(<String, Object?>{
      'conversationId': conversationId,
      'messageId': messageId,
      'fileId': fileId,
    });
  }

  Future<void> fulfillSecretMediaViewRequest({
    required String conversationId,
    required String requestId,
    required String wrappedFileKeyForDevice,
  }) async {
    final callable = _functions.httpsCallable(
      'fulfillSecretMediaViewRequest',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>(<String, Object?>{
      'conversationId': conversationId,
      'requestId': requestId,
      'wrappedFileKeyForDevice': wrappedFileKeyForDevice,
    });
  }
}

