import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'features/auth/registration_profile_gate.dart';
import 'features/chat/data/chat_folders_repository.dart';
import 'features/chat/data/chat_settings_repository.dart';
import 'features/chat/data/user_contacts_repository.dart';
import 'features/chat/data/user_profiles_repository.dart';
import 'features/chat/data/user_sticker_packs_repository.dart';
import 'features/chat/data/chat_list_offline_cache.dart';

class StarredChatMessageEntry {
  const StarredChatMessageEntry({
    required this.docId,
    required this.conversationId,
    required this.messageId,
    required this.createdAt,
    this.previewText,
  });

  final String docId;
  final String conversationId;
  final String messageId;
  final DateTime createdAt;
  final String? previewText;
}

final firebaseReadyProvider = Provider<bool>((ref) => isFirebaseReady());

/// Завершена ли регистрация по `users/{uid}` (сервер для Google/Apple при «пустом» кэше). После `completeGoogleProfile` — [Ref.invalidate].
final registrationProfileCompleteProvider = FutureProvider.family<bool, String>((
  ref,
  uid,
) async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null || u.uid != uid) return false;
  // Future.any + дедлайн в [getFirestoreRegistrationProfileStatusWithDeadline]: иначе на iOS
  // список чатов может вечно оставаться на «Проверка регистрации…».
  final status = await getFirestoreRegistrationProfileStatusWithDeadline(u);
  return status == RegistrationProfileStatus.complete;
});

/// Трёхсостояние проверки профиля: complete/incomplete/unknown.
final registrationProfileStatusProvider =
    FutureProvider.family<RegistrationProfileStatus, String>((ref, uid) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null || u.uid != uid) return RegistrationProfileStatus.unknown;
      return getFirestoreRegistrationProfileStatusWithDeadline(u);
    });

/// Null when Firebase failed to initialize (app still runs; show setup UI).
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return AuthRepository();
});

final authUserProvider = StreamProvider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.watchUser();
});

final chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return ChatRepository();
});

final userChatIndexProvider = StreamProvider.family<UserChatIndex?, String>((
  ref,
  userId,
) async* {
  final uid = userId.trim();
  if (uid.isEmpty) {
    yield null;
    return;
  }
  final offline = await loadChatListOfflineSnapshot(uid);
  if (offline?.index != null) {
    yield offline!.index;
  }
  final repo = ref.watch(chatRepositoryProvider);
  if (repo == null) {
    yield offline?.index;
    return;
  }
  await for (final v in repo.watchUserChatIndex(userId: uid)) {
    yield v;
  }
});

/// Stable key for Riverpod family (avoid `List` identity churn on every rebuild).
typedef ConversationIdsKey = ({String key});

String conversationIdsCacheKey(List<String> ids) {
  final copy = ids.where((s) => s.isNotEmpty).toSet().toList()..sort();
  if (copy.isEmpty) return '__empty__';
  return copy.join('\u001e');
}

final conversationsProvider =
    StreamProvider.family<List<ConversationWithId>, ConversationIdsKey>((
      ref,
      args,
    ) async* {
      final rawKey = args.key;
      final ids = rawKey == '__empty__'
          ? const <String>[]
          : rawKey.split('\u001e');
      final uid = ref.watch(authUserProvider).asData?.value?.uid.trim();
      if (uid != null && uid.isNotEmpty && ids.isNotEmpty) {
        final offline = await loadChatListOfflineSnapshot(uid);
        if (offline != null && offline.conversations.isNotEmpty) {
          final byId = {
            for (final c in offline.conversations) c.id: c,
          };
          final ordered = <ConversationWithId>[];
          for (final id in ids) {
            final c = byId[id];
            if (c != null) ordered.add(c);
          }
          if (ordered.isNotEmpty) {
            yield ordered;
          }
        }
      }
      final repo = ref.watch(chatRepositoryProvider);
      if (repo == null) {
        yield const <ConversationWithId>[];
        return;
      }
      await for (final v in repo.watchConversationsByIds(ids)) {
        yield v;
      }
    });

final messagesProvider =
    StreamProvider.family<
      List<ChatMessage>,
      ({String conversationId, int limit})
    >((ref, args) {
      final repo = ref.watch(chatRepositoryProvider);
      if (repo == null) return Stream.value(const <ChatMessage>[]);
      return repo.watchMessages(
        conversationId: args.conversationId,
        limit: args.limit,
      );
    });

