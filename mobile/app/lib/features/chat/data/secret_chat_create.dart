import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Creates (or opens existing) Secret DM chat between two users.
///
/// Uses deterministic id `sdm_{lenA}:{uidA}_{lenB}:{uidB}` (lexicographic order),
/// to prevent duplicates (mirrors `dm_...` strategy for regular chats).
String buildSecretDirectConversationId(String userA, String userB) {
  final ids = <String>[userA.trim(), userB.trim()]..sort();
  String part(String v) => '${v.length}:$v';
  return 'sdm_${part(ids[0])}_${part(ids[1])}';
}

Future<String> createOrOpenSecretDirectChat({
  required FirebaseFirestore firestore,
  required String currentUserId,
  required String otherUserId,
  required ({String name, String? avatar, String? avatarThumb}) currentUserInfo,
  required ({String name, String? avatar, String? avatarThumb}) otherUserInfo,
  required int ttlPresetSec,
  SecretChatRestrictions restrictions = const SecretChatRestrictions(
    noForward: true,
    noCopy: true,
    noSave: true,
    screenshotProtection: true,
  ),
  bool lockRequired = false,
  SecretChatMediaViewPolicy? mediaViewPolicy,
}) async {
  final a = currentUserId.trim();
  final b = otherUserId.trim();
  if (a.isEmpty || b.isEmpty || a == b) {
    throw ArgumentError('createOrOpenSecretDirectChat requires distinct non-empty user ids');
  }

  final conversationId = buildSecretDirectConversationId(a, b);
  final ref = firestore.collection('conversations').doc(conversationId);
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final expiresAtIso = DateTime.now()
      .toUtc()
      .add(Duration(seconds: ttlPresetSec))
      .toIso8601String();

  await firestore.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (snap.exists) return;
    tx.set(ref, <String, Object?>{
      'isGroup': false,
      'participantIds': [a, b],
      'adminIds': const <String>[],
      'participantInfo': <String, Object?>{
        a: <String, Object?>{
          'name': currentUserInfo.name,
          if (currentUserInfo.avatar != null) 'avatar': currentUserInfo.avatar,
          if (currentUserInfo.avatarThumb != null) 'avatarThumb': currentUserInfo.avatarThumb,
        },
        b: <String, Object?>{
          'name': otherUserInfo.name,
          if (otherUserInfo.avatar != null) 'avatar': otherUserInfo.avatar,
          if (otherUserInfo.avatarThumb != null) 'avatarThumb': otherUserInfo.avatarThumb,
        },
      },
      'lastMessageTimestamp': nowIso,
      'lastMessageText': '',
      'unreadCounts': <String, Object?>{a: 0, b: 0},
      'unreadThreadCounts': <String, Object?>{a: 0, b: 0},
      'clearedAt': <String, Object?>{a: nowIso, b: nowIso},
      'typing': <String, Object?>{},
      'secretChat': <String, Object?>{
        'enabled': true,
        'createdAt': nowIso,
        'createdBy': a,
        'expiresAt': expiresAtIso,
        'ttlPresetSec': ttlPresetSec,
        'lockPolicy': <String, Object?>{
          'required': lockRequired,
        },
        'restrictions': <String, Object?>{
          'noForward': restrictions.noForward,
          'noCopy': restrictions.noCopy,
          'noSave': restrictions.noSave,
          'screenshotProtection': restrictions.screenshotProtection,
        },
        if (mediaViewPolicy != null)
          'mediaViewPolicy': <String, Object?>{
            'image': mediaViewPolicy.image,
            'video': mediaViewPolicy.video,
            'voice': mediaViewPolicy.voice,
            'file': mediaViewPolicy.file,
            'location': mediaViewPolicy.location,
          },
      },
    });
  });

  // Force-enable E2EE for secret chats (best-effort: chat still exists if keys/peers missing).
  try {
    final identity = await getOrCreateMobileDeviceIdentity();
    await tryAutoEnableE2eeNewDirectChatMobile(
      firestore: firestore,
      conversationId: conversationId,
      currentUserId: a,
      identity: identity,
      options: const AutoEnableE2eeOptions(userWants: true, platformWants: true),
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[secret-chat] E2EE auto-enable failed (non-fatal): $e\n$st');
    }
  }

  // Safety: secret chats should not stay in the main userChats index.
  // Keep local creator index clean even if backend index trigger is stale.
  try {
    await firestore.collection('userChats').doc(a).set(<String, Object?>{
      'conversationIds': FieldValue.arrayRemove(<String>[conversationId]),
    }, SetOptions(merge: true));
  } catch (_) {}

  return conversationId;
}

