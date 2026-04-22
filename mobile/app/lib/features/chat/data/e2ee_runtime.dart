/// Mobile E2EE v2 runtime — единая точка для шифровки/дешифровки сообщений
/// в чатах с включённым E2EE.
///
/// Архитектурные решения:
///  - `MobileE2eeRuntime` — pure Dart класс без Riverpod, чтобы его можно было
///    тестировать без WidgetRef. Он владеет:
///      * ленивой `MobileDeviceIdentityV2` (из secure-storage);
///      * кешем chat-keys по ключу `cid:epoch:proto` (LRU не нужен — обычный
///        `Map`, т.к. эпохи не плодятся; memory-overhead 32 байта на ключ);
///  - Riverpod-провайдер `mobileE2eeRuntimeProvider` создаёт singleton на uid
///    и уничтожает его при logout, чтобы приватник одного пользователя не
///    оказался доступен другому;
///  - все IO-операции (`Firestore`, `secure_storage`) делаются через
///    `lighchat_firebase` API — прямых импортов `cloud_firestore` из UI нет.
///
/// Поддерживается только v2. Сообщения с другим `protocolVersion` (после
/// Phase 10 cleanup таких быть не должно, кроме ручных артефактов) помечаются
/// `E2EE_UNSUPPORTED_PROTO` — UI покажет плейсхолдер.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

/// Результат дешифровки. Отдельный класс, а не `String?`, чтобы различать
/// «сообщение не E2EE» от «не удалось расшифровать».
class MobileDecryptionResult {
  const MobileDecryptionResult._({
    required this.plaintext,
    required this.errorCode,
  });

  /// Успешная дешифровка.
  factory MobileDecryptionResult.ok(String plaintext) =>
      MobileDecryptionResult._(plaintext: plaintext, errorCode: null);

  /// Не удалось: не знаем ключа эпохи, не наш deviceId в wraps, либо чужая
  /// версия протокола.
  factory MobileDecryptionResult.failed(String errorCode) =>
      MobileDecryptionResult._(plaintext: null, errorCode: errorCode);

  final String? plaintext;
  final String? errorCode;

  bool get ok => plaintext != null;
}

/// Тип ошибки для внешнего UI (баннеры).
class MobileE2eeEncryptException implements Exception {
  const MobileE2eeEncryptException(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() =>
      'MobileE2eeEncryptException($code${message == null ? '' : ': $message'})';
}

class MobileE2eeRuntime {
  MobileE2eeRuntime({
    required this.firestore,
    required this.userId,
  });

  final FirebaseFirestore firestore;
  final String userId;

  MobileDeviceIdentityV2? _identity;
  final Map<String, _CachedChatKey> _chatKeyCache = <String, _CachedChatKey>{};
  final Map<String, Future<MobileDeviceIdentityV2>> _identityInFlight =
      <String, Future<MobileDeviceIdentityV2>>{};

  /// Лениво создаёт/читает identity из secure-storage и публикует её в
  /// Firestore. Вызов идемпотентен, конкурентные вызовы дедуплицируются.
  Future<MobileDeviceIdentityV2> ensureIdentity() async {
    final existing = _identity;
    if (existing != null) return existing;
    final inFlight = _identityInFlight[userId];
    if (inFlight != null) return inFlight;
    final fut = _initIdentity();
    _identityInFlight[userId] = fut;
    try {
      final id = await fut;
      _identity = id;
      return id;
    } finally {
      _identityInFlight.remove(userId);
    }
  }

  Future<MobileDeviceIdentityV2> _initIdentity() async {
    final id = await getOrCreateMobileDeviceIdentity();
    await publishMobileDevice(
      firestore: firestore,
      userId: userId,
      identity: id,
    );
    return id;
  }

  /// Полностью сбрасывает кеш и identity. Вызывать на logout.
  Future<void> clearOnLogout() async {
    _identity = null;
    _chatKeyCache.clear();
    await clearMobileDeviceIdentity();
  }

  /// Дешифрует сообщение. Никогда не бросает — на ошибку возвращает
  /// `MobileDecryptionResult.failed(code)`.
  Future<MobileDecryptionResult> decryptMessage({
    required String conversationId,
    required String messageId,
    required ChatMessageE2eePayload payload,
  }) async {
    if (!payload.isV2) {
      // Любой не-v2 формат после Phase 10 cleanup считаем неподдерживаемым:
      // читать такие envelope нечем (v1-приватника в secure-storage уже нет).
      return MobileDecryptionResult.failed('E2EE_UNSUPPORTED_PROTO');
    }
    try {
      // Decrypt-path: heal здесь бессмыслен (ключ, которым шифровался
      // payload, лежит именно в session payload.epoch). Если эту эпоху
      // мы прочесть не можем — сообщение для нас потеряно, UI покажет
      // placeholder.
      final key = await _tryGetChatKey(
        conversationId: conversationId,
        epoch: payload.epoch,
      );
      if (key == null) {
        return MobileDecryptionResult.failed('E2EE_NO_CHAT_KEY');
      }
      final aad = V2MessageAadContext(
        conversationId: conversationId,
        messageId: messageId,
        epoch: payload.epoch,
      );
      final plain = await decryptMessageV2(
        chatKey: key,
        ivB64: payload.ivB64,
        ciphertextB64: payload.ciphertextB64,
        aad: aad,
      );
      return MobileDecryptionResult.ok(plain);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[E2EE] decrypt failed for $conversationId/$messageId: $e\n$st');
      }
      return MobileDecryptionResult.failed('E2EE_DECRYPT_FAILED');
    }
  }

