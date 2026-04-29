import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/secret_chat.dart' hide JsonMap;

export 'src/secret_chat.dart';
export 'src/secret_chat_media_views.dart' hide JsonMap;

typedef JsonMap = Map<String, Object?>;

class UserChatIndex {
  const UserChatIndex({
    required this.conversationIds,
    this.folders,
    this.sidebarFolderOrder,
    this.folderPins,
  });

  final List<String> conversationIds;
  final List<ChatFolder>? folders;
  final List<String>? sidebarFolderOrder;
  final Map<String, List<String>>? folderPins;

  static UserChatIndex fromJson(JsonMap json) {
    final raw = json['conversationIds'];
    final ids = (raw is List ? raw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final foldersRaw = json['folders'];
    final folders = (foldersRaw is List ? foldersRaw : const <Object?>[])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map((m) => ChatFolder.fromJson(m))
        .whereType<ChatFolder>()
        .toList(growable: false);

    final sidebarOrderRaw = json['sidebarFolderOrder'];
    final sidebarFolderOrder =
        (sidebarOrderRaw is List ? sidebarOrderRaw : const <Object?>[])
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList(growable: false);

    final folderPinsRaw = json['folderPins'];
    final folderPins = <String, List<String>>{};
    if (folderPinsRaw is Map) {
      for (final entry in folderPinsRaw.entries) {
        final key = entry.key.toString();
        final v = entry.value;
        final list = (v is List ? v : const <Object?>[])
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
        folderPins[key] = list;
      }
    }

    return UserChatIndex(
      conversationIds: ids,
      folders: folders.isEmpty ? null : folders,
      sidebarFolderOrder: sidebarFolderOrder.isEmpty
          ? null
          : sidebarFolderOrder,
      folderPins: folderPins.isEmpty ? null : folderPins,
    );
  }
}

class ChatFolder {
  const ChatFolder({
    required this.id,
    required this.name,
    required this.conversationIds,
  });

  final String id;
  final String name;
  final List<String> conversationIds;

  static ChatFolder? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final raw = json['conversationIds'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    final ids = (raw is List ? raw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    return ChatFolder(id: id, name: name, conversationIds: ids);
  }
}

/// Cached participant display fields on `conversations` (web `participantInfo`).
class ConversationParticipantInfo {
  const ConversationParticipantInfo({
    required this.name,
    this.avatar,
    this.avatarThumb,
  });

  final String name;
  final String? avatar;
  final String? avatarThumb;

  static ConversationParticipantInfo? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final name = m['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return ConversationParticipantInfo(
      name: name.trim(),
      avatar: m['avatar'] is String ? m['avatar'] as String : null,
      avatarThumb: m['avatarThumb'] is String
          ? m['avatarThumb'] as String
          : null,
    );
  }
}

class Conversation {
  const Conversation({
    required this.isGroup,
    required this.participantIds,
    this.name,
    this.description,
    this.photoUrl,
    this.createdByUserId,
    this.adminIds = const <String>[],
    this.secretChat,
    this.participantInfo,
    this.lastMessageText,
    this.lastMessageTimestamp,
    this.unreadCounts,
    this.unreadThreadCounts,
    this.lastReactionEmoji,
    this.lastReactionTimestamp,
    this.lastReactionSenderId,
    this.lastReactionMessageId,
    this.lastReactionParentId,
    this.lastReactionSeenAt,
    this.clearedAt,
    this.pinnedMessages,
    this.legacyPinnedMessage,
    this.e2eeEnabled,
    this.e2eeKeyEpoch,
    this.e2eeEncryptedDataTypesOverride,
    this.disappearingMessageTtlSec,
    this.disappearingMessagesUpdatedAt,
    this.disappearingMessagesUpdatedBy,
  });

  final bool isGroup;
  final String? name;
  final String? description;

  /// Group avatar URL (web `photoUrl`).
  final String? photoUrl;
  final String? createdByUserId;
  final List<String> adminIds;
  final SecretChatConfig? secretChat;
  final Map<String, ConversationParticipantInfo>? participantInfo;
  final List<String> participantIds;
  final String? lastMessageText;

  /// ISO string in your web model; in Firestore it is commonly stored as string.
  final String? lastMessageTimestamp;
  final Map<String, int>? unreadCounts;
  final Map<String, int>? unreadThreadCounts;
  final String? lastReactionEmoji;
  final String? lastReactionTimestamp;
  final String? lastReactionSenderId;
  final String? lastReactionMessageId;
  final String? lastReactionParentId;
  final Map<String, String>? lastReactionSeenAt;
  final Map<String, String>? clearedAt;
  final List<PinnedMessage>? pinnedMessages;

  /// @deprecated web `pinnedMessage` single field.
  final PinnedMessage? legacyPinnedMessage;
  final bool? e2eeEnabled;
  final int? e2eeKeyEpoch;
  final Map<String, bool>? e2eeEncryptedDataTypesOverride;

  /// Секунды TTL для новых сообщений; null — выкл.
  final int? disappearingMessageTtlSec;
  final String? disappearingMessagesUpdatedAt;
  final String? disappearingMessagesUpdatedBy;

