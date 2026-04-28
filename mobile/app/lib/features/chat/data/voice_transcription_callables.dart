import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

import 'package:lighchat_firebase/src/firebase_callable_http.dart';

class VoiceTranscriptionResult {
  const VoiceTranscriptionResult({required this.transcript});
  final String transcript;
}

/// On-demand voice transcription.
///
/// Region matches CF deployment: `us-central1`.
class VoiceTranscriptionCallables {
  VoiceTranscriptionCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  Future<VoiceTranscriptionResult> transcribeVoiceMessage({
    required String conversationId,
    required String messageId,
    required String languageCode,
  }) async {
    // iOS: avoid `cloud_functions` plugin (FirebaseFunctions iOS SDK can crash/hang).
    // Use the same direct HTTPS callable protocol wrapper as `checkGroupInvitesAllowed`.
    if (Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'transcribeVoiceMessage',
        region: 'us-central1',
        data: <String, dynamic>{
          'conversationId': conversationId,
          'messageId': messageId,
          'languageCode': languageCode,
        },
        timeout: const Duration(seconds: 95),
      );
      final data = raw is Map ? raw : const <Object?, Object?>{};
      final t = (data['transcript'] ?? '').toString().trim();
      return VoiceTranscriptionResult(transcript: t);
    }

    final callable = _functions.httpsCallable(
      'transcribeVoiceMessage',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );
    final res = await callable.call<dynamic>(<String, Object?>{
      'conversationId': conversationId,
      'messageId': messageId,
      'languageCode': languageCode,
    });
    final raw = res.data;
    final data = raw is Map ? raw : const <Object?, Object?>{};
    final t = (data['transcript'] ?? '').toString().trim();
    return VoiceTranscriptionResult(transcript: t);
  }
}

