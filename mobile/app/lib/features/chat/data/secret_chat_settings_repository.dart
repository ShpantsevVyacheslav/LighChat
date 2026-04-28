import 'package:lighchat_models/lighchat_models.dart';

import 'secret_chat_callables.dart';

class SecretChatSettingsRepository {
  SecretChatSettingsRepository({SecretChatCallables? callables})
      : _callables = callables ?? SecretChatCallables();

  final SecretChatCallables _callables;

  Future<void> updateTtlPreset({
    required String conversationId,
    required int ttlPresetSec,
  }) async {
    if (ttlPresetSec <= 0) {
      throw ArgumentError('ttlPresetSec must be positive');
    }
    await _callables.updateSecretChatSettings(
      conversationId: conversationId,
      ttlPresetSec: ttlPresetSec,
    );
  }

  Future<void> updateRestrictions({
    required String conversationId,
    required SecretChatRestrictions restrictions,
  }) async {
    await _callables.updateSecretChatSettings(
      conversationId: conversationId,
      restrictions: <String, Object?>{
        'noForward': restrictions.noForward,
        'noCopy': restrictions.noCopy,
        'noSave': restrictions.noSave,
        'screenshotProtection': restrictions.screenshotProtection,
      },
    );
  }

  Future<void> updateMediaViewPolicy({
    required String conversationId,
    required SecretChatMediaViewPolicy? policy,
  }) async {
    await _callables.updateSecretChatSettings(
      conversationId: conversationId,
      mediaViewPolicy: policy == null
          ? <String, Object?>{'__clear': true}
          : <String, Object?>{
              'image': policy.image,
              'video': policy.video,
              'voice': policy.voice,
              'file': policy.file,
              'location': policy.location,
            },
    );
  }

  Future<void> updateGrantTtlSec({
    required String conversationId,
    required int grantTtlSec,
  }) async {
    if (grantTtlSec <= 0) {
      throw ArgumentError('grantTtlSec must be positive');
    }
    await _callables.updateSecretChatSettings(
      conversationId: conversationId,
      grantTtlSec: grantTtlSec,
    );
  }

  Future<void> resetToStrictDefaults({
    required String conversationId,
  }) async {
    await _callables.updateSecretChatSettings(
      conversationId: conversationId,
      grantTtlSec: 600,
      restrictions: <String, Object?>{
        'noForward': true,
        'noCopy': true,
        'noSave': true,
        'screenshotProtection': true,
      },
      mediaViewPolicy: <String, Object?>{
        'image': 1,
        'video': 1,
        'voice': 1,
        'file': null,
        'location': 1,
      },
    );
  }
}

