import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'e2ee_plaintext_cache.dart';
import 'e2ee_runtime.dart';
import 'secret_chat_callables.dart';

/// Resolves a locked Secret Chat E2EE attachment by requesting a server-enforced
/// view grant, receiving a wrapped per-file key, downloading ciphertext from
/// Storage, and decrypting locally.
class SecretChatMediaOpenService {
  const SecretChatMediaOpenService();

  static const String lockedScheme = 'lighchat-secret-media';

  static bool isLockedSecretAttachment(ChatAttachment a) {
    final uri = Uri.tryParse(a.url);
    return uri != null && uri.scheme == lockedScheme;
  }

  static ({String messageId, String fileId})? parseLockedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != lockedScheme) return null;
    final seg = uri.pathSegments;
    if (seg.length < 2) return null;
    final messageId = seg[0];
    final fileId = seg[1];
    if (messageId.isEmpty || fileId.isEmpty) return null;
    return (messageId: messageId, fileId: fileId);
  }

  static String buildLockedUrl({
    required String messageId,
    required String fileId,
  }) {
    return Uri(
      scheme: lockedScheme,
      pathSegments: [messageId, fileId],
    ).toString();
  }

  static String _wrapContextEpochId({
    required String conversationId,
    required String messageId,
    required String fileId,
  }) {
    return 'scmv|$conversationId|$messageId|$fileId';
  }

  Future<ChatAttachment> openForView({
    required MobileE2eeRuntime runtime,
    required String conversationId,
    required ChatMessage message,
    required ChatAttachment lockedAttachment,
  }) async {
    final parsed = parseLockedUrl(lockedAttachment.url);
    if (parsed == null) {
      throw StateError('SECRET_MEDIA_BAD_URL');
    }
    final messageId = parsed.messageId;
    final fileId = parsed.fileId;

    final payload = message.e2eePayload;
    final attachmentsJson = payload?.attachmentsJson;
    if (payload == null || attachmentsJson == null || attachmentsJson.isEmpty) {
      throw StateError('SECRET_MEDIA_NO_E2EE_PAYLOAD');
    }

    MediaEnvelopeV2? env;
    for (final j in attachmentsJson) {
      try {
        final parsedEnv = MediaEnvelopeV2.fromWireJson(j);
        if (parsedEnv.fileId == fileId) {
          env = parsedEnv;
          break;
        }
      } catch (_) {
        // ignore malformed envelope slots
      }
    }
    if (env == null) throw StateError('SECRET_MEDIA_ENVELOPE_NOT_FOUND');

    final identity = await runtime.ensureIdentity();
    final callables = SecretChatCallables();

    await callables.requestSecretMediaView(
      conversationId: conversationId,
      messageId: messageId,
      fileId: fileId,
      recipientDeviceId: identity.deviceId,
    );

    final grantId = '${runtime.userId}__${messageId}__${fileId}';
    final grantRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('secretMediaKeyGrants')
        .doc(grantId);

    final snap = await grantRef
        .snapshots()
        .where((s) => s.exists)
        .first
        .timeout(const Duration(seconds: 35));

    final data = snap.data() ?? const <String, Object?>{};
    final wrappedStr = data['wrappedFileKeyForDevice'];
    if (wrappedStr is! String || wrappedStr.trim().isEmpty) {
      throw StateError('SECRET_MEDIA_GRANT_MALFORMED');
    }

    final wrapJson = jsonDecode(wrappedStr) as Map;
    final wrap = WrapEntryBase64.fromJson(
      wrapJson.map((k, v) => MapEntry(k.toString(), v)),
    );

    final epochId = _wrapContextEpochId(
      conversationId: conversationId,
      messageId: messageId,
      fileId: fileId,
    );
    final fileKeyRaw = await unwrapChatKeyForDeviceV2(
      wrap: wrap,
      recipientPrivateKey: identity.keyPair.privateKey,
      epochId: epochId,
      deviceId: identity.deviceId,
    );

    final dir = await E2eePlaintextCache.instance.mediaDir(conversationId);
    final ext = _extensionForMime(env.mime);
    final outFile = File('${dir.path}/$messageId-$fileId$ext');

    if (!await outFile.exists()) {
      final res = await downloadAndDecryptMediaFileWithKeyV2(
        input: DownloadDecryptInputV2(
          storage: FirebaseStorage.instance,
          conversationId: conversationId,
          messageId: messageId,
          envelope: env,
        ),
        fileKeyRaw: fileKeyRaw,
      );
      await outFile.writeAsBytes(res.data, flush: true);
    }

    await callables.consumeSecretMediaKeyGrant(
      conversationId: conversationId,
      messageId: messageId,
      fileId: fileId,
    );

    return ChatAttachment(
      url: Uri.file(outFile.path).toString(),
      name: lockedAttachment.name,
      type: lockedAttachment.type,
      size: lockedAttachment.size,
    );
  }
}

String _extensionForMime(String mime) {
  final m = mime.toLowerCase();
  if (m == 'image/jpeg') return '.jpg';
  if (m == 'image/png') return '.png';
  if (m == 'image/webp') return '.webp';
  if (m == 'image/heic' || m == 'image/heif') return '.heic';
  if (m == 'video/mp4') return '.mp4';
  if (m == 'video/quicktime') return '.mov';
  if (m == 'video/webm') return '.webm';
  if (m == 'video/ogg' || m == 'video/ogv') return '.ogv';
  if (m == 'audio/m4a' || m == 'audio/mp4' || m == 'audio/x-m4a') return '.m4a';
  if (m == 'audio/mpeg') return '.mp3';
  if (m == 'audio/ogg') return '.ogg';
  if (m == 'audio/webm') return '.webm';
  if (m == 'audio/wav' || m == 'audio/x-wav') return '.wav';
  if (m == 'application/pdf') return '.pdf';
  return '';
}