  static Conversation fromJson(JsonMap json) {
    final rawParticipants = json['participantIds'];
    final participantIds =
        (rawParticipants is List ? rawParticipants : const <Object?>[])
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList(growable: false);

    final rawAdmins = json['adminIds'];
    final adminIds = (rawAdmins is List ? rawAdmins : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    int? parseEpoch(Object? raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return null;
    }

    int? parseDisappearingTtl(Object? raw) {
      if (raw == null) return null;
      if (raw is int) return raw > 0 ? raw : null;
      if (raw is num) {
        final v = raw.toInt();
        return v > 0 ? v : null;
      }
      return null;
    }

    Map<String, bool>? parseBoolMap(Object? raw) {
      if (raw is! Map) return null;
      final out = <String, bool>{};
      for (final e in raw.entries) {
        final k = e.key.toString().trim();
        final v = e.value;
        if (k.isEmpty || v is! bool) continue;
        out[k] = v;
      }
      return out.isEmpty ? null : out;
    }

    Map<String, int>? parseCounts(Object? raw) {
      if (raw is! Map) return null;
      final out = <String, int>{};
      for (final entry in raw.entries) {
        final k = entry.key.toString();
        final v = entry.value;
        if (v is int) out[k] = v;
        if (v is num) out[k] = v.toInt();
      }
      return out.isEmpty ? null : out;
    }

    Map<String, String>? parseStrings(Object? raw) {
      if (raw is! Map) return null;
      final out = <String, String>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.isEmpty || value is! String || value.trim().isEmpty) continue;
        out[key] = value.trim();
      }
      return out.isEmpty ? null : out;
    }

    List<PinnedMessage>? parsePins(Object? raw) {
      if (raw is! List || raw.isEmpty) return null;
      final out = <PinnedMessage>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        final p = PinnedMessage.fromJson(m);
        if (p != null) out.add(p);
      }
      return out.isEmpty ? null : out;
    }

    Map<String, ConversationParticipantInfo>? parseParticipantInfo(
      Object? raw,
    ) {
      if (raw is! Map) return null;
      final out = <String, ConversationParticipantInfo>{};
      for (final e in raw.entries) {
        final k = e.key.toString();
        if (k.isEmpty) continue;
        final inf = ConversationParticipantInfo.fromJson(e.value);
        if (inf != null) out[k] = inf;
      }
      return out.isEmpty ? null : out;
    }

    return Conversation(
      isGroup: json['isGroup'] == true,
      name: json['name'] is String ? json['name'] as String : null,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      photoUrl: json['photoUrl'] is String ? json['photoUrl'] as String : null,
      createdByUserId: json['createdByUserId'] is String
          ? json['createdByUserId'] as String
          : null,
      adminIds: adminIds,
      secretChat: SecretChatConfig.fromJson(json['secretChat']),
      participantInfo: parseParticipantInfo(json['participantInfo']),
      participantIds: participantIds,
      lastMessageText: json['lastMessageText'] is String
          ? json['lastMessageText'] as String
          : null,
      lastMessageTimestamp: json['lastMessageTimestamp'] is String
          ? json['lastMessageTimestamp'] as String
          : null,
      unreadCounts: parseCounts(json['unreadCounts']),
      unreadThreadCounts: parseCounts(json['unreadThreadCounts']),
      lastReactionEmoji: json['lastReactionEmoji'] is String
          ? json['lastReactionEmoji'] as String
          : null,
      lastReactionTimestamp: (() {
        final raw = json['lastReactionTimestamp'];
        if (raw is String && raw.isNotEmpty) return raw;
        if (raw is Timestamp) return raw.toDate().toUtc().toIso8601String();
        return null;
      })(),
      lastReactionSenderId: json['lastReactionSenderId'] is String
          ? json['lastReactionSenderId'] as String
          : null,
      lastReactionMessageId: json['lastReactionMessageId'] is String
          ? json['lastReactionMessageId'] as String
          : null,
      lastReactionParentId: json['lastReactionParentId'] is String
          ? json['lastReactionParentId'] as String
          : null,
      lastReactionSeenAt: parseStrings(json['lastReactionSeenAt']),
      clearedAt: parseStrings(json['clearedAt']),
      pinnedMessages: parsePins(json['pinnedMessages']),
      legacyPinnedMessage: PinnedMessage.fromJson(
        json['pinnedMessage'] is Map
            ? (json['pinnedMessage'] as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              )
            : null,
      ),
      e2eeEnabled: json['e2eeEnabled'] == true
          ? true
          : (json['e2eeEnabled'] == false ? false : null),
      e2eeKeyEpoch: parseEpoch(json['e2eeKeyEpoch']),
      e2eeEncryptedDataTypesOverride: parseBoolMap(
        json['e2eeEncryptedDataTypesOverride'],
      ),
      disappearingMessageTtlSec: parseDisappearingTtl(
        json['disappearingMessageTtlSec'],
      ),
      disappearingMessagesUpdatedAt:
          json['disappearingMessagesUpdatedAt'] is String
          ? json['disappearingMessagesUpdatedAt'] as String
          : null,
      disappearingMessagesUpdatedBy:
          json['disappearingMessagesUpdatedBy'] is String
          ? json['disappearingMessagesUpdatedBy'] as String
          : null,
    );
  }
}

class PinnedMessage {
  const PinnedMessage({
    required this.messageId,
    required this.text,
    required this.senderName,
    required this.senderId,
    this.mediaPreviewUrl,
    this.mediaType,
    this.messageCreatedAt,
  });

