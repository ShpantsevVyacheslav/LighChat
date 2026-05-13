import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Лёгкий маркер «в этом приложении сейчас идёт конференция». Хранит только
/// мета-данные + ссылку на локальный MediaStream — соединение/WebRtc по-
/// прежнему живут внутри `MeetingRoomScreen`, который остаётся в
/// Navigator-стеке под другими экранами благодаря push'у вместо replace'а.
///
/// Используется:
/// - чат-листом для пилюли «вернуться в звонок»;
/// - `MeetingFloatingMiniStream` — плавающей миниатюрой с локальным
///   видео поверх любого экрана приложения (#8 ревью).
class ActiveMeetingInfo {
  const ActiveMeetingInfo({
    required this.meetingId,
    required this.meetingName,
    this.localStream,
    this.frontCamera = true,
  });

  final String meetingId;
  final String meetingName;
  final MediaStream? localStream;
  final bool frontCamera;

  ActiveMeetingInfo copyWith({
    String? meetingId,
    String? meetingName,
    MediaStream? localStream,
    bool? frontCamera,
  }) {
    return ActiveMeetingInfo(
      meetingId: meetingId ?? this.meetingId,
      meetingName: meetingName ?? this.meetingName,
      localStream: localStream ?? this.localStream,
      frontCamera: frontCamera ?? this.frontCamera,
    );
  }
}

class ActiveMeetingNotifier extends Notifier<ActiveMeetingInfo?> {
  @override
  ActiveMeetingInfo? build() => null;

  void set(ActiveMeetingInfo? info) => state = info;

  void clear() => state = null;

  void updateLocalStream(MediaStream? stream, {bool? frontCamera}) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      localStream: stream,
      frontCamera: frontCamera,
    );
  }
}

final activeMeetingProvider =
    NotifierProvider<ActiveMeetingNotifier, ActiveMeetingInfo?>(
  ActiveMeetingNotifier.new,
);
