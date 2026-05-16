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
    this.lastMessageSenderId,
    this.lastMessageIsThread = false,
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
    this.forwardingAllowed,
    this.screenshotsAllowed,
    this.copyAllowed,
    this.saveMediaAllowed,
    this.shareMediaAllowed,
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

  /// UID отправителя последнего сообщения (для превью «Имя: текст» в списке чатов).
  final String? lastMessageSenderId;

  /// Последнее сообщение из треда (а не из основного чата).
  final bool lastMessageIsThread;
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

  /// Privacy settings for group chats
  final bool? forwardingAllowed;
  final bool? screenshotsAllowed;
  final bool? copyAllowed;
  final bool? saveMediaAllowed;
  final bool? shareMediaAllowed;

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
      lastMessageSenderId: json['lastMessageSenderId'] is String
          ? json['lastMessageSenderId'] as String
          : null,
      lastMessageIsThread: json['lastMessageIsThread'] == true,
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
      forwardingAllowed: json['forwardingAllowed'] == true
          ? true
          : (json['forwardingAllowed'] == false ? false : null),
      screenshotsAllowed: json['screenshotsAllowed'] == true
          ? true
          : (json['screenshotsAllowed'] == false ? false : null),
      copyAllowed: json['copyAllowed'] == true
          ? true
          : (json['copyAllowed'] == false ? false : null),
      saveMediaAllowed: json['saveMediaAllowed'] == true
          ? true
          : (json['saveMediaAllowed'] == false ? false : null),
      shareMediaAllowed: json['shareMediaAllowed'] == true
          ? true
          : (json['shareMediaAllowed'] == false ? false : null),
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
    this.conversationId,
  });

  final bool active;
  final String? expiresAt;
  final double lat;
  final double lng;
  final String updatedAt;
  final String startedAt;
  final double? accuracyM;

  /// Bug #15: id чата, в котором юзер начал live-трансляцию. Нужен,
  /// чтобы chat list мог показывать индикатор «здесь идёт трансляция»
  /// именно в этом ряду. Поле опциональное — старые записи (до
  /// миграции) и веб (где конверсация передавалась иначе) могут его
  /// не иметь; в этом случае глобальный banner всё равно работает.
  final String? conversationId;

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
    final convId = m['conversationId'];
    return UserLiveLocationShare(
      active: m['active'] == true,
      expiresAt: expiresAt,
      lat: lat,
      lng: lng,
      updatedAt: updatedAt,
      startedAt: startedAt,
      accuracyM: _jsonDouble(m['accuracyM']),
      conversationId: convId is String && convId.isNotEmpty ? convId : null,
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

/// Phase 12.3: запрос локации (iMessage «Request Location»). Хранится
/// внутри сообщения вместе с текстом-приглашением. Получатель видит
/// bubble с кнопками Accept/Decline; при Accept создаётся отдельное
/// location-share сообщение, и id записывается в `acceptedShareMessageId`.
class ChatLocationRequest {
  const ChatLocationRequest({
    required this.requesterId,
    required this.status,
    required this.requestedAt,
    this.acceptedShareMessageId,
    this.respondedAt,
  });

  final String requesterId;
  /// `pending` | `accepted` | `declined`
  final String status;
  final String requestedAt;
  final String? acceptedShareMessageId;
  final String? respondedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  static ChatLocationRequest? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final requesterId = (m['requesterId'] as String?)?.trim() ?? '';
    if (requesterId.isEmpty) return null;
    final status = (m['status'] as String?)?.trim();
    if (status == null || status.isEmpty) return null;
    final requestedAt = (m['requestedAt'] as String?)?.trim() ?? '';
    return ChatLocationRequest(
      requesterId: requesterId,
      status: status,
      requestedAt: requestedAt,
      acceptedShareMessageId:
          (m['acceptedShareMessageId'] as String?)?.trim(),
      respondedAt: (m['respondedAt'] as String?)?.trim(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'requesterId': requesterId,
        'status': status,
        'requestedAt': requestedAt,
        if (acceptedShareMessageId != null && acceptedShareMessageId!.isNotEmpty)
          'acceptedShareMessageId': acceptedShareMessageId,
        if (respondedAt != null && respondedAt!.isNotEmpty)
          'respondedAt': respondedAt,
      };
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
    this.readByUid,
    this.updatedAt,
    this.forwardedFrom,
    this.deliveryStatus,
    this.chatPollId,
    this.locationShare,
    this.locationRequest,
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
    this.expireAt,
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

  /// Личные отметки прочтения по uid. Пишутся в режиме скрытых read-receipts
  /// (`privacySettings.showReadReceipts == false`) вместо публичного `readAt`,
  /// чтобы у самого пользователя сбрасывался unread-счётчик и якорь, но
  /// собеседник не видел галочки прочтения.
  final Map<String, DateTime>? readByUid;
  final String? updatedAt;
  final ForwardedFrom? forwardedFrom;

  /// Web `deliveryStatus`: `sending` | `sent` | `failed`.
  final String? deliveryStatus;

  /// Ссылка на документ `conversations/.../polls/{id}`.
  final String? chatPollId;

  /// Веб `locationShare`.
  final ChatLocationShare? locationShare;

  /// Phase 12.3 (iMessage-paritет): запрос локации у собеседника.
  /// Pending до ответа, потом accepted (с `acceptedShareMessageId` →
  /// id отдельного location-share message) или declined. Render —
  /// специальный bubble в chat_message_list.
  final ChatLocationRequest? locationRequest;

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

  /// Firestore TTL timestamp for disappearing messages (`expireAt`).
  final DateTime? expireAt;

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
    final readByUidRaw = data['readByUid'];
    final updatedAtRaw = data['updatedAt'];
    final forwardedFromRaw = data['forwardedFrom'];
    final deliveryStatusRaw = data['deliveryStatus'];
    final expireAtRaw = data['expireAt'];
    final chatPollIdRaw = data['chatPollId'];
    final chatPollId =
        chatPollIdRaw is String && chatPollIdRaw.trim().isNotEmpty
        ? chatPollIdRaw.trim()
        : null;
    final locationShare = ChatLocationShare.fromJson(data['locationShare']);
    final locationRequest =
        ChatLocationRequest.fromJson(data['locationRequest']);
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

    Map<String, DateTime>? readByUid;
    if (readByUidRaw is Map) {
      final m = <String, DateTime>{};
      for (final e in readByUidRaw.entries) {
        final k = e.key.toString();
        if (k.isEmpty) continue;
        final v = e.value;
        if (v is Timestamp) {
          m[k] = v.toDate();
        } else if (v is String && v.isNotEmpty) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) m[k] = parsed;
        }
      }
      if (m.isNotEmpty) readByUid = m;
    }

    DateTime? expireAt;
    if (expireAtRaw is Timestamp) {
      expireAt = expireAtRaw.toDate();
    } else if (expireAtRaw is String && expireAtRaw.isNotEmpty) {
      expireAt = DateTime.tryParse(expireAtRaw);
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
      readByUid: readByUid,
      updatedAt: updatedAt,
      forwardedFrom: forwardedFrom,
      deliveryStatus: deliveryStatus,
      chatPollId: chatPollId,
      locationShare: locationShare,
      locationRequest: locationRequest,
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
      expireAt: expireAt,
    );
  }
}