  /// Подготавливает envelope `e2ee` для записи в сообщение. Бросает
  /// `MobileE2eeEncryptException` на ошибку — она должна всплыть в UI.
  ///
  /// `messageId` обязателен, т.к. входит в AAD (защита от cross-message replay).
  /// Если сообщение ещё не создано в Firestore, используйте
  /// `firestore.collection(...).doc()` для генерации ID заранее.
  Future<Map<String, Object?>> encryptOutgoing({
    required String conversationId,
    required String messageId,
    required int epoch,
    required String plaintext,
  }) async {
    final identity = await ensureIdentity();
    final resolved = await _getOrFetchChatKey(
      conversationId: conversationId,
      epoch: epoch,
    );
    if (resolved == null) {
      throw const MobileE2eeEncryptException('E2EE_NO_CHAT_KEY');
    }
    // После self-heal эпоха может сместиться — пишем в payload/AAD именно
    // `resolved.epoch`, иначе приёмник попробует расшифровать под ошибочной
    // эпохой.
    final aad = V2MessageAadContext(
      conversationId: conversationId,
      messageId: messageId,
      epoch: resolved.epoch,
    );
    final ct = await encryptMessageV2(
      chatKey: resolved.key,
      plaintextUtf8: plaintext,
      aad: aad,
    );
    return <String, Object?>{
      'protocolVersion': v2Protocol,
      'epoch': resolved.epoch,
      'iv': ct.ivB64,
      'ciphertext': ct.ciphertextB64,
      'senderDeviceId': identity.deviceId,
    };
  }

  /// Phase 7: шифрует файл и загружает chunk'и в Storage. Возвращает
  /// envelope для записи в `message.e2ee.attachments[i]`. Бросает, если нет
  /// ключа эпохи или если MIME не подлежит шифрованию (сторона-клиент должна
  /// отсечь стикеры/GIF ещё до вызова, но на всякий случай дублируем).
  Future<MediaEnvelopeV2> encryptMediaForSend({
    required FirebaseStorage storage,
    required String conversationId,
    required String messageId,
    required int epoch,
    required Uint8List data,
    required String mime,
    MediaKindV2? kindHint,
    Uint8List? thumbnailBytes,
    String? thumbnailMime,
    String? metadataJson,
  }) async {
    if (!isEncryptableMimeV2(mime)) {
      throw const MobileE2eeEncryptException(
        'E2EE_MEDIA_MIME_NOT_ENCRYPTABLE',
        'Stickers / GIF должны отправляться plaintext-путём.',
      );
    }
    final resolved = await _getOrFetchChatKey(
      conversationId: conversationId,
      epoch: epoch,
    );
    if (resolved == null) {
      throw const MobileE2eeEncryptException('E2EE_NO_CHAT_KEY');
    }
    final res = await encryptAndUploadMediaFileV2(
      input: EncryptUploadInputV2(
        storage: storage,
        conversationId: conversationId,
        messageId: messageId,
        data: data,
        mime: mime,
        kindHint: kindHint,
        thumbnailBytes: thumbnailBytes,
        thumbnailMime: thumbnailMime,
        metadataJson: metadataJson,
      ),
      chatKeyRaw: resolved.key,
    );
    return res.envelope;
  }

  /// Phase 7: скачивает и расшифровывает один envelope. Для больших файлов
  /// используйте низкоуровневый `decryptMediaFileStreamV2` (см. package export).
  Future<DecryptMediaResultV2> decryptMediaForView({
    required FirebaseStorage storage,
    required String conversationId,
    required String messageId,
    required int epoch,
    required MediaEnvelopeV2 envelope,
  }) async {
    // media-decrypt — аналогично текстовому decrypt'у: key лежит в session
    // под payload.epoch, heal не восстановит старый ключ. Не используем heal.
    final key = await _tryGetChatKey(
      conversationId: conversationId,
      epoch: epoch,
    );
    if (key == null) {
      throw const MobileE2eeEncryptException('E2EE_NO_CHAT_KEY');
    }
    return downloadAndDecryptMediaFileV2(
      input: DownloadDecryptInputV2(
        storage: storage,
        conversationId: conversationId,
        messageId: messageId,
        envelope: envelope,
      ),
      chatKeyRaw: key,
    );
  }

