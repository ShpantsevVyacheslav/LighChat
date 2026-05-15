import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Хелперы для «communication style» уведомлений: chat-style на Android и
/// `INSendMessageIntent` донат на iOS.
///
/// Android: возвращает `MessagingStyleInformation` со скачанным аватаром
/// и `Person(name, icon)`. На лок-скрине Android 12+ это рендерится как
/// pill-row из аватаров (одна нотиф = один чат) — то же поведение, что
/// WhatsApp/Telegram.
///
/// iOS: вызывает native bridge `lighchat/communication_intents` →
/// `INSendMessageIntent.donate()`. На лок-скрине iOS 15+ это даёт богатую
/// карточку с именем + аватаром даже без Notification Service Extension
/// — но только если приложение хотя бы раз получало этот intent раньше
/// (Apple использует donations для ранжирования).
class CommunicationNotificationHelper {
  CommunicationNotificationHelper._();

  static const _iosChannel = MethodChannel('lighchat/communication_intents');

  /// Скачивает аватар, возвращает локальный путь. На ошибки — `null`,
  /// caller fallback-нется на текстовый Person без иконки.
  static Future<String?> downloadAvatar(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final cacheDir = await getTemporaryDirectory();
      final hash = url.hashCode.toUnsigned(32);
      final ext = _imageExt(url);
      final file = File(p.join(cacheDir.path, 'comm_avatar_$hash$ext'));
      if (await file.exists() && (await file.length()) > 0) {
        return file.path;
      }
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _imageExt(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return '.png';
    if (lower.contains('.webp')) return '.webp';
    return '.jpg';
  }

  /// Собирает `MessagingStyleInformation` для Android, если переданы имя
  /// и (опционально) путь к аватару. На null/пусто — возвращает `null`,
  /// caller покажет обычный AndroidNotificationDetails.
  static MessagingStyleInformation? buildAndroidMessagingStyle({
    required String senderName,
    required String body,
    required String? avatarLocalPath,
    String? conversationTitle,
    bool isGroup = false,
  }) {
    if (senderName.trim().isEmpty || body.trim().isEmpty) return null;
    final person = Person(
      name: senderName,
      icon: avatarLocalPath != null
          ? BitmapFilePathAndroidIcon(avatarLocalPath)
          : null,
      important: true,
    );
    return MessagingStyleInformation(
      person,
      conversationTitle: conversationTitle,
      groupConversation: isGroup,
      messages: <Message>[
        Message(body, DateTime.now(), person),
      ],
    );
  }

  /// iOS: native-donate `INSendMessageIntent`. На Android/web — no-op.
  /// Не падает на ошибках канала: just-best-effort.
  static Future<void> donateIosIntent({
    required String senderUid,
    required String senderName,
    required String? avatarLocalPath,
    required String conversationId,
    required String body,
    bool isGroup = false,
  }) async {
    if (kIsWeb) return;
    if (!Platform.isIOS) return;
    try {
      await _iosChannel.invokeMethod('donate', <String, dynamic>{
        'senderUid': senderUid,
        'senderName': senderName,
        'avatarPath': avatarLocalPath,
        'conversationId': conversationId,
        'body': body,
        'isGroup': isGroup,
      });
    } catch (_) {/* swallow */}
  }
}
