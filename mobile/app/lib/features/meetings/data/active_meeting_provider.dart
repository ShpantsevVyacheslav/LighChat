import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Лёгкий маркер «в этом приложении сейчас идёт конференция». Хранит только
/// мета-данные — соединение/WebRtc по-прежнему живут внутри
/// `MeetingRoomScreen`, который остаётся в Navigator-стеке под другими
/// экранами благодаря push'у вместо replace'а.
///
/// Используется чат-листом, чтобы показать пилюлю «вернуться в звонок».
/// (Раньше дополнительно держал `localStream` для Flutter-миниатюры,
/// но её удалили — на мобиле этим занимается нативный PiP.)
class ActiveMeetingInfo {
  const ActiveMeetingInfo({
    required this.meetingId,
    required this.meetingName,
  });

  final String meetingId;
  final String meetingName;

  ActiveMeetingInfo copyWith({
    String? meetingId,
    String? meetingName,
  }) {
    return ActiveMeetingInfo(
      meetingId: meetingId ?? this.meetingId,
      meetingName: meetingName ?? this.meetingName,
    );
  }
}

class ActiveMeetingNotifier extends Notifier<ActiveMeetingInfo?> {
  @override
  ActiveMeetingInfo? build() => null;

  void set(ActiveMeetingInfo? info) => state = info;

  void clear() => state = null;
}

final activeMeetingProvider =
    NotifierProvider<ActiveMeetingNotifier, ActiveMeetingInfo?>(
  ActiveMeetingNotifier.new,
);