  final String messageId;
  final String text;
  final String senderName;
  final String senderId;
  final String? mediaPreviewUrl;
  final String? mediaType;
  final String? messageCreatedAt;

  static PinnedMessage? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final messageId = json['messageId'];
    final text = json['text'];
    final senderName = json['senderName'];
    final senderId = json['senderId'];
    if (messageId is! String || messageId.isEmpty) return null;
    if (text is! String) return null;
    if (senderName is! String || senderName.isEmpty) return null;
    if (senderId is! String || senderId.isEmpty) return null;
    final mediaPreviewUrl = json['mediaPreviewUrl'] is String
        ? json['mediaPreviewUrl'] as String
        : null;
    final mediaType = json['mediaType'] is String
        ? json['mediaType'] as String
        : null;
    final messageCreatedAt = json['messageCreatedAt'] is String
        ? json['messageCreatedAt'] as String
        : null;
    return PinnedMessage(
      messageId: messageId,
      text: text,
      senderName: senderName,
      senderId: senderId,
      mediaPreviewUrl: mediaPreviewUrl,
      mediaType: mediaType,
      messageCreatedAt: messageCreatedAt,
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'messageId': messageId,
    'text': text,
    'senderName': senderName,
    'senderId': senderId,
    if (mediaPreviewUrl != null && mediaPreviewUrl!.isNotEmpty)
      'mediaPreviewUrl': mediaPreviewUrl,
    if (mediaType != null && mediaType!.isNotEmpty) 'mediaType': mediaType,
    if (messageCreatedAt != null && messageCreatedAt!.isNotEmpty)
      'messageCreatedAt': messageCreatedAt,
  };
}

double? _jsonDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  return null;
}

/// `locationShare.liveSession` в сообщении чата.
class ChatLocationLiveSession {
  const ChatLocationLiveSession({this.expiresAt});

  final String? expiresAt;

  static ChatLocationLiveSession? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final exp = m['expiresAt'];
    final expiresAt = exp is String && exp.isNotEmpty ? exp : null;
    return ChatLocationLiveSession(expiresAt: expiresAt);
  }
}

/// Геолокация в сообщении (веб `ChatLocationShare`).
class ChatLocationShare {
  const ChatLocationShare({
    required this.lat,
    required this.lng,
    required this.mapsUrl,
    required this.capturedAt,
    this.accuracyM,
    this.staticMapUrl,
    this.liveSession,
  });

  final double lat;
  final double lng;
  final String mapsUrl;
  final String capturedAt;
  final double? accuracyM;
  final String? staticMapUrl;
  final ChatLocationLiveSession? liveSession;

  static ChatLocationShare? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final lat = _jsonDouble(m['lat']);
    final lng = _jsonDouble(m['lng']);
    if (lat == null || lng == null) return null;
    final mapsUrl = m['mapsUrl'];
    if (mapsUrl is! String || mapsUrl.isEmpty) return null;
    final capturedAt = m['capturedAt'];
    if (capturedAt is! String || capturedAt.isEmpty) return null;
    final staticMapRaw = m['staticMapUrl'];
    final staticMapUrl =
        staticMapRaw is String && staticMapRaw.trim().isNotEmpty
        ? staticMapRaw.trim()
        : null;
    return ChatLocationShare(
      lat: lat,
      lng: lng,
      mapsUrl: mapsUrl,
      capturedAt: capturedAt,
      accuracyM: _jsonDouble(m['accuracyM']),
      staticMapUrl: staticMapUrl,
      liveSession: ChatLocationLiveSession.fromJson(m['liveSession']),
    );
  }
}

/// `users/{uid}.liveLocationShare`.
class UserLiveLocationShare {
  const UserLiveLocationShare({
    required this.active,
    this.expiresAt,
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.startedAt,
    this.accuracyM,
  });

  final bool active;
  final String? expiresAt;
  final double lat;
  final double lng;
  final String updatedAt;
  final String startedAt;
  final double? accuracyM;

  static UserLiveLocationShare? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final lat = _jsonDouble(m['lat']);
    final lng = _jsonDouble(m['lng']);
    final updatedAt = m['updatedAt'];
    final startedAt = m['startedAt'];
    if (lat == null || lng == null) return null;
    if (updatedAt is! String || updatedAt.isEmpty) return null;
    if (startedAt is! String || startedAt.isEmpty) return null;
    final exp = m['expiresAt'];
    final expiresAt = exp is String && exp.isNotEmpty ? exp : null;
    return UserLiveLocationShare(
      active: m['active'] == true,
      expiresAt: expiresAt,
      lat: lat,
      lng: lng,
      updatedAt: updatedAt,
      startedAt: startedAt,
      accuracyM: _jsonDouble(m['accuracyM']),
    );
  }
}

class ForwardedFrom {
  const ForwardedFrom({required this.name});

  final String name;

  static ForwardedFrom? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final name = m['name'];
    if (name is! String || name.isEmpty) return null;
    return ForwardedFrom(name: name);
  }
}

class ConversationWithId {
  const ConversationWithId({required this.id, required this.data});

  final String id;
  final Conversation data;

  static ConversationWithId? fromDoc(
    DocumentSnapshot<Map<String, Object?>> doc,
  ) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return ConversationWithId(id: doc.id, data: Conversation.fromJson(data));
  }
}

