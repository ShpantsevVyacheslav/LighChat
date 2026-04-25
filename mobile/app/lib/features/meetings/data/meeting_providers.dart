import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_models/lighchat_models.dart';

import 'meeting_callables.dart';
import 'meeting_chat_message.dart';
import 'meeting_chat_repository.dart';
import 'meeting_guest_auth.dart';
import 'meeting_poll_repository.dart';
import 'meeting_models.dart';
import 'meeting_repository.dart';
import 'virtual_background_controller.dart';
import 'virtual_background_platform.dart';

/// Dependency container для feature meetings. Всё — autoDispose, чтобы не
/// держать подписки после ухода из экрана митинга.
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(FirebaseFirestore.instance);
});

final meetingCallablesProvider = Provider<MeetingCallables>((ref) {
  return MeetingCallables();
});

final meetingGuestAuthProvider = Provider<MeetingGuestAuth>((ref) {
  return MeetingGuestAuth();
});

/// Документ митинга; `null` — не существует/нет доступа.
final meetingDocProvider = StreamProvider.autoDispose
    .family<MeetingDoc?, String>((ref, meetingId) {
      final repo = ref.watch(meetingRepositoryProvider);
      return repo.watchMeeting(meetingId);
    });

/// Список активных участников митинга. Не включает пользователя до его
/// собственного join (пока не создал `participants/{uid}`).
final meetingParticipantsProvider = StreamProvider.autoDispose
    .family<List<MeetingParticipant>, String>((ref, meetingId) {
      final repo = ref.watch(meetingRepositoryProvider);
      return repo.watchParticipants(meetingId);
    });

/// Список заявок — видит только host/admin (иначе read deny в правилах).
final meetingRequestsProvider = StreamProvider.autoDispose
    .family<List<MeetingRequestDoc>, String>((ref, meetingId) {
      final repo = ref.watch(meetingRepositoryProvider);
      return repo.watchRequests(meetingId);
    });

/// Собственная заявка в waiting-room — для отображения прогресса ожидания.
/// Ключ: пара (meetingId, userId).
final meetingOwnRequestProvider = StreamProvider.autoDispose
    .family<MeetingRequestDoc?, MeetingOwnRequestKey>((ref, key) {
      final repo = ref.watch(meetingRepositoryProvider);
      return repo.watchOwnRequest(key.meetingId, key.userId);
    });

/// История встреч пользователя (паритет web):
/// `userMeetings/{uid}.meetingIds` + fallback на встречи, где пользователь host.
final meetingHistoryProvider = StreamProvider.autoDispose
    .family<List<MeetingDoc>, String>((ref, userId) {
      final repo = ref.watch(meetingRepositoryProvider);
      return repo.watchMeetingHistory(userId);
    });

/// Legacy alias для обратной совместимости.
final myHostedMeetingsProvider = meetingHistoryProvider;

/// Репозиторий чата внутри митинга — отдельный от MeetingRepository.
final meetingChatRepositoryProvider = Provider<MeetingChatRepository>((ref) {
  return MeetingChatRepository(FirebaseFirestore.instance);
});

/// Firebase Storage — загрузка вложений в `meeting-attachments/...`.
final meetingFirebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Сообщения чата текущего митинга. Правила Firestore требуют быть
/// участником (`meetings/{id}/participants/{uid}` существует) — иначе
/// `permission-denied`. Вне участия стрим возвращает ошибку.
final meetingChatMessagesProvider = StreamProvider.autoDispose
    .family<List<MeetingChatMessage>, String>((ref, meetingId) {
      final repo = ref.watch(meetingChatRepositoryProvider);
      return repo.watchMessages(meetingId);
    });

final meetingPollRepositoryProvider = Provider<MeetingPollRepository>((ref) {
  return MeetingPollRepository(FirebaseFirestore.instance);
});

/// Опросы встречи (`meetings/{id}/polls`), паритет web [MeetingPolls].
final meetingPollsProvider = StreamProvider.autoDispose
    .family<List<MeetingPoll>, String>((ref, meetingId) {
      final repo = ref.watch(meetingPollRepositoryProvider);
      return repo.watchPolls(meetingId);
    });

class MeetingOwnRequestKey {
  const MeetingOwnRequestKey({required this.meetingId, required this.userId});
  final String meetingId;
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingOwnRequestKey &&
          other.meetingId == meetingId &&
          other.userId == userId);

  @override
  int get hashCode => Object.hash(meetingId, userId);
}

/// Флаг сборки: `--dart-define=LIGHCHAT_VIRTUAL_BG_NATIVE=true` активирует
/// native-бэкенд виртуального фона (MethodChannel `lighchat/virtual_background`).
/// По умолчанию — noop, UI-переключатель скрыт.
const bool kVirtualBackgroundNativeEnabled = bool.fromEnvironment(
  'LIGHCHAT_VIRTUAL_BG_NATIVE',
  defaultValue: false,
);

/// Провайдер контроллера виртуального фона. Единственная точка выбора
/// реализации: сейчас — noop или MethodChannel (управляется флагом сборки).
/// В будущем сюда можно подложить in-memory для тестов (переопределением).
final virtualBackgroundControllerProvider =
    Provider<VirtualBackgroundController>((ref) {
      final controller = kVirtualBackgroundNativeEnabled
          ? MethodChannelVirtualBackgroundController()
          : NoopVirtualBackgroundController();
      ref.onDispose(() {
        controller.dispose().catchError((_) {});
      });
      return controller;
    });