final threadMessagesProvider =
    StreamProvider.family<
      List<ChatMessage>,
      ({String conversationId, String parentMessageId, int limit})
    >((ref, args) {
      final repo = ref.watch(chatRepositoryProvider);
      if (repo == null) return Stream.value(const <ChatMessage>[]);
      return repo.watchThreadMessages(
        conversationId: args.conversationId,
        parentMessageId: args.parentMessageId,
        limit: args.limit,
      );
    });

final chatMessageByIdProvider =
    FutureProvider.family<
      ChatMessage?,
      ({String conversationId, String messageId})
    >((ref, args) async {
      final repo = ref.watch(chatRepositoryProvider);
      if (repo == null) return null;
      return repo.getChatMessage(
        conversationId: args.conversationId,
        messageId: args.messageId,
      );
    });

final registrationServiceProvider = Provider<RegistrationService?>((ref) {
  if (!isFirebaseReady()) return null;
  return RegistrationService();
});

final userProfilesRepositoryProvider = Provider<UserProfilesRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return UserProfilesRepository();
});

final userContactsRepositoryProvider = Provider<UserContactsRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return UserContactsRepository();
});

final userContactsIndexProvider =
    StreamProvider.family<UserContactsIndex, String>((ref, userId) {
      final repo = ref.watch(userContactsRepositoryProvider);
      if (repo == null) {
        return Stream.value(const UserContactsIndex(contactIds: <String>[]));
      }
      return repo.watchContacts(userId);
    });

final chatFoldersRepositoryProvider = Provider<ChatFoldersRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return ChatFoldersRepository();
});

final chatSettingsRepositoryProvider = Provider<ChatSettingsRepository?>((ref) {
  if (!isFirebaseReady()) return null;
  return ChatSettingsRepository();
});

final userStickerPacksRepositoryProvider =
    Provider<UserStickerPacksRepository?>((ref) {
      if (!isFirebaseReady()) return null;
      return UserStickerPacksRepository(
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      );
    });

final userChatSettingsDocProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, uid) {
      final repo = ref.watch(chatSettingsRepositoryProvider);
      if (repo == null) return Stream.value(const <String, dynamic>{});
      return repo.watchUserDoc(uid);
    });

final starredMessageIdsInConversationProvider =
    StreamProvider.family<
      Set<String>,
      ({String userId, String conversationId})
    >((ref, args) {
      if (!isFirebaseReady()) return Stream.value(const <String>{});
      final uid = args.userId.trim();
      final convId = args.conversationId.trim();
      if (uid.isEmpty || convId.isEmpty) {
        return Stream.value(const <String>{});
      }
      final q = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('starredChatMessages')
          .where('conversationId', isEqualTo: convId);
      return q.snapshots().map((snap) {
        final out = <String>{};
        for (final d in snap.docs) {
          final raw = d.data()['messageId'];
          if (raw is String && raw.trim().isNotEmpty) {
            out.add(raw.trim());
          }
        }
        return out;
      });
    });

final starredMessagesInConversationProvider =
    StreamProvider.family<
      List<StarredChatMessageEntry>,
      ({String userId, String conversationId})
    >((ref, args) {
      if (!isFirebaseReady()) {
        return Stream.value(const <StarredChatMessageEntry>[]);
      }
      final uid = args.userId.trim();
      final convId = args.conversationId.trim();
      if (uid.isEmpty || convId.isEmpty) {
        return Stream.value(const <StarredChatMessageEntry>[]);
      }
      final q = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('starredChatMessages')
          .where('conversationId', isEqualTo: convId)
          .orderBy('createdAt', descending: true);

      DateTime parseCreatedAt(Object? raw) {
        if (raw is Timestamp) return raw.toDate().toLocal();
        if (raw is String) {
          return DateTime.tryParse(raw)?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0);
        }
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      return q.snapshots().map((snap) {
        return snap.docs
            .map((d) {
              final data = d.data();
              final messageId = data['messageId'];
              final createdAtRaw = data['createdAt'];
              final previewText = data['previewText'];
              return StarredChatMessageEntry(
                docId: d.id,
                conversationId: convId,
                messageId: messageId is String ? messageId.trim() : '',
                createdAt: parseCreatedAt(createdAtRaw),
                previewText:
                    previewText is String && previewText.trim().isNotEmpty
                    ? previewText.trim()
                    : null,
              );
            })
            .where((x) => x.messageId.isNotEmpty)
            .toList(growable: false);
      });
    });