/// Опрос в чате: `conversations/{id}/polls/{pollId}` (как веб `MeetingPoll`).
class MeetingPoll {
  const MeetingPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.creatorId,
    required this.status,
    required this.isAnonymous,
    this.description,
    this.votes = const <String, List<int>>{},
    this.allowMultipleAnswers = false,
    this.allowAddingOptions = false,
    this.allowRevoting = true,
    this.shuffleOptions = false,
    this.quizMode = false,
    this.correctOptionIndex,
    this.quizExplanation,
    this.closesAt,
  });

  final String id;
  final String question;
  final String? description;
  final List<String> options;
  final String creatorId;

  /// `active` | `ended` | `cancelled` | `draft`
  final String status;
  final bool isAnonymous;

  /// uid → индексы выбранных вариантов (один или несколько).
  final Map<String, List<int>> votes;
  final bool allowMultipleAnswers;
  final bool allowAddingOptions;
  final bool allowRevoting;
  final bool shuffleOptions;
  final bool quizMode;
  final int? correctOptionIndex;
  final String? quizExplanation;
  final DateTime? closesAt;

  static Map<String, List<int>> _parseVotesMap(Object? votesRaw) {
    final votes = <String, List<int>>{};
    if (votesRaw is! Map) return votes;
    for (final e in votesRaw.entries) {
      final k = e.key.toString();
      final v = e.value;
      if (v is int) {
        votes[k] = [v];
      } else if (v is num) {
        votes[k] = [v.toInt()];
      } else if (v is List) {
        final xs = <int>{};
        for (final x in v) {
          if (x is int) xs.add(x);
          if (x is num) xs.add(x.toInt());
        }
        votes[k] = xs.toList()..sort();
      }
    }
    return votes;
  }

  static MeetingPoll? fromDoc(DocumentSnapshot<Map<String, Object?>> doc) {
    if (!doc.exists) return null;
    final d = doc.data();
    if (d == null) return null;
    final id = doc.id;
    final question = d['question'];
    if (question is! String || question.isEmpty) return null;
    final optsRaw = d['options'];
    final options = (optsRaw is List ? optsRaw : const <Object?>[])
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (options.isEmpty) return null;
    final creatorId = d['creatorId'];
    if (creatorId is! String) return null;
    final status = d['status'] is String ? d['status'] as String : 'active';
    final isAnonymous = d['isAnonymous'] == true;
    final desc = d['description'];
    DateTime? closesAt;
    final ca = d['closesAt'];
    if (ca is Timestamp) {
      closesAt = ca.toDate();
    } else if (ca is String && ca.isNotEmpty) {
      closesAt = DateTime.tryParse(ca);
    }
    int? correctIdx;
    final ci = d['correctOptionIndex'];
    if (ci is int) {
      correctIdx = ci;
    } else if (ci is num) {
      correctIdx = ci.toInt();
    }
    final qe = d['quizExplanation'];
    return MeetingPoll(
      id: id,
      question: question,
      description: desc is String && desc.trim().isNotEmpty
          ? desc.trim()
          : null,
      options: options,
      creatorId: creatorId,
      status: status,
      isAnonymous: isAnonymous,
      votes: _parseVotesMap(d['votes']),
      allowMultipleAnswers: d['allowMultipleAnswers'] == true,
      allowAddingOptions: d['allowAddingOptions'] == true,
      allowRevoting: d['allowRevoting'] != false,
      shuffleOptions: d['shuffleOptions'] == true,
      quizMode: d['quizMode'] == true,
      correctOptionIndex: correctIdx,
      quizExplanation: qe is String && qe.trim().isNotEmpty ? qe.trim() : null,
      closesAt: closesAt,
    );
  }
}

/// Данные для создания опроса в чате (паритет веб `ChatPollCreateInput`).
class ChatPollCreatePayload {
  const ChatPollCreatePayload({
    required this.question,
    this.description,
    required this.options,
    required this.isAnonymous,
    this.allowMultipleAnswers = false,
    this.allowAddingOptions = false,
    this.allowRevoting = true,
    this.shuffleOptions = false,
    this.quizMode = false,
    this.correctOptionIndex,
    this.quizExplanation,
    this.closesAt,
  });

  final String question;
  final String? description;
  final List<String> options;
  final bool isAnonymous;
  final bool allowMultipleAnswers;
  final bool allowAddingOptions;
  final bool allowRevoting;
  final bool shuffleOptions;
  final bool quizMode;
  final int? correctOptionIndex;
  final String? quizExplanation;
  final DateTime? closesAt;

