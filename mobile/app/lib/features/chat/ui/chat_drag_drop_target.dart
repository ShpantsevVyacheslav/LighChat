import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:super_clipboard/super_clipboard.dart' show DataReader;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../l10n/app_localizations.dart';
import '../data/composer_clipboard_paste.dart';

/// Системный drop‑target для экрана чата (iOS 11+ system drag&drop, Android
/// drag&drop). Принимает медиа/файлы/URL/текст из других приложений и
/// конвертирует их в тот же payload, что и paste из буфера — чтобы вся
/// нижележащая логика загрузки (`uploadChatAttachmentFromXFile`) и UI
/// pending‑превью оставались общими.
class ChatDragDropTarget extends StatefulWidget {
  const ChatDragDropTarget({
    super.key,
    required this.child,
    required this.onFilesDropped,
    required this.onTextDropped,
    this.enabled = true,
  });

  final Widget child;

  /// Файлы, прочитанные из drop‑session (image/video/pdf/etc.). Уже сохранены
  /// во временную директорию, если источник не дал file:// URI.
  final void Function(List<XFile> files) onFilesDropped;

  /// Plain‑text/URL из источника (если он был). Получатель сам решает, как
  /// его вставить — в позицию курсора или в конец.
  final void Function(String text) onTextDropped;

  /// Если false — drop полностью игнорируется (loading/error состояние,
  /// E2EE‑баннер, send в процессе и т.п.).
  final bool enabled;

  @override
  State<ChatDragDropTarget> createState() => _ChatDragDropTargetState();
}

class _ChatDragDropTargetState extends State<ChatDragDropTarget> {
  bool _isDragOver = false;

  DropOperation _onDropOver(DropOverEvent event) {
    if (!widget.enabled) return DropOperation.none;
    return event.session.allowedOperations.contains(DropOperation.copy)
        ? DropOperation.copy
        : DropOperation.none;
  }

  void _onDropEnter(DropEvent _) {
    if (!widget.enabled || _isDragOver) return;
    HapticFeedback.selectionClick();
    setState(() => _isDragOver = true);
  }

  void _onDropLeave(DropEvent _) {
    if (!_isDragOver) return;
    setState(() => _isDragOver = false);
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    if (mounted && _isDragOver) {
      setState(() => _isDragOver = false);
    }
    if (!widget.enabled) return;
    final items = event.session.items;
    debugPrint(
      '[chat-drop] performDrop: items=${items.length} '
      'allowedOps=${event.session.allowedOperations}',
    );
    for (var i = 0; i < items.length; i++) {
      final r = items[i].dataReader;
      if (r == null) {
        debugPrint('[chat-drop] item[$i]: no dataReader');
        continue;
      }
      final fmts = r.getFormats(Formats.standardFormats);
      debugPrint(
        '[chat-drop] item[$i]: formats='
        '${fmts.map((f) => f.toString()).join(", ")}',
      );
    }
    final readers = <DataReader>[
      for (final item in items)
        if (item.dataReader != null) item.dataReader!,
    ];
    if (readers.isEmpty) {
      debugPrint('[chat-drop] performDrop: no readers, abort');
      return;
    }
    try {
      final payload = await readComposerPayloadFromDataReaders(readers);
      debugPrint(
        '[chat-drop] payload: files=${payload.files.length} '
        'text=${payload.text == null ? 'null' : "${payload.text!.length} chars"}',
      );
      for (var i = 0; i < payload.files.length; i++) {
        final f = payload.files[i];
        debugPrint(
          '[chat-drop] file[$i]: name="${f.name}" path="${f.path}" '
          'mime=${f.mimeType ?? 'null'}',
        );
      }
      if (!mounted) return;
      if (payload.files.isNotEmpty) {
        widget.onFilesDropped(payload.files);
      }
      final text = (payload.text ?? '').trim();
      if (text.isNotEmpty) {
        widget.onTextDropped(text);
      }
    } catch (e, st) {
      // Silent для UX: drop — best‑effort, ошибки не показываем юзеру.
      // Но в лог пишем — без этого диагностика «почему ничего не
      // добавилось» превращается в гадание.
      debugPrint('[chat-drop] payload read failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: const [...Formats.standardFormats],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onDropEnter: _onDropEnter,
      onDropLeave: _onDropLeave,
      onPerformDrop: _onPerformDrop,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                opacity: _isDragOver ? 1 : 0,
                child: const _ChatDropOverlayHint(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatDropOverlayHint extends StatelessWidget {
  const _ChatDropOverlayHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${l10n.attach_title}: ${l10n.attach_files}',
                    // decoration:none — иначе родительский DefaultTextStyle
                    // (или iOS system spell‑check) рисует жёлтые волнистые
                    // подчёркивания под капсулой overlay.
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                      decorationThickness: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
