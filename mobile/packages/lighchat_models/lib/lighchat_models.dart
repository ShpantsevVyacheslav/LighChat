import 'package:cloud_firestore/cloud_firestore.dart';

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
    final sidebarFolderOrder = (sidebarOrderRaw is List ? sidebarOrderRaw : const <Object?>[])
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
      sidebarFolderOrder: sidebarFolderOrder.isEmpty ? null : sidebarFolderOrder,
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
      avatarThumb: m['avatarThumb'] is String ? m['avatarThumb'] as String : null,
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
    this.participantInfo,
    this.lastMessageText,
    this.lastMessageTimestamp,
    this.unreadCounts,
    this.unreadThreadCounts,
    this.pinnedMessages,
    this.legacyPinnedMessage,
    this.e2eeEnabled,
    this.e2eeKeyEpoch,
  });

  final bool isGroup;
  final String? name;
  final String? description;
  /// Group avatar URL (web `photoUrl`).
  final String? photoUrl;
  final String? createdByUserId;
  final List<String> adminIds;
  final Map<String, ConversationParticipantInfo>? participantInfo;
  final List<String> participantIds;
  final String? lastMessageText;
  /// ISO string in your web model; in Firestore it is commonly stored as string.
  final String? lastMessageTimestamp;
  final Map<String, int>? unreadCounts;
  final Map<String, int>? unreadThreadCounts;
  final List<PinnedMessage>? pinnedMessages;
  /// @deprecated web `pinnedMessage` single field.
  final PinnedMessage? legacyPinnedMessage;
  final bool? e2eeEnabled;
  final int? e2eeKeyEpoch;

  static Conversation fromJson(JsonMap json) {
    final rawParticipants = json['participantIds'];
    final participantIds = (rawParticipants is List ? rawParticipants : const <Object?>[])
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

    Map<String, ConversationParticipantInfo>? parseParticipantInfo(Object? raw) {
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
      description: json['description'] is String ? json['description'] as String : null,
      photoUrl: json['photoUrl'] is String ? json['photoUrl'] as String : null,
      createdByUserId: json['createdByUserId'] is String ? json['createdByUserId'] as String : null,
      adminIds: adminIds,
      participantInfo: parseParticipantInfo(json['participantInfo']),
      participantIds: participantIds,
      lastMessageText: json['lastMessageText'] is String ? json['lastMessageText'] as String : null,
      lastMessageTimestamp: json['lastMessageTimestamp'] is String ? json['lastMessageTimestamp'] as String : null,
      unreadCounts: parseCounts(json['unreadCounts']),
      unreadThreadCounts: parseCounts(json['unreadThreadCounts']),
      pinnedMessages: parsePins(json['pinnedMessages']),
      legacyPinnedMessage: PinnedMessage.fromJson(
        json['pinnedMessage'] is Map ? (json['pinnedMessage'] as Map).map((k, v) => MapEntry(k.toString(), v)) : null,
      ),
      e2eeEnabled: json['e2eeEnabled'] == true ? true : (json['e2eeEnabled'] == false ? false : null),
      e2eeKeyEpoch: parseEpoch(json['e2eeKeyEpoch']),
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
    final mediaPreviewUrl = json['mediaPreviewUrl'] is String ? json['mediaPreviewUrl'] as String : null;
    final mediaType = json['mediaType'] is String ? json['mediaType'] as String : null;
    final messageCreatedAt = json['messageCreatedAt'] is String ? json['messageCreatedAt'] as String : null;
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
        if (mediaPreviewUrl != null && mediaPreviewUrl!.isNotEmpty) 'mediaPreviewUrl': mediaPreviewUrl,
        if (mediaType != null && mediaType!.isNotEmpty) 'mediaType': mediaType,
        if (messageCreatedAt != null && messageCreatedAt!.isNotEmpty) 'messageCreatedAt': messageCreatedAt,
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
        staticMapRaw is String && staticMapRaw.trim().isNotEmpty ? staticMapRaw.trim() : null;
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

  static ConversationWithId? fromDoc(DocumentSnapshot<Map<String, Object?>> doc) {
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
    this.votes = const <String, int>{},
  });

  final String id;
  final String question;
  final List<String> options;
  final String creatorId;
  /// `active` | `ended` | `cancelled` | `draft`
  final String status;
  final bool isAnonymous;
  final Map<String, int> votes;

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
    final votesRaw = d['votes'];
    final votes = <String, int>{};
    if (votesRaw is Map) {
      for (final e in votesRaw.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is int) votes[k] = v;
        if (v is num) votes[k] = v.toInt();
      }
    }
    return MeetingPoll(
      id: id,
      question: question,
      options: options,
      creatorId: creatorId,
      status: status,
      isAnonymous: isAnonymous,
      votes: votes,
    );
  }
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

    final lastThreadMessageText =
        data['lastThreadMessageText'] is String
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
      lastThreadMessageTimestamp =
          ltsRaw.toDate().toUtc().toIso8601String();
    }

    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final attachments = (attachmentsRaw is List ? attachmentsRaw : const <Object?>[])
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
    final mediaPreviewUrl = m['mediaPreviewUrl'] is String ? m['mediaPreviewUrl'] as String : null;
    final mediaType = m['mediaType'] is String ? m['mediaType'] as String : null;
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
    final size = json['size'] is int ? json['size'] as int : (json['size'] is num ? (json['size'] as num).toInt() : null);
    final width = json['width'] is int ? json['width'] as int : (json['width'] is num ? (json['width'] as num).toInt() : null);
    final height = json['height'] is int ? json['height'] as int : (json['height'] is num ? (json['height'] as num).toInt() : null);
    final thumbHash = json['thumbHash'] is String ? json['thumbHash'] as String : null;
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
