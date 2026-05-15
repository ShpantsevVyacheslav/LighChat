import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Subject Lift (iOS 17+): тапни объект на фото → iOS вырезает его из
/// фона. Возвращает локальный путь к PNG с прозрачным альфа-каналом —
/// можно сразу аттачить в чат, шарить, сохранять в галерею.
///
/// На iOS < 17, Android, web — `isAvailable()` вернёт `false`,
/// `lift()` → `null`.
class SubjectLift {
  SubjectLift._();
  static final SubjectLift instance = SubjectLift._();

  static const _channel = MethodChannel('lighchat/subject_lift');

  /// Доступна ли фича. iOS 17+ + `ImageAnalyzer.isSupported`.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return false;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Открывает нативный фуллскрин с фото; пользователь тапает объект,
  /// iOS возвращает его как UIImage; мы сохраняем PNG в tmp и возвращаем
  /// путь. `null` — если пользователь закрыл без выбора или произошла
  /// ошибка.
  ///
  /// [imageUrl] — `file://...` или `http(s)://...` (URL который умеет
  /// читать `URLSession`). Для cached_network_image — берите путь из
  /// кэша или uri.toFilePath.
  Future<String?> lift({required String imageUrl}) async {
    try {
      final v = await _channel.invokeMethod<String>(
        'lift',
        <String, dynamic>{'imageUrl': imageUrl},
      );
      return v;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[SubjectLift] ${e.code}: ${e.message}');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