  /// Поля документа опроса без `createdAt`.
  Map<String, Object?> pollDocumentFields(String pollId, String creatorId) {
    final q = question.trim();
    final opts = options
        .map((e) => e.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final m = <String, Object?>{
      'id': pollId,
      'question': q,
      'options': opts,
      'creatorId': creatorId,
      'status': 'active',
      'isAnonymous': isAnonymous,
      'votes': <String, Object?>{},
    };
    final d = description?.trim();
    if (d != null && d.isNotEmpty) m['description'] = d;
    if (allowMultipleAnswers) m['allowMultipleAnswers'] = true;
    if (allowAddingOptions) m['allowAddingOptions'] = true;
    if (!allowRevoting) m['allowRevoting'] = false;
    if (shuffleOptions) m['shuffleOptions'] = true;
    if (quizMode && correctOptionIndex != null) {
      m['quizMode'] = true;
      m['correctOptionIndex'] = correctOptionIndex;
      final ex = quizExplanation?.trim();
      if (ex != null && ex.isNotEmpty) m['quizExplanation'] = ex;
    }
    final c = closesAt;
    if (c != null) m['closesAt'] = c.toUtc().toIso8601String();
    return m;
  }
}

/// Полный payload поля `message.e2ee` — нужен mobile-клиенту для дешифровки
/// (Phase 4 E2EE v2). Отдельный иммутабельный класс (user-rule #1 isolation)
/// вместо набора полей внутри `ChatMessage`, чтобы логика парсинга и
/// сравнения концентрировалась в одном месте и можно было безопасно
/// расширить (например, для Phase 7 media wraps).
class ChatMessageE2eePayload {
  const ChatMessageE2eePayload({
    required this.protocolVersion,
    required this.epoch,
    required this.ivB64,
    required this.ciphertextB64,
    this.senderDeviceId,
    this.attachmentsJson,
  });

  /// После Phase 10 cleanup единственная поддерживаемая версия — `v2-p256-aesgcm-multi`.
  /// Не делаем enum: сервер может прислать неизвестную новую версию, её UI
  /// должен корректно отрисовать как «обновите приложение».
  final String protocolVersion;
  final int epoch;
  final String ivB64;
  final String ciphertextB64;

  /// `e2ee.senderDeviceId` — опционально; нужно AAD в v2 (читать из web).
  final String? senderDeviceId;

  /// E2EE v2 Phase 9 (multimedia): сырой JSON-массив envelope'ов из
  /// `message.e2ee.attachments[]`. Парсится в `MediaEnvelopeV2` уровнем выше
  /// (runtime), чтобы модели не зависели от `lighchat_firebase`. Может быть
  /// пустым/null для text-only сообщений.
  final List<Map<String, Object?>>? attachmentsJson;

  bool get isV2 => protocolVersion == 'v2-p256-aesgcm-multi';

  static ChatMessageE2eePayload? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final proto = m['protocolVersion'];
    final epochRaw = m['epoch'];
    final ivRaw = m['iv'];
    final ctRaw = m['ciphertext'];
    final attachmentsRaw = m['attachments'];
    final attachmentsJson = attachmentsRaw is List
        ? attachmentsRaw
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList(growable: false)
        : null;
    final hasAttachments =
        attachmentsJson != null && attachmentsJson.isNotEmpty;
    if (proto is! String || proto.isEmpty) return null;
    // Backward-compatible media-only envelopes:
    // старые клиенты могли отправлять attachments[] с отсутствующим iv/ct.
    final iv = ivRaw is String ? ivRaw : (hasAttachments ? '' : null);
    final ct = ctRaw is String ? ctRaw : (hasAttachments ? '' : null);
    if (iv == null || ct == null) return null;
    // Поддержка media-only E2EE envelope: старые клиенты могли писать
    // пустые iv/ciphertext при наличии `attachments[]`.
    if (!hasAttachments && (iv.isEmpty || ct.isEmpty)) return null;
    final epoch = epochRaw is int
        ? epochRaw
        : (epochRaw is num ? epochRaw.toInt() : 0);
    final senderDev = m['senderDeviceId'];
    return ChatMessageE2eePayload(
      protocolVersion: proto,
      epoch: epoch,
      ivB64: iv,
      ciphertextB64: ct,
      senderDeviceId: senderDev is String && senderDev.isNotEmpty
          ? senderDev
          : null,
      attachmentsJson: (attachmentsJson != null && attachmentsJson.isNotEmpty)
          ? attachmentsJson
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageE2eePayload &&
          other.protocolVersion == protocolVersion &&
          other.epoch == epoch &&
          other.ivB64 == ivB64 &&
          other.ciphertextB64 == ciphertextB64 &&
          other.senderDeviceId == senderDeviceId);

