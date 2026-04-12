import 'dart:ui';

import 'package:flutter/material.dart';

/// Действия меню скрепки (паритет веб-меню вложений + мобильные источники).
enum ComposerAttachmentAction {
  /// Галерея / камера фото / камера видео (через подменю).
  photoVideo,
  /// Системный выбор файлов (iOS/Android).
  deviceFiles,
  videoCircle,
  location,
  poll,
  stickersGif,
  format,
}

/// Стеклянная панель пунктов (иконка + подпись).
class ComposerAttachmentMenuPanel extends StatelessWidget {
  const ComposerAttachmentMenuPanel({
    super.key,
    required this.onItemTap,
  });

  final void Function(ComposerAttachmentAction action) onItemTap;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.92);
    final iconFg = Colors.white.withValues(alpha: 0.82);

    Widget row(ComposerAttachmentAction id, IconData icon, String label) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemTap(id),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: iconFg),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row(
                ComposerAttachmentAction.photoVideo,
                Icons.collections_outlined,
                'Фото и видео',
              ),
              row(
                ComposerAttachmentAction.deviceFiles,
                Icons.folder_outlined,
                'Файлы',
              ),
              row(ComposerAttachmentAction.videoCircle, Icons.videocam_rounded, 'Кружок'),
              row(ComposerAttachmentAction.location, Icons.location_on_outlined, 'Локация'),
              row(ComposerAttachmentAction.poll, Icons.poll_outlined, 'Опрос'),
              row(
                ComposerAttachmentAction.stickersGif,
                Icons.emoji_emotions_outlined,
                'Стикеры и GIF',
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              row(ComposerAttachmentAction.format, Icons.text_fields_rounded, 'Форматировать'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Меню у нижнего края, высота по контенту; [bottomFromScreenBottom] — отступ низа панели от низа экрана
/// (до верхней границы композера).
OverlayEntry showComposerAttachmentOverlay({
  required BuildContext context,
  required double bottomFromScreenBottom,
  required void Function(ComposerAttachmentAction action) onSelected,
  void Function()? onDismissed,
}) {
  late OverlayEntry entry;
  void dismiss() {
    entry.remove();
    onDismissed?.call();
  }

  entry = OverlayEntry(
    builder: (ctx) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: bottomFromScreenBottom,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(ctx).width - 24,
                  ),
                  child: IntrinsicWidth(
                    child: ComposerAttachmentMenuPanel(
                      onItemTap: (a) {
                        dismiss();
                        onSelected(a);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Overlay.of(context).insert(entry);
  return entry;
}
