import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

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