  @override
  int get hashCode =>
      Object.hash(protocolVersion, epoch, ivB64, ciphertextB64, senderDeviceId);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    this.text,
    this.attachments = const <ChatAttachment>[],
    this.replyTo,
    this.isDeleted = false,
    this.reactions,
    required this.createdAt,
    this.readAt,
    this.updatedAt,
    this.forwardedFrom,
    this.deliveryStatus,
    this.chatPollId,
    this.locationShare,
    this.threadCount,
    this.unreadThreadCounts,
    this.lastThreadMessageText,
    this.lastThreadMessageSenderId,
    this.lastThreadMessageTimestamp,
    this.hasE2eeCiphertext = false,
    this.e2eePayload,
    this.mediaNorm,
    this.emojiBurst,
    this.systemEvent,
    this.voiceTranscript,
  });

  final String id;
  final String senderId;
  final String? text;
  final List<ChatAttachment> attachments;
  final ReplyContext? replyTo;
  final bool isDeleted;

  /// Map: emoji -> list of user ids or detailed objects (legacy + new format).
  final Map<String, List<ReactionEntry>>? reactions;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? updatedAt;
  final ForwardedFrom? forwardedFrom;

  /// Web `deliveryStatus`: `sending` | `sent` | `failed`.
  final String? deliveryStatus;

  /// Ссылка на документ `conversations/.../polls/{id}`.
  final String? chatPollId;

  /// Веб `locationShare`.
  final ChatLocationShare? locationShare;

  /// Количество сообщений в ветке `.../messages/{id}/thread` (веб `threadCount`).
  final int? threadCount;

  /// Непрочитанные ответы в ветке по uid (веб `unreadThreadCounts`).
  final Map<String, int>? unreadThreadCounts;
  final String? lastThreadMessageText;
  final String? lastThreadMessageSenderId;

  /// ISO-строка или сериализованный момент с веба (`lastThreadMessageTimestamp`).
  final String? lastThreadMessageTimestamp;

  /// Есть ли шифротекст в payload (`e2ee.ciphertext`).
  /// Сохраняем для обратной совместимости — существующий код чатлиста использует
  /// этот булевый флаг, чтобы скрыть компоновку «пустого» сообщения.
  final bool hasE2eeCiphertext;

  /// Полный payload `message.e2ee` — `null`, если поля нет в документе. Нужно
  /// для дешифровки через `MobileE2eeRuntime` (Phase 4).
  final ChatMessageE2eePayload? e2eePayload;

  /// Статус серверной нормализации медиа (webm/mov → mp4/m4a).
  final ChatMediaNorm? mediaNorm;

  /// Событие полноэкранного emoji-burst (синхронизация между клиентами).
  final ChatEmojiBurstEvent? emojiBurst;

  /// Phase 8: system-событие E2EE (enabled / epoch rotated / device …).
  /// Если присутствует — UI рендерит divider вместо bubble.
  final ChatSystemEvent? systemEvent;

  /// On-demand transcription for voice messages (plaintext chats only).
  /// Stored in Firestore as `voiceTranscript.text` (map) or legacy string.
  final String? voiceTranscript;

  static ChatMessage? fromDoc(DocumentSnapshot<Map<String, Object?>> doc) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    final senderId = data['senderId'];
    final text = data['text'];
    final attachmentsRaw = data['attachments'];
    final createdAtRaw = data['createdAt'];
    final replyToRaw = data['replyTo'];
    final isDeletedRaw = data['isDeleted'];
    final reactionsRaw = data['reactions'];
    final readAtRaw = data['readAt'];
    final updatedAtRaw = data['updatedAt'];
    final forwardedFromRaw = data['forwardedFrom'];
    final deliveryStatusRaw = data['deliveryStatus'];
    final chatPollIdRaw = data['chatPollId'];
    final chatPollId =
        chatPollIdRaw is String && chatPollIdRaw.trim().isNotEmpty
        ? chatPollIdRaw.trim()
        : null;
    final locationShare = ChatLocationShare.fromJson(data['locationShare']);
    final mediaNorm = ChatMediaNorm.fromJson(data['mediaNorm']);
    final emojiBurst = ChatEmojiBurstEvent.fromJson(data['emojiBurst']);
    final e2eePayload = ChatMessageE2eePayload.fromJson(data['e2ee']);
    final hasE2eeCiphertext = e2eePayload != null;
    final systemEvent = ChatSystemEvent.fromJson(data['systemEvent']);
    final vtRaw = data['voiceTranscript'];
    String? voiceTranscript;
    if (vtRaw is String && vtRaw.trim().isNotEmpty) {
      voiceTranscript = vtRaw.trim();
    } else if (vtRaw is Map) {
      final t = vtRaw['text'];
      if (t is String && t.trim().isNotEmpty) voiceTranscript = t.trim();
    }

    int? threadCount;
    final threadCountRaw = data['threadCount'];
    if (threadCountRaw is int) {
      threadCount = threadCountRaw;
    } else if (threadCountRaw is num) {
      threadCount = threadCountRaw.toInt();
    }

    Map<String, int>? unreadThreadCounts;
    final uraw = data['unreadThreadCounts'];
    if (uraw is Map) {
      final um = <String, int>{};
      for (final e in uraw.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (k.isEmpty) continue;
        if (v is int) um[k] = v;
        if (v is num) um[k] = v.toInt();
      }
      if (um.isNotEmpty) unreadThreadCounts = um;
    }

    final lastThreadMessageText = data['lastThreadMessageText'] is String
        ? data['lastThreadMessageText'] as String
        : null;
    final lastThreadMessageSenderId =
        data['lastThreadMessageSenderId'] is String
        ? data['lastThreadMessageSenderId'] as String
        : null;

    String? lastThreadMessageTimestamp;
    final ltsRaw = data['lastThreadMessageTimestamp'];
    if (ltsRaw is String && ltsRaw.isNotEmpty) {
      lastThreadMessageTimestamp = ltsRaw;
    } else if (ltsRaw is Timestamp) {
      lastThreadMessageTimestamp = ltsRaw.toDate().toUtc().toIso8601String();
    }

    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt =
          DateTime.tryParse(createdAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final attachments =
        (attachmentsRaw is List ? attachmentsRaw : const <Object?>[])
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .map((m) => ChatAttachment.fromJson(m))
            .whereType<ChatAttachment>()
            .toList(growable: false);

    final replyTo = ReplyContext.fromJson(replyToRaw);
    final isDeleted = isDeletedRaw == true;
    final reactions = parseReactions(reactionsRaw);

    DateTime? readAt;
    if (readAtRaw is Timestamp) {
      readAt = readAtRaw.toDate();
    } else if (readAtRaw is String && readAtRaw.isNotEmpty) {
      readAt = DateTime.tryParse(readAtRaw);
    }

    final updatedAt = updatedAtRaw is String ? updatedAtRaw : null;
    final forwardedFrom = ForwardedFrom.fromJson(forwardedFromRaw);
    final deliveryStatus =
        deliveryStatusRaw is String && deliveryStatusRaw.isNotEmpty
        ? deliveryStatusRaw
        : null;

    return ChatMessage(
      id: doc.id,
      senderId: senderId is String ? senderId : '',
      text: text is String ? text : null,
      attachments: attachments,
      replyTo: replyTo,
      isDeleted: isDeleted,
      reactions: reactions,
      createdAt: createdAt,
      readAt: readAt,
      updatedAt: updatedAt,
      forwardedFrom: forwardedFrom,
      deliveryStatus: deliveryStatus,
      chatPollId: chatPollId,
      locationShare: locationShare,
      threadCount: threadCount,
      unreadThreadCounts: unreadThreadCounts,
      lastThreadMessageText: lastThreadMessageText,
      lastThreadMessageSenderId: lastThreadMessageSenderId,
      lastThreadMessageTimestamp: lastThreadMessageTimestamp,
      hasE2eeCiphertext: hasE2eeCiphertext,
      e2eePayload: e2eePayload,
      mediaNorm: mediaNorm,
      emojiBurst: emojiBurst,
      systemEvent: systemEvent,
      voiceTranscript: voiceTranscript,
    );
  }
}

