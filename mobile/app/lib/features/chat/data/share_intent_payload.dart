import 'package:image_picker/image_picker.dart';

/// Полезная нагрузка системного «Поделиться» (iOS Share Extension /
/// Android `ACTION_SEND` / `ACTION_SEND_MULTIPLE`), нормализованная под
/// внутренний формат composer'а: список `XFile` для медиа/документов +
/// необязательный текст (URL/plain).
///
/// Передаётся через `GoRouterState.extra` на `/share` и затем — через
/// extra на `/chats/{conversationId}` при выборе целевого чата.
class ShareIntentPayload {
  const ShareIntentPayload({
    this.files = const <XFile>[],
    this.text,
  });

  /// Файлы из шеринга (image/video/pdf/...). Если источник дал text+files —
  /// держим их вместе, чтобы получатель решил, как комбинировать (caption +
  /// album, например).
  final List<XFile> files;

  /// Plain‑текст или URL (на iOS Share Extension `text/plain` приходит
  /// отдельно от файлов; на Android — через `Intent.EXTRA_TEXT`).
  final String? text;

  bool get isEmpty => files.isEmpty && (text == null || text!.trim().isEmpty);
  bool get isNotEmpty => !isEmpty;
}