  /// Переиспользуется в двух местах: read-path и send-path.
  ///
  /// Новый контракт (post-launch fix): возвращает `ResolvedChatKey` с фактически
  /// использованной эпохой — может отличаться от `epoch`, если пришлось
  /// делать self-heal (rotate). Вызывающий ДОЛЖЕН использовать эпоху из
  /// результата при сборке payload / AAD, иначе `decryptMessageV2` не
  /// сойдётся на приёме.
  ///
  /// При невозможности unwrap для запрошенной эпохи — делает один круг
  /// `healSessionForCurrentDevices` и повторяет. Это закрывает три post-launch
  /// регрессии:
  ///   - новое устройство ещё не в wraps (нас добавили в e2eeDevices, эпоху
  ///     никто не ротировал) — rotate → получаем ключ;
  ///   - session с неподдерживаемым `protocolVersion` (legacy/unknown) —
  ///     rotate в v2;
  ///   - collaborator открыл новое устройство → сообщение для него не дойдёт,
  ///     но rotate добавит его в новую эпоху.
  Future<_ResolvedChatKey?> _getOrFetchChatKey({
    required String conversationId,
    required int epoch,
  }) async {
    final direct = await _tryGetChatKey(
      conversationId: conversationId,
      epoch: epoch,
    );
    if (direct != null) {
      return _ResolvedChatKey(key: direct, epoch: epoch);
    }

    try {
      final convSnap = await firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      if (!convSnap.exists) return null;
      final data = convSnap.data();
      if (data == null) return null;
      final participantIdsRaw = data['participantIds'];
      final participantIds = (participantIdsRaw is List
              ? participantIdsRaw
              : const <Object?>[])
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false);
      final rawEpoch = data['e2eeKeyEpoch'];
      final latestEpoch = rawEpoch is int
          ? rawEpoch
          : (rawEpoch is num ? rawEpoch.toInt() : epoch);
      final identity = await ensureIdentity();

      final healResult = await healSessionForCurrentDevices(
        firestore: firestore,
        conversationId: conversationId,
        currentEpoch: latestEpoch,
        participantIds: participantIds,
        currentUserId: userId,
        identity: identity,
      );
      final targetEpoch =
          healResult.healed ? healResult.newEpoch : latestEpoch;
      _chatKeyCache.remove('$conversationId:$epoch');
      final healed = await _tryGetChatKey(
        conversationId: conversationId,
        epoch: targetEpoch,
      );
      if (healed == null) return null;
      return _ResolvedChatKey(key: healed, epoch: targetEpoch);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[E2EE] heal attempt failed for $conversationId: $e');
      }
      return null;
    }
  }

  Future<Uint8List?> _tryGetChatKey({
    required String conversationId,
    required int epoch,
  }) async {
    final cacheKey = '$conversationId:$epoch';
    final cached = _chatKeyCache[cacheKey];
    if (cached != null) return cached.key;

    final fetched = await fetchE2eeSessionAny(
      firestore: firestore,
      conversationId: conversationId,
      epoch: epoch,
    );
    if (fetched == null || !fetched.isV2) return null;
    final identity = await ensureIdentity();
    try {
      final raw = await unwrapChatKeyForMobile(
        session: fetched.v2!,
        userId: userId,
        identity: identity,
        conversationId: conversationId,
      );
      _chatKeyCache[cacheKey] = _CachedChatKey(raw);
      return raw;
    } on E2eeSessionException catch (e) {
      if (kDebugMode) {
        debugPrint('[E2EE] unwrap failed $conversationId:$epoch → ${e.code}');
      }
      return null;
    }
  }
}

/// Итог разрешения chat-key: ключ и эпоха, под которой он получен. Эпоха
/// может отличаться от запрошенной, если произошёл self-heal с ротацией.
class _ResolvedChatKey {
  const _ResolvedChatKey({required this.key, required this.epoch});
  final Uint8List key;
  final int epoch;
}

class _CachedChatKey {
  _CachedChatKey(this.key);
  final Uint8List key;
}

/// Riverpod singleton: один экземпляр на uid. При logout ref меняется и
/// предыдущий runtime автоматически утилизируется.
final mobileE2eeRuntimeProvider = Provider<MobileE2eeRuntime?>((ref) {
  if (!isFirebaseReady()) return null;
  final user = ref.watch(authUserProvider).asData?.value;
  if (user == null) return null;
  final rt = MobileE2eeRuntime(
    firestore: FirebaseFirestore.instance,
    userId: user.uid,
  );
  ref.onDispose(() {
    // identity НЕ стираем — пользователь может вернуться под этим же uid без
    // потери ключа. Только кеш chat-keys очистится вместе с экземпляром.
  });
  return rt;
});