/// Phase 8 — system-маркер E2EE в timeline чата.
/// Зеркало `ChatSystemEvent` в `src/lib/types.ts`.
enum ChatSystemEventType {
  e2eeV2Enabled('e2ee.v2.enabled'),
  e2eeV2Disabled('e2ee.v2.disabled'),
  e2eeV2EpochRotated('e2ee.v2.epoch.rotated'),
  e2eeV2DeviceAdded('e2ee.v2.device.added'),
  e2eeV2DeviceRevoked('e2ee.v2.device.revoked'),
  e2eeV2FingerprintChanged('e2ee.v2.fingerprint.changed'),
  gameLobbyCreated('gameLobbyCreated'),
  gameStarted('gameStarted');

  const ChatSystemEventType(this.wire);
  final String wire;

  static ChatSystemEventType? fromWire(String? wire) {
    if (wire == null || wire.isEmpty) return null;
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}

class ChatSystemEvent {
  const ChatSystemEvent({required this.type, this.data});

  final ChatSystemEventType type;
  final Map<String, Object?>? data;

  static ChatSystemEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final typeStr = raw['type'];
    if (typeStr is! String) return null;
    final type = ChatSystemEventType.fromWire(typeStr);
    if (type == null) return null;
    final d = raw['data'];
    Map<String, Object?>? data;
    if (d is Map) {
      data = d.map((k, v) => MapEntry(k.toString(), v));
    }
    return ChatSystemEvent(type: type, data: data);
  }
}

enum DurakGameStatus { lobby, active, finished, cancelled }

class DurakCardModel {
  const DurakCardModel({required this.rank, required this.suit});

  final Object rank;
  final String? suit;

  static DurakCardModel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final r = raw['r'];
    final s = raw['s'];
    if (r == null) return null;
    return DurakCardModel(rank: r, suit: s?.toString());
  }
}

class DurakPublicViewModel {
  const DurakPublicViewModel({
    required this.phase,
    required this.trumpSuit,
    required this.deckCount,
    required this.discardCount,
    required this.attackerUid,
    required this.defenderUid,
    required this.handCounts,
    this.currentThrowerUid,
    this.roundDefenderHandLimit,
    this.canFinishTurn,
  });

  final String phase;
  final String trumpSuit;
  final int deckCount;
  final int discardCount;
  final String attackerUid;
  final String defenderUid;
  final Map<String, int> handCounts;
  final String? currentThrowerUid;
  final int? roundDefenderHandLimit;
  final bool? canFinishTurn;

  static DurakPublicViewModel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    int asInt(Object? v) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    final handCountsRaw = raw['handCounts'];
    final handCounts = <String, int>{};
    if (handCountsRaw is Map) {
      for (final e in handCountsRaw.entries) {
        handCounts[e.key.toString()] = asInt(e.value);
      }
    }
    final roundLimitRaw = raw['roundDefenderHandLimit'];
    return DurakPublicViewModel(
      phase: (raw['phase'] ?? '').toString(),
      trumpSuit: (raw['trumpSuit'] ?? '').toString(),
      deckCount: asInt(raw['deckCount']),
      discardCount: asInt(raw['discardCount']),
      attackerUid: (raw['attackerUid'] ?? '').toString(),
      defenderUid: (raw['defenderUid'] ?? '').toString(),
      handCounts: handCounts,
      currentThrowerUid:
          (raw['currentThrowerUid'] ?? '').toString().trim().isEmpty
          ? null
          : raw['currentThrowerUid'].toString(),
      roundDefenderHandLimit: roundLimitRaw is int
          ? roundLimitRaw
          : int.tryParse((roundLimitRaw ?? '').toString()),
      canFinishTurn: raw.containsKey('canFinishTurn')
          ? raw['canFinishTurn'] == true
          : null,
    );
  }
}

class ChatEmojiBurstEvent {
  const ChatEmojiBurstEvent({
    required this.eventId,
    required this.emoji,
    required this.by,
    required this.at,
  });

