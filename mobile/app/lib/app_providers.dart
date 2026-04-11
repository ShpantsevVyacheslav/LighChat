import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'features/auth/registration_profile_gate.dart';
import 'features/chat/data/chat_folders_repository.dart';
import 'features/chat/data/chat_settings_repository.dart';
import 'features/chat/data/user_contacts_repository.dart';
import 'features/chat/data/user_profiles_repository.dart';

final firebaseReadyProvider = Provider<bool>((ref) => isFirebaseReady());

/// Завершена ли регистрация по `users/{uid}` (сервер для Google при «пустом» кэше). После `completeGoogleProfile` — [Ref.invalidate].
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
) {
  final repo = ref.watch(chatRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.watchUserChatIndex(userId: userId);
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
    ) {
      final repo = ref.watch(chatRepositoryProvider);
      if (repo == null) return Stream.value(const <ConversationWithId>[]);
      final rawKey = args.key;
      final ids = rawKey == '__empty__'
          ? const <String>[]
          : rawKey.split('\u001e');
      return repo.watchConversationsByIds(ids);
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

final userChatSettingsDocProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, uid) {
      final repo = ref.watch(chatSettingsRepositoryProvider);
      if (repo == null) return Stream.value(const <String, dynamic>{});
      return repo.watchUserDoc(uid);
    });
