/// Предсэндовые лимиты вложений в композере мобильного чата.
///
/// Существуют две группы ограничений:
///  * E2EE-чат: `5` файлов и `96` МБ суммарно — жёстко зашиты в
///    `e2ee_attachment_send_helper.dart` и валидируются на «последней миле»
///    в outbox-пайплайне. Здесь мы переиспользуем те же константы, чтобы
///    показывать предсэндовую подсказку.
///  * Обычный чат: 20 attachments — это лимит из `firestore.rules` (write
///    rules для `conversations/{cid}/messages/{mid}`). Без клиентской
///    проверки попытка отправки 21+ файла валится с PERMISSION_DENIED уже
///    после загрузки в Storage — мы хотим этого избежать.
library;

import 'package:image_picker/image_picker.dart';

import 'e2ee_attachment_send_helper.dart'
    show e2eeSendMaxFilesPerMessage, e2eeSendMaxTotalBytes;

/// Серверный лимит из firestore.rules (`messages` write).
const int regularSendMaxFilesPerMessage = 20;

class ComposerAttachmentLimits {
  const ComposerAttachmentLimits({
    required this.maxFiles,
    this.maxTotalBytes,
  });

  final int maxFiles;

  /// `null` для обычных чатов — суммарный размер клиент не валидирует
  /// (per-file 220 МБ остаётся на стороне Storage rules).
  final int? maxTotalBytes;

  factory ComposerAttachmentLimits.forChat({required bool isE2ee}) {
    if (isE2ee) {
      return const ComposerAttachmentLimits(
        maxFiles: e2eeSendMaxFilesPerMessage,
        maxTotalBytes: e2eeSendMaxTotalBytes,
      );
    }
    return const ComposerAttachmentLimits(
      maxFiles: regularSendMaxFilesPerMessage,
    );
  }
}

class ComposerLimitsState {
  const ComposerLimitsState({
    required this.currentCount,
    required this.currentBytes,
    required this.limits,
  });

  final int currentCount;

  /// `null` если суммарный размер не считался (limits.maxTotalBytes == null).
  final int? currentBytes;
  final ComposerAttachmentLimits limits;

  bool get isOverFiles => currentCount > limits.maxFiles;

  bool get isOverBytes {
    final cap = limits.maxTotalBytes;
    final used = currentBytes;
    if (cap == null || used == null) return false;
    return used > cap;
  }

  bool get isOverLimit => isOverFiles || isOverBytes;

  int get excessFiles => isOverFiles ? currentCount - limits.maxFiles : 0;
}

/// Считает фактические значения и сравнивает с лимитами.
///
/// Размер запрашивается через `XFile.length()` ТОЛЬКО когда у лимитов есть
/// `maxTotalBytes` — иначе для обычных чатов мы делаем лишние file-stat'ы
/// на каждое добавление вложения.
Future<ComposerLimitsState> computeComposerLimitsState(
  List<XFile> files,
  ComposerAttachmentLimits limits,
) async {
  final count = files.length;
  if (limits.maxTotalBytes == null) {
    return ComposerLimitsState(
      currentCount: count,
      currentBytes: null,
      limits: limits,
    );
  }
  var total = 0;
  for (final f in files) {
    try {
      total += await f.length();
    } catch (_) {
      // Если файл недоступен — считаем как 0, не блокируем UI.
    }
  }
  return ComposerLimitsState(
    currentCount: count,
    currentBytes: total,
    limits: limits,
  );
}

/// Человекочитаемые мегабайты (округление вверх для отображения «использовано»).
String formatComposerBytesMb(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 100) return mb.toStringAsFixed(0);
  if (mb >= 10) return mb.toStringAsFixed(1);
  return mb.toStringAsFixed(1);
}