  final String eventId;
  final String emoji;
  final String by;
  final String at;

  static ChatEmojiBurstEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final eventIdRaw = m['eventId'];
    final emojiRaw = m['emoji'];
    final byRaw = m['by'];
    final atRaw = m['at'];
    if (eventIdRaw is! String || eventIdRaw.trim().isEmpty) return null;
    if (emojiRaw is! String || emojiRaw.trim().isEmpty) return null;
    if (byRaw is! String || byRaw.trim().isEmpty) return null;
    if (atRaw is! String || atRaw.trim().isEmpty) return null;
    return ChatEmojiBurstEvent(
      eventId: eventIdRaw.trim(),
      emoji: emojiRaw.trim(),
      by: byRaw.trim(),
      at: atRaw.trim(),
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'eventId': eventId,
    'emoji': emoji,
    'by': by,
    'at': at,
  };
}

class ChatMediaNorm {
  const ChatMediaNorm({
    required this.status,
    this.failedIndexes = const <int>[],
    required this.updatedAt,
  });

  final String status;
  final List<int> failedIndexes;
  final String updatedAt;

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isDone => status == 'done';

  bool isFailedIndex(int index) => failedIndexes.contains(index);

  static ChatMediaNorm? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final statusRaw = m['status'];
    final updatedAtRaw = m['updatedAt'];
    if (statusRaw is! String || statusRaw.isEmpty) return null;
    if (updatedAtRaw is! String || updatedAtRaw.isEmpty) return null;
    final failed = <int>[];
    final failedRaw = m['failedIndexes'];
    if (failedRaw is List) {
      for (final one in failedRaw) {
        if (one is int) {
          failed.add(one);
        } else if (one is num) {
          failed.add(one.toInt());
        }
      }
    }
    return ChatMediaNorm(
      status: statusRaw,
      failedIndexes: failed,
      updatedAt: updatedAtRaw,
    );
  }
}

class ReplyContext {
  const ReplyContext({
    required this.messageId,
    required this.senderName,
    this.text,
    this.mediaPreviewUrl,
    this.mediaType,
  });

  final String messageId;
  final String senderName;
  final String? text;
  final String? mediaPreviewUrl;
  final String? mediaType;

  static ReplyContext? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final messageId = m['messageId'];
    final senderName = m['senderName'];
    if (messageId is! String || messageId.isEmpty) return null;
    if (senderName is! String || senderName.isEmpty) return null;
    final text = m['text'] is String ? m['text'] as String : null;
    final mediaPreviewUrl = m['mediaPreviewUrl'] is String
        ? m['mediaPreviewUrl'] as String
        : null;
    final mediaType = m['mediaType'] is String
        ? m['mediaType'] as String
        : null;
    return ReplyContext(
      messageId: messageId,
      senderName: senderName,
      text: text,
      mediaPreviewUrl: mediaPreviewUrl,
      mediaType: mediaType,
    );
  }
}

class ReactionEntry {
  const ReactionEntry({required this.userId, this.timestamp});

  final String userId;
  final String? timestamp;
}

Map<String, List<ReactionEntry>>? parseReactions(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, List<ReactionEntry>>{};
  for (final e in raw.entries) {
    final emoji = e.key.toString();
    final v = e.value;
    if (emoji.isEmpty) continue;
    if (v is! List) continue;
    final entries = <ReactionEntry>[];
    for (final item in v) {
      if (item is String && item.isNotEmpty) {
        entries.add(ReactionEntry(userId: item));
      } else if (item is Map) {
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        final uid = m['userId'];
        if (uid is! String || uid.isEmpty) continue;
        final ts = m['timestamp'] is String ? m['timestamp'] as String : null;
        entries.add(ReactionEntry(userId: uid, timestamp: ts));
      }
    }
    if (entries.isNotEmpty) out[emoji] = entries;
  }
  return out.isEmpty ? null : out;
}

class ChatAttachment {
  const ChatAttachment({
    required this.url,
    required this.name,
    this.type,
    this.size,
    this.width,
    this.height,
    this.thumbHash,
  });

  final String url;
  final String name;
  final String? type;
  final int? size;
  final int? width;
  final int? height;
  final String? thumbHash;

  static ChatAttachment? fromJson(Map<String, Object?> json) {
    final url = json['url'];
    final name = json['name'];
    if (url is! String || url.isEmpty) return null;
    if (name is! String) return null;
    final type = json['type'] is String ? json['type'] as String : null;
    final size = json['size'] is int
        ? json['size'] as int
        : (json['size'] is num ? (json['size'] as num).toInt() : null);
    final width = json['width'] is int
        ? json['width'] as int
        : (json['width'] is num ? (json['width'] as num).toInt() : null);
    final height = json['height'] is int
        ? json['height'] as int
        : (json['height'] is num ? (json['height'] as num).toInt() : null);
    final thumbHash = json['thumbHash'] is String
        ? json['thumbHash'] as String
        : null;
    return ChatAttachment(
      url: url,
      name: name,
      type: type,
      size: size,
      width: width,
      height: height,
      thumbHash: thumbHash,
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'url': url,
    'name': name,
    if (type != null) 'type': type,
    if (size != null) 'size': size,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (thumbHash != null && thumbHash!.isNotEmpty) 'thumbHash': thumbHash,
  };
}
