import 'package:flutter/material.dart';

/// Подменяет системную вставку в [TextField]: вызывает [onPaste] вместо
/// только `Clipboard.getData(text)`, чтобы вставлялись файлы из буфера
/// (изображения, видео и т.д.) через `readComposerClipboardPayload`.
class ComposerClipboardMaterialSelectionControls
    extends MaterialTextSelectionControls {
  ComposerClipboardMaterialSelectionControls({required this.onPaste});

  final Future<void> Function() onPaste;

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) => onPaste();
}
