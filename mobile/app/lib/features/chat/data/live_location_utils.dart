import 'package:lighchat_models/lighchat_models.dart';

const int _liveMessageSessionSlopMs = 15000;

bool isLiveShareExpired(UserLiveLocationShare share, [int nowMs = 0]) {
  final now = nowMs > 0 ? nowMs : DateTime.now().millisecondsSinceEpoch;
  final exp = share.expiresAt;
  if (exp == null || exp.isEmpty) return false;
  final t = DateTime.tryParse(exp)?.millisecondsSinceEpoch;
  if (t == null) return false;
  return t <= now;
}

bool isLiveShareVisible(UserLiveLocationShare? share, [int nowMs = 0]) {
  if (share == null || !share.active) return false;
  return !isLiveShareExpired(share, nowMs);
}

/// Сообщение с `liveSession` ещё показывает превью карты (паритет `live-location-utils.ts`).
bool isChatLiveLocationMessageStillStreaming(
  ChatLocationShare share,
  DateTime messageCreatedAt,
  UserLiveLocationShare? senderLiveShare,
  bool senderProfileResolved, [
  int nowMs = 0,
]) {
  final now = nowMs > 0 ? nowMs : DateTime.now().millisecondsSinceEpoch;
  if (share.liveSession == null) return false;

  final expiresAtIso = share.liveSession!.expiresAt;
  if (expiresAtIso != null && expiresAtIso.isNotEmpty) {
    final exp = DateTime.tryParse(expiresAtIso)?.millisecondsSinceEpoch;
    if (exp != null && exp <= now) return false;
  }

  if (!senderProfileResolved) return true;

  if (!isLiveShareVisible(senderLiveShare, now)) return false;

  final msgMs = messageCreatedAt.millisecondsSinceEpoch;
  final startedMs = DateTime.tryParse(senderLiveShare!.startedAt)?.millisecondsSinceEpoch;
  if (startedMs != null &&
      msgMs + _liveMessageSessionSlopMs < startedMs) {
    return false;
  }

  return true;
}
