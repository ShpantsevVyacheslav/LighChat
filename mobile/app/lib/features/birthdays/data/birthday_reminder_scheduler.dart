import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:lighchat_mobile/features/push/push_foreground_suppression.dart';
import 'package:lighchat_mobile/features/push/push_local_notifications_facade.dart';

/// Локальное напоминание «за день до ДР» в следующем году. Реюзает основной
/// канал [PushLocalNotificationsFacade.channelSilentId] (без звука — это не
/// срочное сообщение). Возвращает `true` если шедулинг прошёл успешно.
class BirthdayReminderScheduler {
  BirthdayReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<bool> scheduleDayBefore({
    required String contactUserId,
    required DateTime birthDate,
    required String title,
    required String body,
  }) async {
    ensureTimezoneDataLoaded();

    final now = DateTime.now();
    // ДР следующего года: берём те же month/day, год — следующий.
    final nextYear =
        DateTime(now.year + 1, birthDate.month, birthDate.day, 10);
    final remindAt = nextYear.subtract(const Duration(days: 1));
    final localZone = tz.local;
    final scheduledTz = tz.TZDateTime.from(remindAt, localZone);

    final id = _notificationId(contactUserId);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        PushLocalNotificationsFacade.channelSilentId,
        'Birthday reminders',
        importance: Importance.defaultImportance,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTz,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'birthday:$contactUserId',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static int _notificationId(String userId) =>
      ('birthday_reminder:$userId').hashCode & 0x7fffffff;
}