/// Статус отложенного сообщения (зеркало TS-типа `ScheduledChatMessageStatus`).
enum ScheduledChatMessageStatus {
  pending('pending'),
  sending('sending'),
  sent('sent'),
  failed('failed');

  const ScheduledChatMessageStatus(this.wire);
  final String wire;

  static ScheduledChatMessageStatus fromWire(String? wire) {
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return ScheduledChatMessageStatus.pending;
  }
}

/// Заготовка опроса для отложенной отправки. При публикации
/// scheduler-CF создаст реальный документ `polls/{id}` и привяжет его
/// к message через `chatPollId`.
class ScheduledChatPendingPoll {
  const ScheduledChatPendingPoll({
    required this.question,
    required this.options,
    this.allowMultiple = false,
    this.isAnonymous = false,
  });

  final String question;
  final List<String> options;
  final bool allowMultiple;
  final bool isAnonymous;

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'question': question,
    'options': options,
    'allowMultiple': allowMultiple,
    'isAnonymous': isAnonymous,
  };

  static ScheduledChatPendingPoll? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final q = raw['question'];
    final optsRaw = raw['options'];
    if (q is! String || q.trim().isEmpty) return null;
    final opts = (optsRaw is List ? optsRaw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
    if (opts.length < 2) return null;
    return ScheduledChatPendingPoll(
      question: q.trim(),
      options: opts,
      allowMultiple: raw['allowMultiple'] == true,
      isAnonymous: raw['isAnonymous'] == true,
    );
  }
}

/// Отложенное сообщение, документ из `conversations/{id}/scheduledMessages/{id}`.
/// Видно только отправителю; публикуется scheduler-CF в момент `sendAt`.
/// E2EE compromise: даже в E2EE-чате сохраняется plaintext.
class ScheduledChatMessage {
  const ScheduledChatMessage({
    required this.id,
    required this.senderId,
    this.text,
    this.attachments = const <ChatAttachment>[],
    this.replyTo,
    this.pendingPoll,
    this.locationShare,
    required this.scheduledAt,
    required this.sendAt,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.updatedAt,
    this.publishedMessageId,
  });

  final String id;
  final String senderId;
  final String? text;
  final List<ChatAttachment> attachments;
  final ReplyContext? replyTo;
  final ScheduledChatPendingPoll? pendingPoll;
  final ChatLocationShare? locationShare;
  final DateTime scheduledAt;
  final DateTime sendAt;
  final ScheduledChatMessageStatus status;
  final String? failureReason;
  final DateTime createdAt;
  final String? updatedAt;
  final String? publishedMessageId;

  static DateTime _parseDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is String && raw.isNotEmpty) {
      final dt =
          DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dt.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ScheduledChatMessage? fromDoc(
    DocumentSnapshot<Map<String, Object?>> doc,
  ) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    final senderId = data['senderId'];
    if (senderId is! String || senderId.isEmpty) return null;

    final text = data['text'];
    final attachmentsRaw = data['attachments'];
    final attachments =
        (attachmentsRaw is List ? attachmentsRaw : const <Object?>[])
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .map(ChatAttachment.fromJson)
            .whereType<ChatAttachment>()
            .toList(growable: false);

    final replyTo = ReplyContext.fromJson(data['replyTo']);
    final pendingPoll = ScheduledChatPendingPoll.fromJson(data['pendingPoll']);
    final locationShare = ChatLocationShare.fromJson(data['locationShare']);

    return ScheduledChatMessage(
      id: doc.id,
      senderId: senderId,
      text: text is String ? text : null,
      attachments: attachments,
      replyTo: replyTo,
      pendingPoll: pendingPoll,
      locationShare: locationShare,
      scheduledAt: _parseDate(data['scheduledAt']),
      sendAt: _parseDate(data['sendAt']),
      status: ScheduledChatMessageStatus.fromWire(
        data['status'] is String ? data['status'] as String : null,
      ),
      failureReason: data['failureReason'] is String
          ? data['failureReason'] as String
          : null,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] is String
          ? data['updatedAt'] as String
          : null,
      publishedMessageId: data['publishedMessageId'] is String
          ? data['publishedMessageId'] as String
          : null,
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
  gameStarted('gameStarted'),
  callMissed('call.missed'),
  callCancelled('call.cancelled');

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
    this.trumpCard,
    required this.deckCount,
    required this.discardCount,
    required this.attackerUid,
    required this.defenderUid,
    required this.handCounts,
    this.currentThrowerUid,
    this.turnUid,
    this.turnKind,
    this.turnStartedAt,
    this.turnDeadlineAt,
    this.turnTimeSec,
    this.roundDefenderHandLimit,
    this.canFinishTurn,
  });

  final String phase;
  final String trumpSuit;
  final DurakCardModel? trumpCard;
  final int deckCount;
  final int discardCount;
  final String attackerUid;
  final String defenderUid;
  final Map<String, int> handCounts;
  final String? currentThrowerUid;
  final String? turnUid;
  final String? turnKind;
  final String? turnStartedAt;
  final String? turnDeadlineAt;
  final int? turnTimeSec;
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
      trumpCard: DurakCardModel.fromJson(raw['trumpCard']),
      deckCount: asInt(raw['deckCount']),
      discardCount: asInt(raw['discardCount']),
      attackerUid: (raw['attackerUid'] ?? '').toString(),
      defenderUid: (raw['defenderUid'] ?? '').toString(),
      handCounts: handCounts,
      currentThrowerUid:
          (raw['currentThrowerUid'] ?? '').toString().trim().isEmpty
          ? null
          : raw['currentThrowerUid'].toString(),
      turnUid: (raw['turnUid'] ?? '').toString().trim().isEmpty
          ? null
          : raw['turnUid'].toString(),
      turnKind: (raw['turnKind'] ?? '').toString().trim().isEmpty
          ? null
          : raw['turnKind'].toString(),
      turnStartedAt: (raw['turnStartedAt'] ?? '').toString().trim().isEmpty
          ? null
          : raw['turnStartedAt'].toString(),
      turnDeadlineAt: (raw['turnDeadlineAt'] ?? '').toString().trim().isEmpty
          ? null
          : raw['turnDeadlineAt'].toString(),
      turnTimeSec: raw['turnTimeSec'] is int
          ? raw['turnTimeSec'] as int
          : int.tryParse((raw['turnTimeSec'] ?? '').toString()),
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
